import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models.dart';
import '../config.dart';
import '../widgets/ui.dart';

class DailyJournal extends StatelessWidget {
  const DailyJournal({super.key,required this.day,this.prioritiesOnly=false,this.withPriorities=true});
  final String day;
  final bool prioritiesOnly,withPriorities;
  @override
  Widget build(BuildContext context) {
    final j=store.data.journal(day),check=jsonMap(store.data.journal(day)['checkin']);
    final reflection=jsonMap(j['reflection']);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(withPriorities)...[
        Row(children:[Expanded(child:SectionLabel('What matters today')),TextButton(onPressed:()=>_edit(context,'priorities'),child:Text('Edit'))]),
        Panel(padding:8,child:Column(children:[
          for(var i=0;i<3;i++)Builder(builder:(context){
            final p=jsonMap(j['priority_$i']);
            final text=p['text'] as String? ?? '';
            if(text.isEmpty)return ListTile(leading:Icon(Icons.add_rounded,color:C.label3),title:Text('Choose priority ${i+1}',style:TextStyle(color:C.label2,fontSize:14)),onTap:()=>_edit(context,'priorities'));
            return CheckboxListTile(contentPadding:EdgeInsets.symmetric(horizontal:8),controlAffinity:ListTileControlAffinity.leading,value:p['done']==true,
              title:Text(text,style:TextStyle(fontSize:15,color:p['done']==true?C.label2:C.label)),
              onChanged:(v)=>store.saveJournal(day,'priority_$i',{...p,'done':v==true}));
          }),
        ])),gap,
      ],
      if(!prioritiesOnly)...[
        SectionLabel('A moment for you'),
        Panel(padding:8,child:ListTile(leading:Icon(Icons.wb_sunny_outlined,color:C.blue),
          title:Text('Mood & energy'),subtitle:Text(check.isEmpty?'How are you arriving today?':'Mood ${check['mood']}/5 · Energy ${check['energy']}/5'),
          trailing:Icon(Icons.chevron_right),onTap:()=>_edit(context,'checkin'))),SizedBox(height:10),
        Panel(padding:8,child:ListTile(leading:Icon(Icons.nights_stay_outlined,color:C.blue),
          title:Text('Evening reflection'),subtitle:Text(reflection.isEmpty?(store.now.hour>=17?'Give today a gentle close.':'Capture a thought whenever you like.'):'Your thoughts are saved. Revisit or edit.'),
          trailing:Icon(Icons.chevron_right),onTap:()=>_edit(context,'reflection'))),gap,
      ],
    ]);
  }
  Future<void> _edit(BuildContext context,String kind)=>showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:C.card,
    builder:(_)=>_JournalEditor(day:day,kind:kind));
}
class JournalDayScreen extends StatelessWidget {
  const JournalDayScreen(this.day,{super.key});
  final String day;
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(DateFormat('MMMM d').format(DateTime.parse(day)))),
    body:AnimatedBuilder(animation:store,builder:(context,_)=>ListView(padding:EdgeInsets.all(24),children:[
      Text('Your daily notes',style:TextStyle(fontSize:28,fontWeight:FontWeight.w600)),gap,DailyJournal(day:day),
    ])));
}
class _JournalEditor extends StatefulWidget {
  const _JournalEditor({required this.day,required this.kind});
  final String day,kind;
  @override
  State<_JournalEditor> createState()=>_JournalEditorState();
}
class _JournalEditorState extends State<_JournalEditor> {
  late final Json _original=store.data.journal(widget.day);
  late final List<TextEditingController> _fields=List.generate(3,(i){
    final value=widget.kind=='priorities'?jsonMap(_original['priority_$i'])['text']:
      widget.kind=='reflection'?jsonMap(_original['reflection'])[['win','challenge','tomorrow'][i]]:
      i==0?jsonMap(_original['checkin'])['note']:'';
    return TextEditingController(text:value as String? ?? '');
  });
  late int _mood=(jsonMap(_original['checkin'])['mood'] as num? ?? 3).toInt();
  late int _energy=(jsonMap(_original['checkin'])['energy'] as num? ?? 3).toInt();
  bool _busy=false;
  @override
  void dispose(){for(final c in _fields)c.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final priorities=widget.kind=='priorities',check=widget.kind=='checkin';
    return SafeArea(child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(24,8,24,24+MediaQuery.of(context).viewInsets.bottom),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(priorities?'Three things that matter':check?'How are you feeling?':'Close the day gently',style:TextStyle(fontSize:25,fontWeight:FontWeight.w600)),
      SizedBox(height:8),Text(widget.day,style:TextStyle(color:C.label2)),gap,
      if(check)...[
        _rating('Mood',_mood,['Very low','Low','Okay','Good','Great'],(v)=>setState(()=>_mood=v)),gap,
        _rating('Energy',_energy,['Empty','Low','Steady','High','Full'],(v)=>setState(()=>_energy=v)),gap,
        TextField(controller:_fields[0],maxLength:400,maxLines:3,decoration:InputDecoration(labelText:'Anything behind those feelings? (optional)')),
      ]else for(var i=0;i<3;i++)Padding(padding:EdgeInsets.only(bottom:16),child:TextField(controller:_fields[i],maxLength:priorities?100:1000,
        maxLines:priorities?1:3,decoration:InputDecoration(labelText:priorities?'Priority ${i+1}':['What went well?','What got in the way?','What matters tomorrow?'][i]))),
      gap,ActionButton(_busy?'Saving…':'Save',_busy?null:()async{
        setState(()=>_busy=true);
        if(priorities){for(var i=0;i<3;i++){
          final old=jsonMap(_original['priority_$i']),text=_fields[i].text.trim();
          if(text!=(old['text'] as String? ?? ''))await store.saveJournal(widget.day,'priority_$i',{'text':text,'done':false});
        }}else if(check){await store.saveJournal(widget.day,'checkin',{'mood':_mood,'energy':_energy,'note':_fields[0].text.trim()});}
        else{await store.saveJournal(widget.day,'reflection',{'win':_fields[0].text.trim(),'challenge':_fields[1].text.trim(),'tomorrow':_fields[2].text.trim()});}
        if(context.mounted)Navigator.pop(context);
      }),
    ])));
  }
  Widget _rating(String name,int selected,List<String> labels,ValueChanged<int> change)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('$name · ${labels[selected-1]}',style:TextStyle(fontSize:17,fontWeight:FontWeight.w500)),SizedBox(height:10),
    Wrap(spacing:8,children:[for(var i=1;i<=5;i++)ChoiceChip(label:Text('$i'),tooltip:labels[i-1],selected:selected==i,onSelected:(_)=>change(i))]),
  ]);
}
