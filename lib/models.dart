import 'dart:math' as math;

typedef Json = Map<String, dynamic>;
String dayKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime shiftDay(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime monday(DateTime d) => shiftDay(dateOnly(d), 1 - d.weekday);
String number(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
Json jsonMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};

class Habit {
  Habit(this.data);
  final Json data;
  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? 'Habit';
  String get emoji => data['emoji'] as String? ?? '✦';
  String get kind => data['kind'] as String? ?? 'check';
  String get category => data['category'] as String? ?? 'Personal';
  double get target => (data['target'] as num? ?? 1).toDouble();
  String get unit => data['unit'] as String? ?? 'times';
  int get weeklyTarget => (data['weeklyTarget'] as num? ?? 4).toInt();
  int get reminder => (data['reminder'] as num? ?? 1080).toInt();
  bool get remind => data['remind'] == true;
  String get created => data['created'] as String? ?? '1970-01-01';
  String? get archived => data['archived'] as String?;
  List<int> get weekdays => ((data['weekdays'] as List?) ?? [1,2,3,4,5,6,7]).cast<int>();
  bool active(String day) => day.compareTo(created) >= 0 && (archived == null || day.compareTo(archived!) < 0);
  Habit on(String day) {
    Json? version;
    for (final item in (data['versions'] as List? ?? [])) {
      final v = jsonMap(item);
      if ((v['from'] as String).compareTo(day) <= 0) version = v;
    }
    return version == null ? this : Habit({...data, ...version, 'id': id, 'archived': archived, 'pauses': data['pauses']});
  }
  bool paused(String day) => (data['pauses'] as List? ?? []).any((p) => day.compareTo(p['start'] as String)>=0 && day.compareTo(p['end'] as String)<=0);
  bool scheduled(DateTime day) => active(dayKey(day)) && (kind == 'weekly' || weekdays.contains(day.weekday));
  String get targetLabel => kind == 'weekly' ? '$weeklyTarget days / week' : kind == 'quantity' ? '${number(target)} $unit / day' : 'Daily check-in';
  double get dailyTarget => kind == 'quantity' ? target : 1;
}

class TrackerData {
  TrackerData(this.json);
  final Json json;
  factory TrackerData.empty([DateTime? at]) {
    final now = at ?? DateTime.now();
    return TrackerData({
      'schema': 2, 'habits': <String,dynamic>{}, 'log': <String,dynamic>{},
      'goal': {'label': 'Build a life you feel good about', 'start': dayKey(now), 'target': dayKey(shiftDay(now, 100))},
      'prefs': {'name':'Joshua', 'onboarded':false, 'reminders':false, 'quietStart':1320, 'quietEnd':480, 'summaryTime':1200},
    });
  }
  factory TrackerData.legacy(Json old) {
    final model = TrackerData.empty();
    final oldLog = jsonMap(old['log']);
    final keys = oldLog.keys.toList()..sort();
    final start = keys.isEmpty ? dayKey(DateTime.now()) : keys.first;
    for (final item in old['habits'] as List? ?? []) {
      final h = jsonMap(item);
      final id = h['id'].toString();
      model.habitMap[id] = {...h, 'id':id, 'kind':'check', 'target':1,
        'created':start, 'weekdays':[1,2,3,4,5,6,7]};
    }
    for (final day in keys) {
      model.logs[day] = jsonMap(oldLog[day]).map((id, done) => MapEntry(id,
        {'value':done == true ? 1 : 0, 'target':1, 'unit':'times', 'kind':'check'}));
    }
    model.goal.addAll(jsonMap(old['goal']));
    return model;
  }
  Json get journalMap => json.putIfAbsent('journal',()=> <String,dynamic>{}) as Json;
  Json get reviews => json.putIfAbsent('reviews',()=> <String,dynamic>{}) as Json;
  Json get restDays => json.putIfAbsent('restDays',()=> <String,dynamic>{}) as Json;
  Json journal(String day) => jsonMap(journalMap[day]);
  bool rest(DateTime day) {
    final key=dayKey(day),override=jsonMap(restDays[key]);
    if(override.containsKey('rest'))return override['rest']==true;
    List<dynamic> days=[];
    final versions=prefs['restVersions'] as List? ?? [];
    if(versions.isEmpty){
      if(key.compareTo(prefs['restFrom'] as String? ?? '1970-01-01')>=0)days=prefs['restWeekdays'] as List? ?? [];
    }else{
      for(final v in versions){if(key.compareTo(v['from'] as String)<0)continue;days=v['days'] as List;}
    }
    return days.contains(day.weekday);
  }
  bool scheduled(Habit h, DateTime day) => h.scheduled(day) && !rest(day) && !h.paused(dayKey(day));
  bool protectedRest(DateTime day) {
    if(rest(day))return true;
    final planned=allHabits.where((h)=>h.on(dayKey(day)).scheduled(day));
    return planned.isNotEmpty && planned.every((h)=>h.paused(dayKey(day)));
  }
  int weeklyTargetFor(Habit h,DateTime day) {
    final start=monday(day);
    var available=0;
    for(var i=0;i<7;i++){final d=shiftDay(start,i);if(scheduled(h.on(dayKey(d)),d))available++;}
    return math.min(h.weeklyTarget,available);
  }
  Json get habitMap => json['habits'] as Json;
  Json get logs => json['log'] as Json;
  Json get goal => json['goal'] as Json;
  Json get prefs => json['prefs'] as Json;
  List<Habit> get allHabits => habitMap.values.map((v) => Habit(jsonMap(v))).toList();
  List<Habit> get habits => allHabits.where((h) => h.archived == null).toList();
  Json entry(String id, String day) => jsonMap(jsonMap(logs[day])[id]);
  double value(String id, String day) => (entry(id, day)['value'] as num? ?? 0).toDouble();
  bool completed(Habit h, String day) {
    final e = entry(h.id, day);
    final target = (e['target'] as num? ?? h.on(day).dailyTarget).toDouble();
    return value(h.id, day) >= target && target > 0;
  }
  int weekDone(Habit h, DateTime now) {
    final start = monday(now);
    var count = 0;
    for (var i = 0; i <= now.weekday - 1; i++) {
      final d = shiftDay(start, i);
      if (scheduled(h.on(dayKey(d)),d) && completed(h, dayKey(d))) count++;
    }
    return count;
  }
  List<Habit> due(DateTime now) => habits.where((h) => scheduled(h,now) &&
    (h.kind != 'weekly' || weekDone(h, now) < weeklyTargetFor(h,now) || completed(h, dayKey(now)))).toList();
  List<Habit> remaining(DateTime now) => due(now).where((h) => !completed(h, dayKey(now))).toList();
  double progress(DateTime now) {
    final list = due(now);
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (n,h) => n + (value(h.id, dayKey(now)) / h.dailyTarget).clamp(0,1)) / list.length;
  }
  int get bestStreak {
    final keys=logs.keys.toList()..sort();
    if(keys.isEmpty)return 0;
    var current=0,best=0;
    for(var d=DateTime.parse(keys.first);dayKey(d).compareTo(keys.last)<=0;d=shiftDay(d,1)) {
      if(protectedRest(d))continue;
      if(allHabits.any((h)=>completed(h,dayKey(d)))){current++;best=math.max(best,current);}else{current=0;}
    }
    return best;
  }
  int streak(DateTime now) {
    final keys=logs.keys.toList()..sort();
    if(keys.isEmpty)return 0;
    var d=dateOnly(now),count=0;
    if(!allHabits.any((h)=>completed(h,dayKey(d))) && !protectedRest(d))d=shiftDay(d,-1);
    while(dayKey(d).compareTo(keys.first)>=0) {
      if(protectedRest(d)){d=shiftDay(d,-1);continue;}
      if(!allHabits.any((h)=>completed(h,dayKey(d))))break;
      count++;d=shiftDay(d,-1);
    }
    return count;
  }
  List<Milestone> get milestones {
    var wins=0;double minutes=0;
    for(final day in logs.keys){for(final h in allHabits){
      if(completed(h,day))wins++;
      final old=h.on(day), e=entry(h.id,day);
      if(old.category=='Learning' && (e['unit']=='minutes'||e['unit']=='hours'))minutes+=value(h.id,day)*(e['unit']=='hours'?60:1);
    }}
    final best=bestStreak.toDouble();
    return [
      for(final goal in [1,10,25,50,100,250])Milestone('wins_$goal',goal==1?'Your first small win':'$goal small wins','Completed habit check-ins',wins.toDouble(),goal.toDouble()),
      for(final goal in [3,7,14,30])Milestone('streak_$goal','$goal active days','Best streak, with planned rest protected',best,goal.toDouble()),
      for(final goal in [10,20,50,100])Milestone('learn_$goal','$goal hours of learning','Time you made for growth',minutes/60,goal.toDouble()),
    ];
  }
  String reviewSummary(DateTime sunday) {
    final stats=week(sunday);
    if(stats.possible==0)return 'No scheduled habits this week. Choose one small intention for the week ahead.';
    final ranked=stats.byHabit.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final strongest=allHabits.firstWhere((h)=>h.id==ranked.first.key).name;
    return '${stats.done} of ${stats.possible} planned opportunities completed. $strongest was your most consistent habit. '
      '${stats.rate>=0.8?'Keep the rhythm that worked.':'Choose one habit to make easier next week.'}';
  }
  WeekStats week(DateTime now, {int offset = 0}) {
    final start = shiftDay(monday(now), offset * 7);
    final elapsed = now.weekday;
    var done = 0, possible = 0;
    final byHabit = <String, double>{};
    for (final original in allHabits) {
      var hd = 0, hp = 0;
      final weekH = original.on(dayKey(shiftDay(start, elapsed - 1)));
      for (var i=0; i<elapsed; i++) {
        final date = shiftDay(start,i);
        final key = dayKey(date);
        final h = original.on(key);
        if (!scheduled(h,date)) continue;
        hp++;
        if (completed(original,key)) hd++;
      }
      if (weekH.kind == 'weekly' && hp > 0) {
        hp = weeklyTargetFor(weekH, start); // full weekly goal, not a daily quota
        hd = math.min(hd, hp);
      }
      done += hd; possible += hp;
      if (hp > 0) byHabit[original.id] = hd / hp;
    }
    return WeekStats(done,possible,byHabit);
  }
  void apply(Json op) {
    final type = op['type'];
    final value = jsonMap(op['value']);
    if (type == 'habit') habitMap[op['key'] as String] = value;
    if (type == 'log') {
      final day = op['day'] as String;
      logs[day] = {...jsonMap(logs[day]), op['key'] as String:value};
    }
    if(type=='journal') {
      final day=op['day'] as String;
      journalMap[day]={...journal(day),op['key'] as String:value};
    }
    if(type=='review')reviews[op['key'] as String]=value;
    if(type=='rest')restDays[op['day'] as String]=value;
    if (type == 'prefs') prefs.addAll(value);
    if (type == 'goal') goal.addAll(value);
  }
}

