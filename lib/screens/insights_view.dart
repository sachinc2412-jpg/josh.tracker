import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/ui.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});
  @override
  Widget build(BuildContext context) {
    final data=store.data,now=store.now;
    final current=data.week(now),previous=data.week(now,offset:-1);
    final delta=((current.rate-previous.rate)*100).round();
    return ListView(padding:const EdgeInsets.fromLTRB(24,24,24,132),children:[
      const PageTitle('Insights','The small things are adding up.'),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('THIS WEEK SO FAR',style:TextStyle(color:C.label2,fontSize:11,letterSpacing:1.5)),gap,
        Text(current.possible==0?'—':'${(current.rate*100).round()}%',style:const TextStyle(fontSize:52,fontWeight:FontWeight.w600,letterSpacing:-2)),
        Text('${current.done} completed / ${current.possible} opportunities',style:const TextStyle(color:C.label2)),gap,
        if(previous.possible>0)Text('${delta>=0?'+':''}$delta percentage points vs the same weekdays last week',style:TextStyle(color:delta>=0?C.green:C.label2,fontSize:13,height:1.5))
        else const Text('Your comparison will appear once you have a previous week to look back on.',style:TextStyle(color:C.label2,fontSize:13,height:1.5)),
      ])),gap,
      Row(children:[Expanded(child:Panel(child:_metric('${data.streak(now)}','Current active streak'))),const SizedBox(width:12),Expanded(child:Panel(child:_metric('${data.bestStreak}','Best active streak')))]),
      const Padding(padding:EdgeInsets.only(top:10,bottom:14),child:Text('An active day has at least one completed habit.',style:TextStyle(color:C.label3,fontSize:11))),
      const SectionLabel('Your last seven days'),
      Panel(child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(var i=6;i>=0;i--)Expanded(child:_bar(shiftDay(now,-i)))])),gap,
      const SectionLabel('Habit by habit'),
      if(current.byHabit.isEmpty)const Panel(child:Text('Log your first habit to start finding your rhythm.',style:TextStyle(color:C.label2))),
      for(final entry in current.byHabit.entries)Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text(data.allHabits.firstWhere((h)=>h.id==entry.key).name,style:const TextStyle(fontWeight:FontWeight.w500))),
          Text('${(entry.value*100).round()}%',style:const TextStyle(color:C.label2))]),const SizedBox(height:14),
        ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:entry.value,minHeight:5,color:C.blue,backgroundColor:C.card2)),
      ]))),gap,
      const Panel(child:Text('Daily goals count scheduled days up to today. Weekly goals count completed days toward the full weekly target. Comparisons use the same weekdays; archived habits retain their earlier history.',style:TextStyle(color:C.label2,fontSize:12,height:1.6))),
    ]);
  }
  Widget _metric(String value,String label)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w600)),const SizedBox(height:6),Text(label,style:const TextStyle(color:C.label2,fontSize:12,height:1.4))]);
  Widget _bar(DateTime date) {
    final data=store.data,key=dayKey(date);
    final scheduled=data.allHabits.where((h)=>h.on(key).scheduled(date)).toList();
    final done=scheduled.where((h)=>data.completed(h,key)).length;
    final ratio=scheduled.isEmpty?0.0:done/scheduled.length;
    return Semantics(label:'${DateFormat('EEEE').format(date)}: $done completed habits',child:Column(children:[
      Text('$done',style:const TextStyle(color:C.label2,fontSize:11)),const SizedBox(height:9),
      Container(height:94,alignment:Alignment.bottomCenter,child:Container(width:18,height:6+ratio*88,
        decoration:BoxDecoration(color:dayKey(date)==store.todayKey?C.blue:C.label2,borderRadius:BorderRadius.circular(6)))),
      const SizedBox(height:12),Text(DateFormat('EEEEE').format(date),style:const TextStyle(color:C.label2,fontSize:11)),
    ]));
  }
}
