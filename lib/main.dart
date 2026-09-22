import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'package:flutter/cupertino.dart';

final store = Store();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );
  await store.init();
  runApp(const JoshApp());
}

class JoshApp extends StatelessWidget {
  const JoshApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Josh Tracker',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        dividerColor: C.sep,
        textSelectionTheme: const TextSelectionThemeData(cursorColor: C.blue),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
        scaffoldBackgroundColor: C.bg,
        colorScheme: base.colorScheme.copyWith(
          surface: C.bg,
          primary: C.blue,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: C.label,
          displayColor: C.label,
        ),
      ),
      home: const IntroScreen(child: Root()),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: C.blue)),
          );
        }
        return store.user == null ? const AuthScreen() : const HomeScreen();
      },
    );
  }
}
