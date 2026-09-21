import 'package:flutter/material.dart';
import '../config.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/icon-512.png',
                      width: 68, height: 68, fit: BoxFit.cover),
                ),
                const SizedBox(height: 22),
                const Text('Josh Tracker',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text('Track the sprint. Sync everywhere.',
                    style: TextStyle(fontSize: 15, color: C.label2)),
                const SizedBox(height: 28),
                _googleBtn(),
                if (_showEmail) ...[
                  const SizedBox(height: 20),
                  _divider(),
                  const SizedBox(height: 14),
                  _field(_email, 'Email',
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_pass, 'Password', obscure: true),
                  const SizedBox(height: 12),
                  _primaryBtn(_signup ? 'Create account' : 'Sign in', _emailSubmit),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _signup = !_signup),
                      child: Text(
                        _signup ? 'Have an account? Sign in' : 'New here? Create account',
                        style: const TextStyle(color: C.blue),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showEmail = !_showEmail),
                    child: Text(_showEmail ? 'Hide email sign-in' : 'Use email instead',
                        style: const TextStyle(color: C.label2)),
                  ),
                ),
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_msg!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: _msgErr ? C.red : C.green)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleBtn() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : _google,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
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

  Widget _divider() => Row(children: const [
        Expanded(child: Divider(color: C.sep, height: 1)),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: C.label3, fontSize: 13))),
        Expanded(child: Divider(color: C.sep, height: 1)),
      ]);

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: C.label, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.label3),
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
    // Simple multicolour G mark.
    return const SizedBox(
      width: 18,
      height: 18,
      child: Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
    );
  }
}
