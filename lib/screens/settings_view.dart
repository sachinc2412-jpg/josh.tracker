import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/ui.dart';
import 'habit_editor.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    final prefs=store.data.prefs;
    return ListView(padding:const EdgeInsets.fromLTRB(24,24,24,132),children:[
      const PageTitle('Settings','Make room for what matters.'),
      Panel(padding:6,child:Column(children:[
        ListTile(title:const Text('Your name'),subtitle:Text(store.name),trailing:const Icon(Icons.chevron_right),onTap:()=>_text(context,'Your name',store.name,(v)=>store.preferences({'name':v}),30)),
        ListTile(title:const Text('Your bigger goal'),subtitle:Text(store.data.goal['label'] as String),trailing:const Icon(Icons.chevron_right),onTap:()=>_text(context,'Your bigger goal',store.data.goal['label'] as String,(v)=>store.updateGoal({'label':v}),100)),
        ListTile(title:const Text('Target date'),subtitle:Text(store.data.goal['target'] as String),trailing:const Icon(Icons.calendar_today_outlined,size:20),onTap:()async{
          final now=DateTime.now();
          final initial=DateTime.tryParse(store.data.goal['target'] as String)??now;
          final date=await showDatePicker(context:context,initialDate:initial.isBefore(dateOnly(now))?now:initial,
            firstDate:dateOnly(now),lastDate:DateTime(now.year+20));
          if(date!=null)await store.updateGoal({'target':dayKey(date)});
        }),
      ])),gap,
      Row(children:[const Expanded(child:SectionLabel('Your habits')),TextButton(onPressed:()=>editHabit(context),child:const Text('+ Add'))]),
      for(final h in store.habits)Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(padding:4,child:ListTile(
        leading:Icon(categoryIcon(h.category),color:C.label2),title:Text(h.name),subtitle:Text(h.targetLabel),onTap:()=>editHabit(context,habit:h),
        trailing:IconButton(tooltip:'Archive habit',icon:const Icon(Icons.archive_outlined,size:20,color:C.label2),onPressed:()async{
          final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Archive this habit?'),content:const Text('It leaves your daily list. Your earlier progress stays in History and Insights.'),actions:[
            TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Keep habit')),TextButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Archive'))]));
          if(ok==true)await store.archive(h);
        })))),gap,
      const SectionLabel('Gentle reminders'),
      Panel(padding:8,child:Column(children:[
        SwitchListTile.adaptive(title:const Text('Notifications'),subtitle:Text(store.reminders.permitted?'Enabled on this device':'Permission is needed on this device'),value:prefs['reminders']==true,onChanged:(v)async{
          final granted=!v||await store.reminders.request();
          await store.preferences({'reminders':v&&granted});
          if(context.mounted&&v&&!granted)message(context,'Allow Josh Tracker notifications in Android Settings.');
        }),
        _time(context,'Quiet hours begin',prefs['quietStart'] as int? ??1320,(v)=>store.preferences({'quietStart':v})),
        _time(context,'Quiet hours end',prefs['quietEnd'] as int? ??480,(v)=>store.preferences({'quietEnd':v})),
        _time(context,'Daily remaining-habits check',prefs['summaryTime'] as int? ??1200,(v)=>store.preferences({'summaryTime':v})),
        ListTile(title:const Text('Android notification settings'),trailing:const Icon(Icons.open_in_new,size:18),onTap:store.reminders.openSettings),
        ListTile(title:const Text('Send a test notification'),trailing:const Icon(Icons.notifications_none_rounded),onTap:()async{
          if(!await store.reminders.request()){if(context.mounted)message(context,'Notifications are not allowed yet.');return;}
          try{await store.reminders.test();}catch(_){if(context.mounted)message(context,'Could not send the test notification.');}
        }),
      ])),const SizedBox(height:12),
      Text(store.reminders.error??'Habit reminders only appear for unfinished activities. Equal quiet-hour times disable quiet hours. Snooze lasts 30 minutes, or until quiet hours end.',style:const TextStyle(color:C.label2,fontSize:12,height:1.6)),gap,
      const SectionLabel('Your data'),
      Panel(padding:6,child:Column(children:[
        ListTile(title:Text(store.syncLabel),subtitle:Text(store.syncError??'${store.pendingCount} changes waiting'),trailing:TextButton(onPressed:store.retry,child:const Text('Retry'))),
        ListTile(title:const Text('Export progress'),subtitle:const Text('CSV spreadsheet'),trailing:const Icon(Icons.ios_share_rounded,size:20),onTap:()=>_share(context,store.exportCsv(),'csv')),
        ListTile(title:const Text('Export full backup'),subtitle:const Text('JSON file'),trailing:const Icon(Icons.ios_share_rounded,size:20),onTap:()=>_share(context,store.exportJson(),'json')),
      ])),gap,
      Panel(padding:6,child:ListTile(title:Text(store.user?.email??'Your account'),subtitle:const Text('Sign out',style:TextStyle(color:C.red)),onTap:()async{
        final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Sign out?'),content:Text(store.pendingCount>0?'${store.pendingCount} unsynced changes will stay on this phone for this account. Sign in to the same account here to sync them later.':'Your progress will be here when you return.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Stay')),TextButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Sign out'))]));
        if(ok==true){try{await store.signOut();}catch(_){if(context.mounted)message(context,'Could not sign out. Try again.');}}
      })),gap,
      const Text('JOSH TRACKER\nA little better. Every day.',textAlign:TextAlign.center,style:TextStyle(color:C.label3,fontSize:11,height:1.8,letterSpacing:0.5)),
    ]);
  }
  Future<void> _text(BuildContext context,String title,String initial,Future<void> Function(String) save,int max) async {
    final result=await showDialog<String>(context:context,builder:(_)=>_TextDialog(title,initial,max));
    if(result!=null)await save(result);
  }
  Widget _time(BuildContext context,String label,int value,Future<void> Function(int) save)=>ListTile(title:Text(label),trailing:Text(TimeOfDay(hour:value~/60,minute:value%60).format(context),style:const TextStyle(color:C.label2)),onTap:()async{
    final time=await showTimePicker(context:context,initialTime:TimeOfDay(hour:value~/60,minute:value%60));
    if(time!=null)await save(time.hour*60+time.minute);
  });
  Future<void> _share(BuildContext context,String content,String extension)async{
    try{final dir=await getTemporaryDirectory();final file=File('${dir.path}/josh-tracker-${store.todayKey}.$extension');await file.writeAsString(content);await Share.shareXFiles([XFile(file.path)]);}
    catch(_){if(context.mounted)message(context,'Export could not open. Please try again.');}
  }
}
class _TextDialog extends StatefulWidget {
  const _TextDialog(this.title,this.initial,this.max);
  final String title,initial;
  final int max;
  @override
  State<_TextDialog> createState()=>_TextDialogState();
}
class _TextDialogState extends State<_TextDialog>{
  late final _controller=TextEditingController(text:widget.initial);
  @override
  void dispose(){_controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>AlertDialog(title:Text(widget.title),content:TextField(controller:_controller,maxLength:widget.max,autofocus:true),actions:[
    TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
    TextButton(onPressed:(){if(_controller.text.trim().isNotEmpty)Navigator.pop(context,_controller.text.trim());},child:const Text('Save'))]);
}
