import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../main.dart';
import '../store.dart';
import '../widgets/ui.dart';
import 'habit_editor.dart';
import 'daily_journal.dart';
import 'weekly_review.dart';
import 'personalization.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});
  @override
  Widget build(BuildContext context) {
    final now=store.now,data=store.data;
    final due=data.due(now),left=data.remaining(now);
    final completed=due.length-left.length;
    final focus=List<Habit>.from(left)..sort((a,b)=>a.reminder.compareTo(b.reminder));
    return RefreshIndicator(onRefresh:store.retry,color:C.blue,child:ListView(
      physics: AlwaysScrollableScrollPhysics(),padding: EdgeInsets.fromLTRB(24,24,24,132),children:[
        Row(children:[
          Expanded(child:Text(DateFormat('EEEE, MMMM d').format(now).toUpperCase(),style: TextStyle(color:C.label2,fontSize:11,letterSpacing:1.3))),
          _syncChip(context),
        ]), SizedBox(height:22),
        Text('${greeting(now)},\n${store.name.isEmpty?'Joshua':store.name}.',style: TextStyle(fontSize:35,fontWeight:FontWeight.w600,letterSpacing:-1.4,height:1.15)),
         SizedBox(height:14),AnimatedSwitcher(duration: Duration(milliseconds:300),
          child:Text(focusQuote(data,now),key:ValueKey(focusQuote(data,now)),style: TextStyle(color:C.label2,fontSize:15,height:1.6))),gap,
        Panel(child:Column(children:[
          ProgressRing(data.progress(now)), SizedBox(height:10),
          Text(due.isEmpty?'A little space for you':left.isEmpty?'A day well spent':'$completed of ${due.length} habits complete',
            style: TextStyle(fontSize:17,fontWeight:FontWeight.w600)),
           SizedBox(height:8),Text(due.isEmpty?'No habits due today.':left.isEmpty?'Your progress is worth a pause.':'Every small action counts.',style: TextStyle(color:C.label2,fontSize:13)),
           SizedBox(height:22), Divider(height:1), SizedBox(height:18),
          Row(children:[_stat('${data.streak(now)}','day active streak'),Container(height:32,width:1,color:C.sep),_stat('${data.week(now).done}','wins this week')]),
        ])),gap,
        DailyJournal(day:store.todayKey,prioritiesOnly:true),gap,
        if(now.weekday==7) ...[Panel(padding:4,child:ListTile(leading:Icon(Icons.auto_stories_outlined,color:C.blue),title:Text('Your weekly review is ready'),subtitle:Text('Take a moment to look back'),trailing:Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>WeeklyReviewScreen())))),gap],
        if(focus.isNotEmpty)...[
           SectionLabel('Your next small win'),
          Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Icon(categoryIcon(focus.first.category),color:C.blue,size:22), SizedBox(width:10),
              Expanded(child:Text(focus.first.name,style: TextStyle(fontSize:18,fontWeight:FontWeight.w600)))]),
             SizedBox(height:10),Text(_remaining(focus.first),style: TextStyle(color:C.label2)),
             SizedBox(height:16),ActionButton(focus.first.kind=='quantity'?'Log progress':'Mark complete',()=>logHabit(context,focus.first)),
          ])),gap,
        ],
        Row(children:[ Expanded(child:SectionLabel('Your rhythm')),TextButton(onPressed:()=>editHabit(context),child: Text('+ Add'))]),
        if(due.isEmpty) Panel(child:Column(children:[ Icon(Icons.spa_outlined,color:C.label2,size:30),gap,
           Text(data.protectedRest(now)?'Recovery is part of your rhythm.':'Set a small intention for today.'),gap,ActionButton(data.protectedRest(now)?'Manage rest':'Add a habit',(){if(data.protectedRest(now)){Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>RestScreen()));}else{editHabit(context);}},secondary:true)])),
        for(final h in due) Padding(padding: EdgeInsets.only(bottom:10),child:_habit(context,h)),
        if(data.habits.any((h)=>h.kind=='weekly')) ...[
           SectionLabel('Your weekly goals'),
          for(final h in data.habits.where((h)=>h.kind=='weekly')) Padding(padding: EdgeInsets.only(bottom:10),
            child:Panel(child:Row(children:[Expanded(child:Text(h.name)),Text('${data.weekDone(h,now)} / ${data.weeklyTargetFor(h,now)} days',style: TextStyle(color:C.label2))]))),
        ],
        gap,DailyJournal(day:store.todayKey,withPriorities:false),gap,
        Panel(padding:4,child:ListTile(leading:Icon(Icons.spa_outlined,color:C.label2),title:Text(data.protectedRest(now)?'A planned day of rest':'Need a little space?'),subtitle:Text('Rest days & habit pauses'),trailing:Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>RestScreen())))),
        gap,Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
           Text('THE BIGGER PICTURE',style:TextStyle(color:C.label2,fontSize:10,letterSpacing:1.4)),
           SizedBox(height:10),Text(data.goal['label'] as String? ?? 'Keep showing up',style: TextStyle(fontSize:19,fontWeight:FontWeight.w500,height:1.4)),
           SizedBox(height:10),Text('Your target · ${data.goal['target']}',style: TextStyle(color:C.label2,fontSize:12)),
        ])),
      ]));
  }
  Widget _stat(String value,String label)=>Expanded(child:Column(children:[Text(value,style: TextStyle(fontSize:22,fontWeight:FontWeight.w600)),
     SizedBox(height:5),Text(label,style: TextStyle(fontSize:11,color:C.label2),textAlign:TextAlign.center)]));
  String _remaining(Habit h) {
    if(h.kind=='weekly') return '${store.data.weekDone(h,store.now)} of ${store.data.weeklyTargetFor(h,store.now)} days this week. One day at a time.';
    if(h.kind=='quantity') return '${number((h.target-store.data.value(h.id,store.todayKey)).clamp(0,h.target))} ${h.unit} left for today.';
    return 'A small promise to yourself. Ready when you are.';
  }
  Widget _habit(BuildContext context,Habit h) {
    final done=store.data.completed(h,store.todayKey);
    final value=store.data.value(h.id,store.todayKey);
    return Semantics(button:true,label:'${h.name}, ${done?'completed':_remaining(h)}',child:Material(color:C.card,borderRadius:BorderRadius.circular(22),
      child:InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>logHabit(context,h),
        child:Padding(padding: EdgeInsets.all(17),child:Row(children:[
          Container(width:42,height:42,decoration:BoxDecoration(color:C.card2,borderRadius:BorderRadius.circular(13)),child:Icon(categoryIcon(h.category),size:21,color:done?C.green:C.label2)),
           SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(h.name,style:TextStyle(fontSize:16,fontWeight:FontWeight.w500,color:done?C.label2:C.label)),
             SizedBox(height:6),Text(h.kind=='quantity'?'${number(value)} / ${number(h.target)} ${h.unit}':h.kind=='weekly'?h.targetLabel:done?'Complete':'Tap to check in',style: TextStyle(fontSize:12,color:C.label2)),
            if(h.kind=='quantity') Padding(padding: EdgeInsets.only(top:10),child:ClipRRect(borderRadius:BorderRadius.circular(4),
              child:LinearProgressIndicator(value:(value/h.target).clamp(0,1).toDouble(),minHeight:3,backgroundColor:C.card2,color:done?C.green:C.blue))),
          ])),
          if(!done && h.remind && store.data.prefs['reminders']==true) IconButton(tooltip:'Remind me in 30 minutes',icon: Icon(Icons.snooze_rounded,size:20,color:C.label2),onPressed:()async{
            final ok=await store.reminders.snooze(h.id);
            if(context.mounted)message(context,ok?'Snoozed for 30 minutes, respecting quiet hours.':'Enable notifications in Settings first.');
          }),
           SizedBox(width:8),AnimatedSwitcher(duration: Duration(milliseconds:220),child:Icon(done?Icons.check_circle_rounded:Icons.radio_button_unchecked,key:ValueKey(done),color:done?C.green:C.label3,size:26)),
        ])))));
  }
  Widget _syncChip(BuildContext context)=>TextButton(onPressed:()=>showModalBottomSheet<void>(context:context,showDragHandle:true,backgroundColor:C.card,
    builder:(_)=>SafeArea(child:Padding(padding: EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(store.syncLabel,style: TextStyle(fontSize:23,fontWeight:FontWeight.w600)),gap,
      Text(store.syncError??'Your changes are saved on this device and in your account.',style: TextStyle(color:C.label2,height:1.5)),
      if(store.pendingCount>0)Text('${store.pendingCount} changes waiting',style: TextStyle(color:C.label2)),gap,
      ActionButton('Retry sync',(){Navigator.pop(context);store.retry();}),
    ])))),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(store.syncState==SyncState.saved?Icons.cloud_done_outlined:Icons.cloud_upload_outlined,size:15,color:store.syncState==SyncState.saved?C.label2:C.orange),
       SizedBox(width:5),Text(store.syncLabel,style: TextStyle(fontSize:11,color:C.label2))]));
}
