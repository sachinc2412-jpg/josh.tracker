import 'package:flutter/material.dart';

/// One launch animation per process. Does not push a route or interrupt OAuth.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.child});
  final Widget child;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration:  Duration(milliseconds: 2200),
  );
  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _finished = true;
    } else {
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _finished = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end) => Curves.easeInOutCubic.transform(
        ((_controller.value - start) / (end - start)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final reveal = _phase(0.04, 0.40);
          final title = _phase(0.35, 0.60);
          final exit = _phase(0.80, 1.0);
          return Opacity(
            opacity: 1 - exit,
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -24 * exit),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: reveal,
                      child: Transform.scale(
                        scale: 0.55 + 0.45 * reveal,
                        child: Image.asset('assets/icon-512.png',
                            width: 104, height: 104),
                      ),
                    ),
                     SizedBox(height: 22),
                    Opacity(
                      opacity: title,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - title)),
                        child:  Column(children: [
                          Text('Josh Tracker',
                              style: TextStyle(color:Colors.white,fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8)),
                          SizedBox(height: 9),
                          Text('A little better. Every day.',
                              style: TextStyle(fontSize: 13,
                                  color: Color(0xFF9599A6))),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
