import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models.dart';

Habit habit(TrackerData data,{String kind='check',int target=4}) {
  final h=Habit({'id':'h','name':'Read','category':'Learning','kind':kind,'target':60,'unit':'minutes','weeklyTarget':target,'created':'2026-09-01'});
  data.habitMap[h.id]=h.data;
  return h;
}
void complete(TrackerData data,String day,{double value=1})=>data.apply({'type':'log','day':day,'key':'h','value':{'value':value,'target':1,'unit':'times'}});
void main(){
  test('priorities, check-in and reflection merge independently and survive serialization',(){
    final d=TrackerData.empty();
    final ops=[
      {'type':'journal','day':'2026-09-23','key':'priority_0','value':{'text':'Finish a chapter','done':true}},
      {'type':'journal','day':'2026-09-23','key':'checkin','value':{'mood':4,'energy':2,'note':'A quiet start'}},
      {'type':'journal','day':'2026-09-23','key':'reflection','value':{'win':'Read','challenge':'Time','tomorrow':'Start early'}},
      {'type':'journal','day':'2026-09-23','key':'priority_1','value':{'text':'Call home','done':false}},
    ];
    for(final op in ops)d.apply(op);
    d.apply(ops.first); // idempotent value replay must preserve other fields
    expect(d.journal('2026-09-23').length,4);
    expect(jsonMap(d.journal('2026-09-23')['priority_0'])['done'],true);
    expect(jsonMap(d.journal('2026-09-23')['checkin'])['energy'],2);
    expect(d.journal('2026-09-24'),isEmpty);
    final restored=TrackerData(jsonMap(jsonDecode(jsonEncode(d.json))));
    expect(restored.journal('2026-09-23'),d.journal('2026-09-23'));
  });
  test('planned rest removes opportunities, protects streak and adds no active day',(){
    final d=TrackerData.empty();habit(d);
    complete(d,'2026-09-21');complete(d,'2026-09-23');
    d.apply({'type':'rest','day':'2026-09-22','value':{'rest':true}});
    expect(d.due(DateTime(2026,9,22)),isEmpty);
    expect(d.week(DateTime(2026,9,23)).possible,2);
    expect(d.week(DateTime(2026,9,23)).done,2);
    expect(d.streak(DateTime(2026,9,23)),2);
    expect(d.bestStreak,2);
    expect(d.streak(DateTime(2026,9,25)),0); // an unplanned missed day still breaks it
  });
  test('recurring rest versions preserve earlier schedules and allow a daily override',(){
    final d=TrackerData.empty();habit(d);
    d.prefs['restVersions']=[{'from':'2026-09-21','days':[2]},{'from':'2026-09-24','days':[5]}];
    expect(d.rest(DateTime(2026,9,15)),false);
    expect(d.rest(DateTime(2026,9,22)),true);
    expect(d.rest(DateTime(2026,9,25)),true);
    expect(d.rest(DateTime(2026,9,29)),false);
    d.apply({'type':'rest','day':'2026-09-22','value':{'rest':false}});
    expect(d.rest(DateTime(2026,9,22)),false);
  });
  test('pause boundaries are inclusive and weekly targets reflect available days',(){
    final d=TrackerData.empty();final h=habit(d,kind:'weekly',target:4);
    h.data['pauses']=[{'start':'2026-09-22','end':'2026-09-26'}];
    expect(d.weeklyTargetFor(h,DateTime(2026,9,23)),2);
    expect(d.due(DateTime(2026,9,22)),isEmpty);
    expect(d.due(DateTime(2026,9,26)),isEmpty);
    complete(d,'2026-09-21');
    expect(d.remaining(DateTime(2026,9,27)).length,1);
    complete(d,'2026-09-27');
    expect(d.week(DateTime(2026,9,27)).rate,1);
    expect(d.bestStreak,2);
    expect(d.remaining(DateTime(2026,9,28)).length,1);
  });
  test('a pause for one habit does not excuse a missed day for another',(){
    final d=TrackerData.empty();final h=habit(d);
    h.data['pauses']=[{'start':'2026-09-22','end':'2026-09-22'}];
    d.habitMap['b']={'id':'b','name':'Walk','created':'2026-09-01'};
    complete(d,'2026-09-21');complete(d,'2026-09-23');
    expect(d.protectedRest(DateTime(2026,9,22)),false);
    expect(d.streak(DateTime(2026,9,23)),1);
  });
  test('fully resting a week has zero opportunities and no division error',(){
    final d=TrackerData.empty();habit(d,kind:'weekly');
    d.prefs['restWeekdays']=[1,2,3,4,5,6,7];
    expect(d.week(DateTime(2026,9,27)).possible,0);
    expect(d.week(DateTime(2026,9,27)).rate,0);
    expect(d.reviewSummary(DateTime(2026,9,27)),contains('No scheduled'));
    expect(d.streak(DateTime(2026,9,27)),0);
  });
  test('milestones count habit-day wins and actual learning time without double logging',(){
    final d=TrackerData.empty();habit(d,kind:'quantity');
    final op={'type':'log','day':'2026-09-23','key':'h','value':{'value':600,'target':60,'unit':'minutes'}};
    d.apply(op);d.apply(op);
    expect(d.milestones.firstWhere((m)=>m.id=='wins_1').earned,true);
    expect(d.milestones.firstWhere((m)=>m.id=='wins_10').earned,false);
    expect(d.milestones.firstWhere((m)=>m.id=='learn_10').earned,true);
    expect(d.milestones.firstWhere((m)=>m.id=='learn_20').value,10);
    d.apply({'type':'log','day':'2026-09-23','key':'h','value':{'value':0,'target':60,'unit':'minutes'}});
    expect(d.milestones.firstWhere((m)=>m.id=='wins_1').earned,false);
  });
  test('weekly intentions use week-specific keys and tone respects rest',(){
    final d=TrackerData.empty();habit(d);
    d.apply({'type':'review','key':'2026-09-21','value':{'note':'Start with ten minutes'}});
    d.apply({'type':'review','key':'2026-09-14','value':{'note':'Sleep earlier'}});
    expect(d.reviews.length,2);
    d.prefs['tone']='direct';
    expect(focusQuote(d,DateTime(2026,9,23)),contains('Pick the next action'));
    d.apply({'type':'rest','day':'2026-09-23','value':{'rest':true}});
    expect(focusQuote(d,DateTime(2026,9,23)),contains('recovery'));
  });
}
