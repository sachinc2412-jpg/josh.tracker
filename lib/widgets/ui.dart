import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../main.dart';
import '../models.dart';

const gap = SizedBox(height:20);
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(color:C.card,borderRadius:BorderRadius.circular(26),
      border:Border.all(color:const Color(0x0FFFFFFF))),
    child:child,
  );
}
class PageTitle extends StatelessWidget {
  const PageTitle(this.title,this.subtitle,{super.key});
  final String title,subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.only(bottom:24),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:34,fontWeight:FontWeight.w700,letterSpacing:-1.2)),
      const SizedBox(height:7),Text(subtitle,style:const TextStyle(color:C.label2,fontSize:14,height:1.5)),
    ]),
  );
}
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label,{super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(padding:const EdgeInsets.fromLTRB(2,8,2,12),
    child:Text(label,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w600,letterSpacing:-0.4)));
}
class ActionButton extends StatelessWidget {
  const ActionButton(this.label,this.onPressed,{super.key,this.secondary=false});
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  @override
  Widget build(BuildContext context) => SizedBox(width:double.infinity,
    child:FilledButton(onPressed:onPressed,style:FilledButton.styleFrom(
      minimumSize:const Size(48,52),backgroundColor:secondary?C.card2:C.label,
      foregroundColor:secondary?C.label:Colors.black,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
      child:Text(label,style:const TextStyle(fontWeight:FontWeight.w600))));
}
void message(BuildContext context,String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text),behavior:SnackBarBehavior.floating));
}
class ProgressRing extends StatelessWidget {
  const ProgressRing(this.value,{super.key,this.size=176});
  final double value,size;
  @override
  Widget build(BuildContext context) => Semantics(label:'Today progress ${(value*100).round()} percent',
    child:TweenAnimationBuilder<double>(tween:Tween(begin:0,end:value),
      duration:MediaQuery.of(context).disableAnimations?Duration.zero:const Duration(milliseconds:650),
      curve:Curves.easeOutCubic,builder:(context,v,_)=>SizedBox(width:size,height:size,
        child:CustomPaint(painter:_Ring(v),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text('${(v*100).round()}%',style:const TextStyle(fontSize:38,fontWeight:FontWeight.w600,letterSpacing:-1.8)),
          const SizedBox(height:3),const Text('OF TODAY',style:TextStyle(color:C.label2,fontSize:10,letterSpacing:1.5)),
        ]))))));
}
class _Ring extends CustomPainter {
  const _Ring(this.value);
  final double value;
  @override
  void paint(Canvas canvas,Size size) {
    final rect = Rect.fromCircle(center:size.center(Offset.zero),radius:size.width/2-12);
    final p = Paint()..style=PaintingStyle.stroke..strokeWidth=8..strokeCap=StrokeCap.round;
    canvas.drawArc(rect,0,math.pi*2,false,p..color=C.card2);
    if(value>0) canvas.drawArc(rect,-math.pi/2,math.pi*2*value.clamp(0,1),false,p..color=value>=1?C.green:C.blue);
  }
  @override
  bool shouldRepaint(_Ring old) => old.value!=value;
}
IconData categoryIcon(String category) => switch(category) {
  'Health'=>Icons.favorite_border_rounded, 'Learning'=>Icons.auto_stories_outlined,
  'Work'=>Icons.trending_up_rounded, 'Rest'=>Icons.nights_stay_outlined,
  _=>Icons.check_circle_outline_rounded,
};

Future<void> logHabit(BuildContext context,Habit h) async {
  final before = store.data.remaining(store.now).length;
  if(h.kind!='quantity') {
    HapticFeedback.selectionClick();
    await store.toggle(h.id);
    if(context.mounted && before>0 && store.data.remaining(store.now).isEmpty) {
      message(context,'All done. A little better than yesterday.');
    }
    return;
  }
  final value = await showModalBottomSheet<double>(context:context,isScrollControlled:true,
    backgroundColor:C.card,showDragHandle:true,
    builder:(_)=>_QuantitySheet(h));
  if(value==null) return;
  HapticFeedback.selectionClick();
  await store.setValue(h,value);
  if(context.mounted && before>0 && store.data.remaining(store.now).isEmpty) {
    message(context,'All done. Take a moment to enjoy it.');
  }
}
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet(this.habit);
  final Habit habit;
  @override
  State<_QuantitySheet> createState()=>_QuantitySheetState();
}
class _QuantitySheetState extends State<_QuantitySheet> {
  late final _text = TextEditingController(text:number(store.data.value(widget.habit.id,store.todayKey)));
  String? _error;
  @override
  void dispose(){_text.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final h=widget.habit;
    final step=h.unit=='hours'?0.5:h.unit=='minutes'?15.0:1.0;
    return SafeArea(child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(24,8,24,24+MediaQuery.of(context).viewInsets.bottom),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(h.name,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w600)),
        const SizedBox(height:8),Text('Today’s total · goal ${number(h.target)} ${h.unit}',style:const TextStyle(color:C.label2)),gap,
        TextField(controller:_text,autofocus:true,keyboardType:const TextInputType.numberWithOptions(decimal:true),
          decoration:InputDecoration(labelText:h.unit,errorText:_error)),gap,
        Wrap(spacing:10,children:[
          for(final delta in [-step,step]) OutlinedButton(onPressed:(){
            final v=double.tryParse(_text.text)??0;
            _text.text=number((v+delta).clamp(0,1000000));
          },child:Text('${delta>0?'+':''}${number(delta)}')),
          TextButton(onPressed:()=>_text.text=number(h.target),child:const Text('Reach goal')),
        ]),gap,
        ActionButton('Save progress',(){
          final v=double.tryParse(_text.text);
          if(v==null || !v.isFinite || v<0 || v>1000000){setState(()=>_error='Enter a number from 0 to 1,000,000.');return;}
          Navigator.pop(context,v);
        }),
      ])));
  }
}
