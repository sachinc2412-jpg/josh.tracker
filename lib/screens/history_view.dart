import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/ui.dart';
import 'daily_journal.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState()=>_HistoryViewState();
}
class _HistoryViewState extends State<HistoryView> {
  int _offset=0;
  String _selected=dayKey(DateTime.now());
  @override
  Widget build(BuildContext context) {
    final now=store.now,data=store.data;
    final month=DateTime(now.year,now.month+_offset,1);
    final count=DateUtils.getDaysInMonth(month.year,month.month);
    final selectedDate=DateTime.parse(_selected);
    final selected=data.allHabits.where((h)=>data.scheduled(h.on(_selected),selectedDate) || data.entry(h.id,_selected).isNotEmpty).toList();
    return ListView(padding: EdgeInsets.fromLTRB(24,24,24,132),children:[
       PageTitle('History','Every day tells part of your story.'),
      Panel(child:Column(children:[
        Row(children:[IconButton(tooltip:'Previous month',onPressed:()=>setState(()=>_offset--),icon: Icon(Icons.chevron_left)),
          Expanded(child:Text(DateFormat('MMMM y').format(month),textAlign:TextAlign.center,style: TextStyle(fontSize:18,fontWeight:FontWeight.w600))),
          IconButton(tooltip:'Next month',onPressed:_offset<0?()=>setState(()=>_offset++):null,icon: Icon(Icons.chevron_right))]),gap,
        Row(children:[for(final d in ['M','T','W','T','F','S','S'])Expanded(child:Text(d,textAlign:TextAlign.center,style: TextStyle(color:C.label2,fontSize:11)))]),
         SizedBox(height:12),GridView.count(crossAxisCount:7,shrinkWrap:true,physics: NeverScrollableScrollPhysics(),mainAxisSpacing:6,crossAxisSpacing:6,
          children:[for(var i=1;i<month.weekday;i++) SizedBox(),for(var d=1;d<=count;d++)_day(DateTime(month.year,month.month,d))]),
      ])),gap,
      SectionLabel(DateFormat('EEEE, MMMM d').format(selectedDate)),
      Panel(padding:4,child:ListTile(leading:Icon(Icons.edit_note_rounded,color:C.blue),title:Text('Your daily journal'),subtitle:Text(data.protectedRest(selectedDate)?'Planned rest · priorities, check-in & reflection':'Priorities, mood, energy & reflection'),trailing:Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>JournalDayScreen(_selected))))),gap,
      if(selected.isEmpty) Panel(child:Text('No scheduled habits on this day.',style:TextStyle(color:C.label2))),
      for(final original in selected)Builder(builder:(context){
        final h=original.on(_selected),done=data.completed(original,_selected),entry=data.entry(h.id,_selected);
        return Padding(padding: EdgeInsets.only(bottom:10),child:Panel(child:Row(children:[Icon(done?Icons.check_circle_rounded:Icons.circle_outlined,color:done?C.green:C.label3,size:22),
           SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h.name), SizedBox(height:5),
            Text(h.kind=='quantity'?'${number(data.value(h.id,_selected))} / ${number((entry['target'] as num?)??h.target)} ${entry['unit']??h.unit}':done?'Completed':'Not logged',style: TextStyle(color:C.label2,fontSize:12))]))])));
      }),
    ]);
  }
  Widget _day(DateTime d) {
    final key=dayKey(d),data=store.data;
    final future=key.compareTo(store.todayKey)>0;
    final done=data.allHabits.where((h)=>data.completed(h,key)).length;
    return Semantics(label:'${DateFormat('MMMM d').format(d)}, $done completed',selected:key==_selected,child:InkWell(onTap:future?null:()=>setState(()=>_selected=key),borderRadius:BorderRadius.circular(11),
      child:Container(alignment:Alignment.center,decoration:BoxDecoration(color:done>0? Color(0x332F8CFF):C.card2,borderRadius:BorderRadius.circular(11),border:key==_selected?Border.all(color:C.label):null),
        child:Text('${d.day}',style:TextStyle(fontSize:13,color:future?C.label3:done>0?C.blue:C.label)))));
  }
}
