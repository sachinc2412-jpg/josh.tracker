import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../config.dart';
import '../widgets/ui.dart';

class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Make it yours')),body:AnimatedBuilder(animation:store,builder:(context,_){
    final p=store.data.prefs;
    return ListView(padding:EdgeInsets.all(24),children:[
      PageTitle('Your own rhythm.','A few thoughtful choices, just for you.'),
      SectionLabel('Appearance'),
      Panel(child:Wrap(spacing:8,runSpacing:8,children:[for(final mode in ['system','light','dark'])ChoiceChip(label:Text({'system':'System','light':'Light','dark':'Dark'}[mode]!),selected:(p['theme']??'dark')==mode,onSelected:(_)=>store.preferences({'theme':mode}))])),gap,
      SectionLabel('Accent'),
      Panel(child:Wrap(spacing:8,runSpacing:8,children:[for(final entry in {'blue':'Ocean','teal':'Sage','violet':'Iris','rose':'Rose'}.entries)ChoiceChip(label:Text(entry.value),selected:(p['accent']??'blue')==entry.key,onSelected:(_)=>store.preferences({'accent':entry.key}))])),gap,
      SectionLabel('Your daily voice'),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Wrap(spacing:8,children:[for(final tone in ['gentle','direct'])ChoiceChip(label:Text(tone=='gentle'?'Gentle':'Direct'),selected:(p['tone']??'gentle')==tone,onSelected:(_)=>store.preferences({'tone':tone}))]),
        SizedBox(height:12),Text(p['tone']=='direct'?'3 habits left. Pick the next action and begin.':'One small step, at your own pace.',style:TextStyle(color:C.label2)),
      ])),gap,
      Panel(child:ListTile(contentPadding:EdgeInsets.zero,leading:Icon(Icons.spa_outlined,color:C.blue),title:Text('Rest days & pauses'),subtitle:Text('Build recovery into your week'),trailing:Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>RestScreen())))),gap,
      Text('Your choices sync with your account. System appearance follows this device.',style:TextStyle(color:C.label2,height:1.5)),
    ]);
  }));
}

class RestScreen extends StatelessWidget {
  const RestScreen({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Rest days & pauses')),body:AnimatedBuilder(animation:store,builder:(context,_){
    final data=store.data,weekdays=List<int>.from(data.prefs['restWeekdays'] as List? ?? []);
    return ListView(padding:EdgeInsets.all(24),children:[
      PageTitle('Room to recover.','Protect your rhythm when life needs space.'),
      Panel(child:SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:Text('Rest today'),subtitle:Text('No habits due or habit reminders today'),value:data.rest(store.now),onChanged:(v)=>store.restDay(store.todayKey,v))),gap,
      SectionLabel('Recurring rest days'),
      Panel(child:Wrap(spacing:6,runSpacing:8,children:[for(var i=1;i<=7;i++)FilterChip(label:Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i-1]),selected:weekdays.contains(i),onSelected:(v){
        final next=[...weekdays];if(v){next.add(i);}else{next.remove(i);}final versions=[...(data.prefs['restVersions'] as List? ?? []).where((v)=>v['from']!=store.todayKey),{'from':store.todayKey,'days':next}];store.preferences({'restWeekdays':next,'restFrom':store.todayKey,'restVersions':versions});
      })])),gap,
      Text('Rest days are excluded from completion rates. They preserve an existing streak without adding a completed day. Weekly targets are capped at available days. Recurring changes apply from today.',style:TextStyle(color:C.label2,height:1.6)),gap,
      SectionLabel('Pause an individual habit'),
      for(final h in data.habits)Padding(padding:EdgeInsets.only(bottom:12),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(h.name,style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
        for(final p in (h.data['pauses'] as List? ?? []).where((p)=>(p['end'] as String).compareTo(store.todayKey)>=0))ListTile(contentPadding:EdgeInsets.zero,
          title:Text('${p['start']} – ${p['end']}',style:TextStyle(fontSize:13)),subtitle:Text(p['reason'] as String? ?? 'A little space'),
          trailing:TextButton(child:Text((p['start'] as String).compareTo(store.todayKey)>0?'Cancel':'Resume'),onPressed:()async{
            final list=<dynamic>[];
            for(final old in (h.data['pauses'] as List? ?? [])){
              if(old==p){if((p['start'] as String).compareTo(store.todayKey)<0)list.add({...jsonMap(p),'end':dayKey(shiftDay(store.now,-1))});}
              else{list.add(old);}
            }
            await store.edit('habit',{...h.data,'pauses':list},key:h.id);
          })),
        TextButton.icon(icon:Icon(Icons.pause_circle_outline),label:Text('Plan a pause'),onPressed:()async{
          final range=await showDateRangePicker(context:context,firstDate:dateOnly(store.now),lastDate:DateTime(store.now.year+5),helpText:'Choose your pause dates');
          if(range!=null)await store.pauseHabit(h,dayKey(range.start),dayKey(range.end),'Planned break');
        }),
      ]))),
    ]);
  }));
}
