import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class Habit {
  final String id;
  String name;
  String emoji;
  Habit({required this.id, required this.name, required this.emoji});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};
  factory Habit.fromJson(Map<String, dynamic> j) =>
      Habit(id: j['id'].toString(), name: j['name'] ?? '', emoji: j['emoji'] ?? '⭐');
}

class Goal {
  String label;
  String start; // yyyy-MM-dd
  String target; // yyyy-MM-dd
  Goal({required this.label, required this.start, required this.target});

  Map<String, dynamic> toJson() => {'label': label, 'start': start, 'target': target};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        label: j['label'] ?? 'Sprint',
        start: j['start'] ?? _today(),
        target: j['target'] ?? '2026-12-31',
      );
}

String _today() => DateTime.now().toIso8601String().split('T').first;

int daysBetween(String a, String b) {
  final da = DateTime.parse(a);
  final db = DateTime.parse(b);
  return db.difference(da).inDays;
}

class Sprint {
  final int total, elapsed, remaining;
  final double pct;
  Sprint(this.total, this.elapsed, this.remaining, this.pct);
}

const _kCache = 'josh_state_cache';
const _kTs = 'josh_state_ts';

List<Habit> _defaults() => [
      Habit(id: '1', name: '90 Min Hour Trade', emoji: '📈'),
      Habit(id: '2', name: '90 Min Meta Learning', emoji: '🧠'),
      Habit(id: '3', name: 'Gym', emoji: '🏋️'),
      Habit(id: '4', name: 'Diet', emoji: '🥗'),
      Habit(id: '5', name: 'Sleep', emoji: '😴'),
    ];

class Store extends ChangeNotifier {
  final SupabaseClient sb = Supabase.instance.client;
  late SharedPreferences _prefs;

  List<Habit> habits = _defaults();
  Map<String, Map<String, bool>> log = {};
  Goal goal = Goal(label: '101 Day Sprint', start: _today(), target: '2026-12-31');
  User? user;
  bool ready = false;
  bool _pending = false;

  String get todayKey => _today();

  // ---------- lifecycle ----------
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCache();
    user = sb.auth.currentUser;
    sb.auth.onAuthStateChange.listen((data) async {
      user = data.session?.user;
      if (user != null) {
        await pull();
      }
      notifyListeners();
    });
    if (user != null) await pull();
    ready = true;
    notifyListeners();
  }

  // ---------- local cache ----------
  void _loadCache() {
    final raw = _prefs.getString(_kCache);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['habits'] is List) {
        habits = (j['habits'] as List).map((e) => Habit.fromJson(e)).toList();
      }
      if (j['log'] is Map) log = _decodeLog(j['log']);
      if (j['goal'] is Map) goal = Goal.fromJson(j['goal']);
    } catch (_) {}
  }

  Map<String, Map<String, bool>> _decodeLog(dynamic raw) {
    final out = <String, Map<String, bool>>{};
    (raw as Map).forEach((day, v) {
      final inner = <String, bool>{};
      (v as Map).forEach((hid, val) => inner[hid.toString()] = val == true);
      out[day.toString()] = inner;
    });
    return out;
  }

  Map<String, dynamic> _stateJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'log': log,
        'goal': goal.toJson(),
      };

  int _ts() => _prefs.getInt(_kTs) ?? 0;

  Future<void> _persist({bool bump = true}) async {
    notifyListeners(); // paint the change immediately
    await _prefs.setString(_kCache, jsonEncode(_stateJson()));
    if (bump) {
      await _prefs.setInt(_kTs, DateTime.now().millisecondsSinceEpoch);
      _push();
    }
  }

  // ---------- cloud sync (one JSON row per user, last-write-wins) ----------
  Future<void> _push() async {
    if (user == null) {
      _pending = true;
      return;
    }
    try {
      final ts = _ts();
      await sb.from('tracker_state').upsert({
        'user_id': user!.id,
        'habits': habits.map((h) => h.toJson()).toList(),
        'log': log,
        'goal': goal.toJson(),
        'updated_at':
            DateTime.fromMillisecondsSinceEpoch(ts).toUtc().toIso8601String(),
      });
      _pending = false;
    } catch (_) {
      _pending = true;
    }
  }

  Future<void> pull() async {
    if (user == null) return;
    try {
      final data = await sb
          .from('tracker_state')
          .select()
          .eq('user_id', user!.id)
          .maybeSingle();
      if (data != null) {
        final serverTs =
            DateTime.tryParse(data['updated_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
        if (serverTs >= _ts()) {
          if (data['habits'] is List) {
            habits = (data['habits'] as List).map((e) => Habit.fromJson(e)).toList();
          }
          if (data['log'] is Map) log = _decodeLog(data['log']);
          if (data['goal'] is Map) goal = Goal.fromJson(data['goal']);
          await _prefs.setString(_kCache, jsonEncode(_stateJson()));
          await _prefs.setInt(_kTs, serverTs);
          notifyListeners();
        } else {
          await _push();
        }
      } else {
        await _prefs.setInt(_kTs, DateTime.now().millisecondsSinceEpoch);
        await _push();
      }
    } catch (_) {
      _pending = true;
    }
  }

  Future<void> retryIfPending() async {
    if (_pending) await _push();
  }

  // ---------- mutations ----------
  Future<void> toggle(String habitId) async {
    final day = log.putIfAbsent(todayKey, () => {});
    day[habitId] = !(day[habitId] ?? false);
    await _persist();
  }

  Future<void> addHabit(String name, String emoji) async {
    habits.add(Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        emoji: emoji.isEmpty ? '⭐' : emoji));
    await _persist();
  }

  Future<void> deleteHabit(String id) async {
    habits.removeWhere((h) => h.id == id);
    await _persist();
  }

  Future<void> updateGoal({String? label, String? start, String? target}) async {
    if (label != null) goal.label = label;
    if (start != null) goal.start = start;
    if (target != null) goal.target = target;
    await _persist();
  }

  // ---------- derived ----------
  int doneOn(String day) {
    final d = log[day] ?? {};
    return habits.where((h) => d[h.id] == true).length;
  }

  double todayPct() => habits.isEmpty ? 0 : doneOn(todayKey) / habits.length;

  Sprint sprint() {
    final total = daysBetween(goal.start, goal.target).clamp(1, 1 << 30);
    final elapsed = daysBetween(goal.start, todayKey).clamp(0, total);
    final remaining = daysBetween(todayKey, goal.target).clamp(0, 1 << 30);
    return Sprint(total, elapsed, remaining, elapsed / total);
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

  // ---------- export ----------
  String exportCsv() {
    final rows = <String>['"Date","Task","Completed"'];
    final days = log.keys.toList()..sort();
    for (final d in days) {
      for (final h in habits) {
        final done = (log[d]?[h.id] ?? false) ? 'Yes' : 'No';
        rows.add('"$d","${h.name.replaceAll('"', '""')}","$done"');
      }
    }
    return rows.join('\n');
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'habits': habits.map((h) => h.toJson()).toList(),
        'log': log,
        'goal': goal.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
      });
}