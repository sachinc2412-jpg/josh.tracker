import 'package:flutter/material.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/ui.dart';

Future<void> editHabit(BuildContext context,{Habit? habit}) => showModalBottomSheet<void>(
  context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:C.card,
  builder:(_)=>HabitEditor(habit:habit));

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key,this.habit});
  final Habit? habit;
  @override
  State<HabitEditor> createState()=>_HabitEditorState();
}
class _HabitEditorState extends State<HabitEditor> {
  final _form=GlobalKey<FormState>();
  late final _name=TextEditingController(text:widget.habit?.name??'');
  late final _target=TextEditingController(text:number(widget.habit?.target??1));
  late String _kind=widget.habit?.kind??'check';
  late String _category=widget.habit?.category??'Personal';
  late String _unit=widget.habit?.unit??'minutes';
  late int _weekly=widget.habit?.weeklyTarget??4;
  late Set<int> _days=(widget.habit?.weekdays??[1,2,3,4,5,6,7]).toSet();
  late bool _remind=widget.habit?.remind??false;
  late int _time=widget.habit?.reminder??1080;
  bool _saving=false;
  @override
  void dispose(){_name.dispose();_target.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>SafeArea(child:SingleChildScrollView(
    padding:EdgeInsets.fromLTRB(24,8,24,24+MediaQuery.of(context).viewInsets.bottom),
    child:Form(key:_form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(widget.habit==null?'A new intention':'Shape your habit',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w600,letterSpacing:-0.7)),gap,
      TextFormField(controller:_name,maxLength:60,decoration:const InputDecoration(labelText:'Habit name'),validator:(v)=>v==null||v.trim().isEmpty?'Give your habit a name.':null),
      gap,DropdownButtonFormField<String>(value:_kind,decoration:const InputDecoration(labelText:'How to track'),items:const[
        DropdownMenuItem(value:'check',child:Text('Daily checkbox')),
        DropdownMenuItem(value:'quantity',child:Text('Daily amount')),
        DropdownMenuItem(value:'weekly',child:Text('Days per week')),
      ],onChanged:(v)=>setState(()=>_kind=v!)),gap,
      DropdownButtonFormField<String>(value:_category,decoration:const InputDecoration(labelText:'Category'),items:[for(final c in ['Personal','Health','Learning','Work','Rest'])DropdownMenuItem(value:c,child:Text(c))],onChanged:(v)=>setState(()=>_category=v!)),gap,
      if(_kind=='quantity')...[
        TextFormField(controller:_target,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Daily target'),validator:(v){
          final n=double.tryParse(v??'');return n==null||!n.isFinite||n<=0||n>1000000?'Use a target above zero, up to 1,000,000.':null;
        }),gap,
        DropdownButtonFormField<String>(value:['minutes','hours','pages','glasses','steps','times'].contains(_unit)?_unit:'times',decoration:const InputDecoration(labelText:'Unit'),
          items:[for(final u in ['minutes','hours','pages','glasses','steps','times'])DropdownMenuItem(value:u,child:Text(u))],onChanged:(v)=>setState(()=>_unit=v!)),gap,
      ],
      if(_kind=='weekly')...[
        Text('Complete on $_weekly days each week',style:const TextStyle(color:C.label2)),
        Slider(value:_weekly.toDouble(),min:1,max:7,divisions:6,label:'$_weekly days',onChanged:(v)=>setState(()=>_weekly=v.round())),
        const Text('One check-in counts as one day. The week starts Monday.',style:TextStyle(color:C.label2,fontSize:12)),gap,
      ]else...[
        const Text('Scheduled days',style:TextStyle(color:C.label2)),const SizedBox(height:8),
        Wrap(spacing:6,children:[for(var i=1;i<=7;i++)FilterChip(label:Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i-1]),selected:_days.contains(i),onSelected:(on)=>setState((){if(on){_days.add(i);}else{_days.remove(i);}}))]),gap,
      ],
      SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Habit reminder'),subtitle:const Text('Only while this habit is unfinished'),value:_remind,onChanged:(v)=>setState(()=>_remind=v)),
      if(_remind)ListTile(contentPadding:EdgeInsets.zero,title:const Text('Remind me at'),trailing:Text(_formatTime(context,_time)),onTap:()async{
        final t=await showTimePicker(context:context,initialTime:TimeOfDay(hour:_time~/60,minute:_time%60));
        if(t!=null)setState(()=>_time=t.hour*60+t.minute);
      }),
      if(_remind && store.data.prefs['reminders']!=true)const Text('Also enable notifications in Settings to receive this reminder.',style:TextStyle(color:C.orange,fontSize:12)),gap,
      ActionButton(_saving?'Saving…':'Save habit',_saving?null:()async{
        if(!_form.currentState!.validate())return;
        if(_kind!='weekly'&&_days.isEmpty){message(context,'Choose at least one day.');return;}
        if(widget.habit==null&&store.habits.length>=30){message(context,'Keep your rhythm focused: up to 30 active habits.');return;}
        setState(()=>_saving=true);
        await store.saveHabit({'name':_name.text.trim(),'emoji':widget.habit?.emoji??'✦','kind':_kind,'category':_category,
          'target':_kind=='quantity'?double.parse(_target.text):1,'unit':_unit,'weeklyTarget':_weekly,
          'weekdays':_days.toList()..sort(),'reminder':_time,'remind':_remind},existing:widget.habit);
        if(context.mounted)Navigator.pop(context);
      }),
    ]))));
}
String _formatTime(BuildContext context,int minutes)=>TimeOfDay(hour:minutes~/60,minute:minutes%60).format(context);
