import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models.dart';

Habit add(TrackerData data,String id,{String kind='check',double target=1,int weekly=4,String created='2026-09-01',List<int> days=const [1,2,3,4,5,6,7]}) {
  final h=Habit({'id':id,'name':id,'kind':kind,'target':target,'weeklyTarget':weekly,'created':created,'weekdays':days});
  data.habitMap[id]=h.data; return h;
}
void log(TrackerData data,Habit h,String day,double value) => data.apply({'type':'log','key':h.id,'day':day,'value':{'value':value,'target':h.dailyTarget}});
void main() {
  test('legacy booleans become amounts without losing history',(){
    final data=TrackerData.legacy({'habits':[{'id':'1','name':'Gym','emoji':'G'}],'log':{'2026-09-20':{'1':true},'2026-09-21':{'1':false}},'goal':{'label':'My sprint'}});
    expect(data.value('1','2026-09-20'),1);
    expect(data.value('1','2026-09-21'),0);
    expect(data.completed(data.habits.single,'2026-09-20'),true);
    expect(data.goal['label'],'My sprint');
    expect(data.prefs['onboarded'],false);
  });
  test('quantity contributes fractional progress and caps at target',(){
    final date=DateTime(2026,9,22),data=TrackerData.empty();
    final sleep=add(data,'sleep',kind:'quantity',target:8);
    log(data,sleep,dayKey(date),4);
    expect(data.progress(date),0.5);
    expect(data.remaining(date).length,1);
    log(data,sleep,dayKey(date),10);
    expect(data.progress(date),1);
    expect(data.remaining(date),isEmpty);
  });
  test('weekly goal completes on distinct days and resets Monday',(){
    final data=TrackerData.empty(),h=addDummy();
    data.habitMap[h.id]=h.data;
    for(final d in [14,15,16,17])log(data,h,'2026-09-$d',1);
    log(data,h,'2026-09-17',1); // repeated save is still one day
    expect(data.weekDone(h,DateTime(2026,9,18)),4);
    expect(data.remaining(DateTime(2026,9,18)),isEmpty);
    expect(data.weekDone(h,DateTime(2026,9,21)),0);
    expect(data.remaining(DateTime(2026,9,21)).length,1);
  });
  test('week stats compare the same elapsed weekdays',(){
    final data=TrackerData.empty(),date=DateTime(2026,9,22); // Tuesday
    final h=add(data,'learn');
    log(data,h,'2026-09-21',1);log(data,h,'2026-09-22',1);
    log(data,h,'2026-09-14',1);log(data,h,'2026-09-16',1); // last Wednesday excluded
    expect(data.week(date).rate,1);
    expect(data.week(date,offset:-1).rate,0.5);
    expect(data.week(date).possible,2);
  });
  test('weekly insight denominator uses weekly target',(){
    final data=TrackerData.empty(),h=addDummy();data.habitMap[h.id]=h.data;
    log(data,h,'2026-09-21',1);
    expect(data.week(DateTime(2026,9,22)).possible,4);
    expect(data.week(DateTime(2026,9,22)).rate,0.25);
  });
  test('unscheduled days and days before creation are not opportunities',(){
    final data=TrackerData.empty();
    add(data,'gym',created:'2026-09-22',days:[1,3,5]);
    expect(data.due(DateTime(2026,9,21)),isEmpty);
    expect(data.due(DateTime(2026,9,22)),isEmpty);
    expect(data.due(DateTime(2026,9,23)).length,1);
  });
  test('goal edits do not reinterpret already logged targets',(){
    final data=TrackerData.empty();
    final h=add(data,'sleep',kind:'quantity',target:8);
    log(data,h,'2026-09-21',8);
    data.habitMap[h.id]={...h.data,'target':9,'versions':[
      {...h.data,'from':'2026-09-01'}, {...h.data,'target':9,'from':'2026-09-22'}]};
    final updated=data.habits.single;
    expect(updated.on('2026-09-21').target,8);
    expect(updated.on('2026-09-22').target,9);
    expect(data.completed(updated,'2026-09-21'),true);
  });
  test('archiving keeps history and removes future opportunities',(){
    final data=TrackerData.empty();final h=add(data,'gym');
    log(data,h,'2026-09-21',1);
    data.habitMap[h.id]={...h.data,'archived':'2026-09-22'};
    expect(data.habits,isEmpty);
    expect(data.allHabits.length,1);
    expect(data.week(DateTime(2026,9,22)).done,1);
    expect(data.week(DateTime(2026,9,22)).possible,1);
  });
  test('active streak tolerates today still being unfinished',(){
    final data=TrackerData.empty();final h=add(data,'gym');
    for(final day in [19,20,21])log(data,h,'2026-09-$day',1);
    expect(data.streak(DateTime(2026,9,22)),3);
    expect(data.streak(DateTime(2026,9,23)),0);
    expect(data.bestStreak,3);
  });
  test('independent edits merge and replay is idempotent',(){
    final data=TrackerData.empty();add(data,'a');add(data,'b');
    final a=<String,dynamic>{'type':'log','key':'a','day':'2026-09-22','value':{'value':1,'target':1}};
    final b=<String,dynamic>{'type':'log','key':'b','day':'2026-09-22','value':{'value':1,'target':1}};
    data.apply(a);data.apply(b);data.apply(a);
    expect(data.value('a','2026-09-22'),1);expect(data.value('b','2026-09-22'),1);
  });
  test('dashboard copy adapts to time and unfinished activity',(){
    final data=TrackerData.empty();final h=add(data,'Read');
    data.habitMap[h.id]={...h.data,'category':'Learning'};
    expect(greeting(DateTime(2026,9,22,8)),'Good morning');
    expect(greeting(DateTime(2026,9,22,14)),'Good afternoon');
    expect(greeting(DateTime(2026,9,22,20)),'Good evening');
    expect(focusQuote(data,DateTime(2026,9,22,14)),contains('read'));
    log(data,h,'2026-09-22',1);
    expect(focusQuote(data,DateTime(2026,9,22,20)),contains('showed up'));
  });
}
Habit addDummy()=>Habit({'id':'gym','name':'Gym','kind':'weekly','weeklyTarget':4,'created':'2026-09-01'});
