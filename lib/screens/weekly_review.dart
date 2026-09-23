import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models.dart';
import '../config.dart';
import '../widgets/ui.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});
  @override
  State<WeeklyReviewScreen> createState()=>_WeeklyReviewScreenState();
}
class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  int _offset=0;
  @override
  Widget build(BuildContext context) {
    final currentEnd=store.now.weekday==7?dateOnly(store.now):shiftDay(monday(store.now),-1);
    final end=shiftDay(currentEnd,_offset*7),start=monday(end),key=dayKey(start);
    return Scaffold(appBar:AppBar(title:Text('Weekly review')),body:AnimatedBuilder(animation:store,builder:(context,_){
      final data=store.data,stats=data.week(end),note=jsonMap(data.reviews[key]);
      var mood=0.0,energy=0.0,count=0,reflections=0,priorities=0,rest=0;
      for(var i=0;i<7;i++){
        final date=shiftDay(start,i),j=data.journal(dayKey(shiftDay(start,i))),c=jsonMap(data.journal(dayKey(shiftDay(start,i)))['checkin']);
        if(c.isNotEmpty){mood+=(c['mood'] as num).toDouble();energy+=(c['energy'] as num).toDouble();count++;}
        if(jsonMap(j['reflection']).values.any((v)=>v.toString().trim().isNotEmpty))reflections++;
        for(var k=0;k<3;k++){if(jsonMap(j['priority_$k'])['done']==true)priorities++;}
        if(data.protectedRest(date))rest++;
      }
      return ListView(padding:EdgeInsets.all(24),children:[
        Row(children:[IconButton(tooltip:'Previous week',onPressed:()=>setState(()=>_offset--),icon:Icon(Icons.chevron_left)),
          Expanded(child:Text('${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}',textAlign:TextAlign.center)),
          IconButton(tooltip:'Next week',onPressed:_offset<0?()=>setState(()=>_offset++):null,icon:Icon(Icons.chevron_right))]),gap,
        PageTitle('A week of becoming.',end==dateOnly(store.now)?'This week so far':'A look back, without judgment.'),
        Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(stats.possible==0?'No goals scheduled':'${(stats.rate*100).round()}% complete',style:TextStyle(fontSize:30,fontWeight:FontWeight.w600)),gap,
          Text(data.reviewSummary(end),style:TextStyle(color:C.label2,height:1.6))])),gap,
        Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('$priorities priorities completed · $reflections reflections',style:TextStyle(height:1.6)),
          Text('$rest planned rest days',style:TextStyle(color:C.label2)),gap,
          Text(count==0?'No mood or energy check-ins this week.':'Average mood ${(mood/count).toStringAsFixed(1)}/5 · energy ${(energy/count).toStringAsFixed(1)}/5',style:TextStyle(color:C.label2,height:1.5)),
          if(count>0)Text('Based on $count daily check-ins',style:TextStyle(fontSize:12,color:C.label3)),
        ])),gap,
        SectionLabel('Carry one thing forward'),
        Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(note['note'] as String? ?? 'What would make next week feel better?',style:TextStyle(height:1.5)),gap,
          ActionButton(note.isEmpty?'Set next week’s intention':'Edit your intention',()async{
            final result=await showDialog<String>(context:context,builder:(_)=>_ReviewNote(note['note'] as String? ?? ''));
            if(result!=null)await store.saveReview(key,{'note':result});
          },secondary:true),
        ])),
      ]);
    }));
  }
}
class _ReviewNote extends StatefulWidget {
  const _ReviewNote(this.initial);
  final String initial;
  @override
  State<_ReviewNote> createState()=>_ReviewNoteState();
}
class _ReviewNoteState extends State<_ReviewNote> {
  late final _text=TextEditingController(text:widget.initial);
  @override
  void dispose(){_text.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>AlertDialog(title:Text('One small adjustment'),content:TextField(controller:_text,maxLines:4,maxLength:600,decoration:InputDecoration(hintText:'Next week I will…')),actions:[
    TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel')),TextButton(onPressed:()=>Navigator.pop(context,_text.text.trim()),child:Text('Save'))]);
}
class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Milestones')),body:AnimatedBuilder(animation:store,builder:(context,_)=>ListView(padding:EdgeInsets.all(24),children:[
    PageTitle('Small wins. Real growth.','Achievements based on your recorded progress.'),
    for(final m in store.data.milestones)Padding(padding:EdgeInsets.only(bottom:12),child:Panel(child:Row(children:[
      Icon(m.earned?Icons.workspace_premium_outlined:Icons.radio_button_unchecked,color:m.earned?C.blue:C.label3,size:30),SizedBox(width:16),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.title,style:TextStyle(fontWeight:FontWeight.w600,fontSize:17)),SizedBox(height:6),Text(m.detail,style:TextStyle(color:C.label2,fontSize:12)),SizedBox(height:10),
        LinearProgressIndicator(value:(m.value/m.target).clamp(0,1).toDouble(),color:C.blue,backgroundColor:C.card2),SizedBox(height:6),
        Text(m.earned?'Achieved':'${number(m.value)} / ${number(m.target)}',style:TextStyle(color:C.label2,fontSize:12)),
      ])),
    ]))),
  ])));
}