class Milestone {
  const Milestone(this.id,this.title,this.detail,this.value,this.target);
  final String id,title,detail;
  final double value,target;
  bool get earned=>value>=target;
}

class WeekStats {
  const WeekStats(this.done, this.possible, this.byHabit);
  final int done, possible;
  final Map<String,double> byHabit;
  double get rate => possible == 0 ? 0 : done / possible;
}

String greeting(DateTime now) => now.hour < 5 ? 'A quiet moment' : now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';
String focusQuote(TrackerData data, DateTime now) {
  final left = data.remaining(now);
  if(data.rest(now))return 'Today is for recovery. Rest belongs in your rhythm.';
  if(data.prefs['tone']=='direct')return data.due(now).isEmpty?'No habits scheduled today.':left.isEmpty?'Today’s plan is complete.':'${left.length} habits left. Pick the next action and begin.';
  if (data.due(now).isEmpty) return 'Room to breathe. Your next step can wait.';
  if (left.isEmpty) return 'You showed up for yourself. Let that be enough today.';
  if (now.hour >= 22 || now.hour < 5) return 'Rest is part of progress. Tomorrow is another chance.';
  final learning = left.where((h) => h.category == 'Learning');
  final health = left.where((h) => h.category == 'Health');
  if (now.hour >= 17) return '${left.length} ${left.length == 1 ? 'habit' : 'habits'} left. Choose one small win before you wind down.';
  if (now.hour >= 12 && learning.isNotEmpty) return 'A little time for ${learning.first.name.toLowerCase()} can move your day forward.';
  if (now.hour < 12 && health.isNotEmpty) return 'Start with yourself. Make a little space for ${health.first.name.toLowerCase()}.';
  const lines = ['Small actions become the life you build.', 'Consistency begins with the next small step.', 'You do not need a perfect day to make progress.', 'Give your attention to one thing that matters.'];
  return lines[(now.day + now.hour ~/ 6) % lines.length];
}
