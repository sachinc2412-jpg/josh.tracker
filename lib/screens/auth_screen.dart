import 'package:flutter/material.dart';
import '../config.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1200));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _showEmail = false;
  bool _signup = false;
  bool _busy = false;
  String? _msg;
  bool _msgErr = true;

  void _set(String? m, {bool err = true}) =>
      setState(() { _msg = m; _msgErr = err; });

  Future<void> _google() async {
    setState(() => _busy = true);
    final err = await store.signInGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) _set(err);
  }

  Future<void> _emailSubmit() async {
    final e = _email.text.trim(), p = _pass.text;
    if (e.isEmpty || p.isEmpty) return _set('Enter an email and password.');
    setState(() => _busy = true);
    final err = _signup
        ? await store.signUpEmail(e, p)
        : await store.signInEmail(e, p);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) _set(err, err: err.contains('created') ? false : true);
    if (err != null && err.contains('created')) setState(() => _signup = false);
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = ThemeData.dark(useMaterial3: true);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight:
                  (constraints.maxHeight - 36).clamp(0.0, double.infinity)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _entrance,
                            curve: const Interval(0, 0.65, curve: Curves.easeOut)),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/icon-512.png', width: 38, height: 38),
                              const SizedBox(width: 10),
                              const Text('Josh Tracker', style: TextStyle(
                                  color: Colors.white, fontSize: 19,
                                  fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                            ]),
                          const SizedBox(height: 24),
                          const Text('Every day. A little better.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 34,
                              fontWeight: FontWeight.w600, letterSpacing: -1.1)),
                          const SizedBox(height: 10),
                          const Text('Your habits. Your pace. Your progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF969AA7),
                              fontSize: 14, height: 1.6)),
                        ]),
                      ),
                      const SizedBox(height: 36),
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _entrance,
                            curve: const Interval(0.2, 1, curve: Curves.easeOut)),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.22),
                            end: Offset.zero).animate(CurvedAnimation(
                              parent: _entrance,
                              curve: const Interval(0.15, 1, curve: Curves.easeOutCubic))),
                          child: Theme(
                            data: panelTheme.copyWith(
                              colorScheme: panelTheme.colorScheme.copyWith(primary: C.blue)),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: C.card,
                                border: Border.all(color: const Color(0x18FFFFFF)),
                                borderRadius: BorderRadius.circular(30)),
                              child: DefaultTextStyle(
                                style: const TextStyle(color: C.label, fontSize: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      Expanded(child: _modeTab('Sign in', false)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _modeTab('Sign up', true)),
                                    ]),
                                    const SizedBox(height: 24),
                                    Text(_signup ? 'Make it a habit.' : 'Welcome back.',
                                      style: const TextStyle(fontSize: 24,
                                        fontWeight: FontWeight.w700, letterSpacing: -0.7)),
                                    const SizedBox(height: 7),
                                    Text(_signup ? 'Small habits. Meaningful progress.'
                                        : 'Your goals are right where you left them.',
                                      style: const TextStyle(color: C.label2,
                                        height: 1.5, fontSize: 13)),
                                    const SizedBox(height: 24),
                                    _googleBtn(),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _busy ? null : () =>
                                          setState(() => _showEmail = !_showEmail),
                                      child: Text(_showEmail ? 'Hide email form' : 'Continue with email',
                                        style: const TextStyle(color: C.label2))),
                                    if (_showEmail) ...[
                                      const SizedBox(height: 8),
                                      _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                                      const SizedBox(height: 12),
                                      _field(_pass, 'Password', obscure: true),
                                      const SizedBox(height: 16),
                                      _primaryBtn(_signup ? 'Create account' : 'Sign in', _emailSubmit),
                                    ],
                                    if (_busy) const Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Center(child: SizedBox(width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2)))),
                                    if (_msg != null) Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Text(_msg!, textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13,
                                          color: _msgErr ? C.red
                                              : C.green))),
                                    const SizedBox(height: 20),
                                    const Text('Your progress, synced across devices.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: C.label2, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _modeTab(String label, bool signup) {
    final selected = _signup == signup;
    return TextButton(
      onPressed: _busy ? null : () => setState(() {
        _signup = signup;
        _msg = null;
        if (signup) _showEmail = true;
      }),
      style: TextButton.styleFrom(
        backgroundColor: selected ? C.card2 : Colors.transparent,
        foregroundColor: selected ? C.label : C.label2,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _googleBtn() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : _google,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F5F7),
          foregroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const _GoogleG(),
        label: const Text('Continue with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: C.label, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.label2),
        filled: true,
        fillColor: C.card2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _busy ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;
    final p = Paint()..style = PaintingStyle.fill;

    // Blue
    p.color = const Color(0xFF4285F4);
    canvas.drawPath(_scaled(_blue, s), p);
    // Green
    p.color = const Color(0xFF34A853);
    canvas.drawPath(_scaled(_green, s), p);
    // Yellow
    p.color = const Color(0xFFFBBC05);
    canvas.drawPath(_scaled(_yellow, s), p);
    // Red
    p.color = const Color(0xFFEA4335);
    canvas.drawPath(_scaled(_red, s), p);
  }

  Path _scaled(Path Function() build, double s) {
    final m = Matrix4.identity()..scale(s, s);
    return build().transform(m.storage);
  }

  static Path _blue() => Path()
    ..moveTo(47.53, 24.55)
    ..cubicTo(47.53, 22.98, 47.38, 21.46, 47.15, 20.0)
    ..lineTo(24.0, 20.0)
    ..lineTo(24.0, 29.02)
    ..lineTo(37.19, 29.02)
    ..cubicTo(36.61, 32.0, 34.9, 34.52, 32.36, 36.22)
    ..lineTo(40.09, 42.22)
    ..cubicTo(44.6, 38.04, 47.53, 31.86, 47.53, 24.55)
    ..close();

  static Path _green() => Path()
    ..moveTo(24.0, 48.0)
    ..cubicTo(30.6, 48.0, 36.14, 45.82, 40.19, 42.09)
    ..lineTo(32.36, 36.22)
    ..cubicTo(30.21, 37.67, 27.43, 38.52, 24.0, 38.52)
    ..cubicTo(17.74, 38.52, 12.43, 34.3, 10.53, 28.61)
    ..lineTo(2.55, 34.79)
    ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
    ..close();

  static Path _yellow() => Path()
    ..moveTo(10.53, 28.59)
    ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
    ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
    ..lineTo(2.55, 13.22)
    ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
    ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.55, 34.79)
    ..lineTo(10.53, 28.59)
    ..close();

  static Path _red() => Path()
    ..moveTo(24.0, 9.5)
    ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
    ..lineTo(40.06, 6.25)
    ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
    ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.55, 13.22)
    ..lineTo(10.53, 19.41)
    ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
    ..close();

  @override
  bool shouldRepaint(_) => false;
}