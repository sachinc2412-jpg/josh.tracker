import 'package:flutter/material.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/ui.dart';

final starterHabits=<Json>[
  {'name':'Sleep','kind':'quantity','target':8,'unit':'hours','category':'Rest','reminder':540,'remind':true},
  {'name':'Learn something','kind':'quantity','target':60,'unit':'minutes','category':'Learning','reminder':1020,'remind':true},
  {'name':'Gym','kind':'weekly','target':1,'weeklyTarget':4,'category':'Health','reminder':1080,'remind':true},
  {'name':'Focused work','kind':'quantity','target':90,'unit':'minutes','category':'Work','reminder':660,'remind':true},
  {'name':'Eat well','kind':'check','target':1,'category':'Health','reminder':1140,'remind':true},
];
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState()=>_OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name=TextEditingController(text:store.name);
  final _goal=TextEditingController(text:store.data.goal['label'] as String? ?? 'Build a life you feel good about');
  late final Set<int> _selected=store.habits.isEmpty?{0,1,2}:{};
  int _step=0,_quietStart=1320,_quietEnd=480;
  bool _enable=false,_busy=false;
  @override
  void dispose(){_name.dispose();_goal.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),
    child:ListView(padding:const EdgeInsets.all(28),children:[
      Row(children:[Image.asset('assets/icon-512.png',width:34,height:34),const SizedBox(width:10),const Text('Josh Tracker',style:TextStyle(fontWeight:FontWeight.w600)),const Spacer(),Text('${_step+1} / 3',style:const TextStyle(color:C.label2))]),
      const SizedBox(height:46),
      PageTitle(['A little more you.','Find your rhythm.','On your terms.'][_step],
        ['Small intentions. A space to grow at your own pace.','Choose a starting point. You can shape every habit later.','Gentle nudges when something is left. Silence when you need it.'][_step]),
      if(_step==0)...[
        TextField(controller:_name,maxLength:30,decoration:const InputDecoration(labelText:'What should we call you?')),gap,
        TextField(controller:_goal,maxLength:100,maxLines:2,decoration:const InputDecoration(labelText:'What are you working towards?')),
      ],
      if(_step==1)...[
        if(store.habits.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:18),child:Text('Your ${store.habits.length} existing habits and history are kept. Add anything you want below.',style:const TextStyle(color:C.label2,height:1.5))),
        for(var i=0;i<starterHabits.length;i++)Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(padding:4,child:CheckboxListTile(
          value:_selected.contains(i),onChanged:(v)=>setState((){if(v==true){_selected.add(i);}else{_selected.remove(i);}}),
          title:Text(starterHabits[i]['name'] as String),subtitle:Text(Habit({'id':'preset',...starterHabits[i]}).targetLabel),controlAffinity:ListTileControlAffinity.trailing))),
      ],
      if(_step==2)...[
        Panel(child:Column(children:[
          SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,value:_enable,title:const Text('Enable reminders'),subtitle:const Text('You stay in control'),onChanged:(v)=>setState(()=>_enable=v)),
          _time('Quiet hours begin',_quietStart,(v)=>setState(()=>_quietStart=v)),
          _time('Quiet hours end',_quietEnd,(v)=>setState(()=>_quietEnd=v)),
        ])),gap,
        const Text('Choose each habit’s reminder time in Settings. Notifications check progress saved on this phone. Android may deliver them a little later to save battery.',style:TextStyle(color:C.label2,fontSize:13,height:1.6)),
      ],
      const SizedBox(height:32),ActionButton(_busy?'Setting things up…':_step==2?'Begin your next chapter':'Continue',_busy?null:()async{
        if(_step==0 && (_name.text.trim().isEmpty||_goal.text.trim().isEmpty)){message(context,'Add your name and a goal to continue.');return;}
        if(_step<2){setState(()=>_step++);return;}
        setState(()=>_busy=true);
        var enabled=_enable;
        if(enabled) enabled=await store.reminders.request();
        final selected=_selected.map((i)=>{...starterHabits[i],'weekdays':[1,2,3,4,5,6,7]}).toList();
        await store.completeSetup(_name.text,_goal.text,selected,enabled,_quietStart,_quietEnd);
      }),
      if(_step>0)TextButton(onPressed:_busy?null:()=>setState(()=>_step--),child:const Text('Back')),
    ])))));
  Widget _time(String title,int value,ValueChanged<int> save)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(title),
    trailing:Text(TimeOfDay(hour:value~/60,minute:value%60).format(context)),onTap:()async{
      final result=await showTimePicker(context:context,initialTime:TimeOfDay(hour:value~/60,minute:value%60));
      if(result!=null)save(result.hour*60+result.minute);
    });
}
