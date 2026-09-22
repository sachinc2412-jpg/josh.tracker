import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'models.dart';
import 'services/reminders.dart';
export 'models.dart';

enum SyncState { saved, syncing, waiting, localError }

class Store extends ChangeNotifier {
  SupabaseClient get sb => Supabase.instance.client;
  late SharedPreferences _prefs;
  final reminders = Reminders();
  TrackerData data = TrackerData.empty();
  User? user;
  bool ready = false, accountReady = false;
  bool _foreground = true;
  int _generation = 0;
  final List<Json> _pending = [];
  Future<void> _disk = Future.value();
  Future<void>? _syncing;
  SyncState syncState = SyncState.waiting;
  String? syncError;
  DateTime? lastSynced;
  String? openHabitId;
  int openRequest = 0;
  DateTime now = DateTime.now();
  Timer? _clock;
  StreamSubscription<AuthState>? _authSubscription;
  String get todayKey => dayKey(now);
  List<Habit> get habits => data.habits;
  int get pendingCount => _pending.length;
  String get name => (data.prefs['name'] as String? ?? 'Joshua').trim();
  String get syncLabel => switch(syncState) {
    SyncState.saved => 'Saved', SyncState.syncing => 'Syncing',
    SyncState.waiting => 'Waiting to sync', SyncState.localError => 'Not saved on device',
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await reminders.init();
    reminders.onOpen = (id) { openHabitId = id; openRequest++; notifyListeners(); };
    openHabitId = await reminders.launchHabit();
    if (openHabitId != null) openRequest++;
    _authSubscription = sb.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != user?.id) unawaited(_openAccount(event.session?.user));
    });
    ready = true;
    unawaited(_openAccount(sb.auth.currentUser));
    _clock = Timer.periodic(const Duration(seconds:30), (_) {
      if (!_foreground) return;
      final old = todayKey;
      now = DateTime.now();
      if (old != todayKey) unawaited(reminders.update(data,user?.id));
      notifyListeners();
      unawaited(sync());
    });
  }
  @override
  void dispose() {
    _clock?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
  Future<void> _openAccount(User? next) async {
    final generation = ++_generation;
    user = next; accountReady = false;
    data = TrackerData.empty(); _pending.clear();
    syncError = null; lastSynced = null; syncState = SyncState.waiting;
    notifyListeners();
    await reminders.update(data,null);
    if (generation != _generation || next == null) return;
    final raw = _prefs.getString('josh_v2_${next.id}');
    if (raw != null) {
      try {
        final cached = jsonMap(jsonDecode(raw));
        data = TrackerData(jsonMap(cached['state']));
        _pending.addAll((cached['pending'] as List? ?? []).map(jsonMap));
        lastSynced = DateTime.tryParse(cached['lastSynced'] as String? ?? '');
        accountReady = true;
      } catch (_) {
        syncError = 'Local data could not be read. It has been kept for recovery.';
        notifyListeners(); return;
      }
    } else {
      try {
        // Account-scoped cloud migration; never assume the old global cache belongs to this user.
        final old = await sb.from('tracker_state').select().eq('user_id',next.id).maybeSingle().timeout(const Duration(seconds:15));
        if (generation != _generation) return;
        data = old == null ? TrackerData.empty() : TrackerData.legacy(old);
        accountReady = true;
        await _save();
      } catch (_) {
        if (generation != _generation) return;
        syncError = 'Connect once to load your account safely, then offline tracking will be available.';
        notifyListeners(); return;
      }
    }
    notifyListeners();
    await reminders.update(data,user?.id);
    await sync();
  }
  Future<void> retry() async {
    if (!accountReady) { await _openAccount(sb.auth.currentUser); } else { await sync(); }
  }
  Future<void> _save() {
    final uid = user?.id;
    if (uid == null) return Future.value();
    final payload = jsonEncode({'state':data.json, 'pending':_pending,
      'lastSynced':lastSynced?.toIso8601String()});
    final job = _disk.catchError((Object _) {}).then((_) async {
      if (!await _prefs.setString('josh_v2_$uid',payload)) throw StateError('Local save failed');
    });
    _disk = job;
    return job;
  }
  Future<void> edit(String type, Json value, {String? key, String? day}) async {
    final generation = _generation;
    final op = <String,dynamic>{'id':'${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1<<32)}',
      'type':type, 'value':value, if(key!=null)'key':key, if(day!=null)'day':day};
    data.apply(op); _pending.add(op); syncState = SyncState.waiting;
    notifyListeners();
    try { await _save(); } catch (_) {
      if (generation != _generation) return;
      syncState = SyncState.localError; syncError = 'Your device could not save this change. Free some storage and retry.';
      notifyListeners(); return;
    }
    if (generation != _generation) return;
    await reminders.update(data,user?.id);
    unawaited(sync());
  }
  Future<void> sync() async {
    if (user == null || !accountReady) return;
    if (_syncing != null) { await _syncing; return; }
    final job = _runSync(); _syncing = job;
    try { await job; } finally { _syncing = null; }
  }
  Future<void> _runSync() async {
    final uid = user!.id, generation = _generation;
    syncState = SyncState.syncing; syncError = null; notifyListeners();
    try {
      try {
        await _save(); // persist queue before the network request
      } catch (_) {
        if (generation == _generation) {
          syncState = SyncState.localError;
          syncError = 'Not saved on this device. Free some storage and retry.';
          notifyListeners();
        }
        return;
      }
      if (generation != _generation) return;
      final batch = _pending.take(250).toList();
      final result = await sb.rpc('josh_sync_v2',params:{'p_ops':batch,'p_seed':data.json}).timeout(const Duration(seconds:15));
      if (generation != _generation || user?.id != uid) return;
      final ack = batch.map((e)=>e['id']).toSet();
      _pending.removeWhere((e)=>ack.contains(e['id']));
      data = TrackerData(jsonMap(result));
      for (final op in _pending) { data.apply(op); }
      lastSynced = DateTime.now();
      try {
        await _save();
      } catch (_) {
        if (generation == _generation) {
          syncState = SyncState.localError;
          syncError = 'Saved to your account, but this device could not update its local copy. Free some storage and retry.';
          notifyListeners();
        }
        return;
      }
      if (generation != _generation) return;
      syncState = _pending.isEmpty ? SyncState.saved : SyncState.waiting;
      await reminders.update(data,uid);
    } catch (e) {
      if (generation != _generation) return;
      syncState = SyncState.waiting;
      syncError = e is PostgrestException && (e.code == 'PGRST202' || e.code == '42P01')
          ? 'Cloud upgrade needed. Your changes stay on this device until the included Supabase setup is installed.'
          : 'Could not reach cloud sync. Changes remain queued on this device. Tap Retry when connected.';
    }
    if (generation == _generation) notifyListeners();
  }
  void foreground(bool value) {
    _foreground = value;
    if (value) {
      now = DateTime.now(); notifyListeners();
      unawaited(reminders.status().then((_)=>reminders.update(data,user?.id)));
      unawaited(sync());
    }
  }
  Future<void> setValue(Habit h, double value, {String? day}) => edit('log', {
    'value':value.clamp(0,1000000), 'target':h.dailyTarget, 'kind':h.kind, 'unit':h.unit,
  },key:h.id,day:day??todayKey);
  Future<void> toggle(String id) {
    final h = habits.firstWhere((h)=>h.id==id);
    return setValue(h,data.completed(h,todayKey)?0:h.dailyTarget);
  }
  Future<void> saveHabit(Json values, {Habit? existing}) async {
    final id = existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final versions = [...(existing?.data['versions'] as List? ?? [])];
    if (existing != null && versions.isEmpty) versions.add({...existing.data,'from':existing.created});
    versions.removeWhere((v)=>jsonMap(v)['from']==todayKey);
    versions.add({...values,'from':todayKey});
    await edit('habit',{...?(existing?.data),...values,'id':id,
      'created':existing?.created??todayKey,'versions':versions},key:id);
  }
  Future<void> archive(Habit h) => edit('habit',{...h.data,'archived':todayKey},key:h.id);
  Future<void> preferences(Json values) => edit('prefs',values);
  Future<void> updateGoal(Json values) => edit('goal',values);
  Future<void> completeSetup(String displayName, String goal, List<Json> selected, bool enable, int quietStart, int quietEnd) async {
    for (final h in selected) { await saveHabit(h); }
    await updateGoal({'label':goal.trim()});
    await preferences({'name':displayName.trim(),'onboarded':true,'reminders':enable,
      'quietStart':quietStart,'quietEnd':quietEnd});
  }
  String exportJson() => const JsonEncoder.withIndent('  ').convert(data.json);
  String exportCsv() {
    String q(Object? value) => '"${value.toString().replaceAll('"','""')}"';
    final rows = <String>['Date,Habit,Value,Target,Unit,Completed'];
    final dates = data.logs.keys.toList()..sort();
    for(final day in dates) {
      for(final h in data.allHabits) {
        final e = data.entry(h.id,day);
        if(e.isEmpty) continue;
        rows.add([day,h.on(day).name,e['value'],e['target'],e['unit'],data.completed(h,day)].map(q).join(','));
      }
    }
    return rows.join('\n');
  }
  // ---------- auth ----------
  Future<String?> signInGoogle() async {
    try {
      final gsi = GoogleSignIn(
        serverClientId: Config.googleServerClientId,
        scopes: ['email', 'profile'],
      );
      final account = await gsi.signIn();
      if (account == null) return 'Cancelled.';
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return 'No ID token from Google. Check serverClientId.';
      await sb.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInEmail(String email, String pass) async {
    try {
      await sb.auth.signInWithPassword(email: email, password: pass);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUpEmail(String email, String pass) async {
    try {
      await sb.auth.signUp(email: email, password: pass);
      return 'Account created. If email confirmation is on, confirm then sign in.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await sb.auth.signOut();
  }


}
