import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/ui.dart';

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
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: C.card2,
          contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          labelStyle: const TextStyle(color:C.label2),
        ),
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
        if (store.user == null) return const AuthScreen();
        if (!store.accountReady) {
          return Scaffold(body: SafeArea(child: Center(child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min,children:[
              if (store.syncError == null) const CircularProgressIndicator()
              else const Icon(Icons.cloud_off_outlined,size:36,color:C.label2),
              const SizedBox(height:20),
              Text(store.syncError ?? 'Bringing your progress home…',textAlign:TextAlign.center),
              if (store.syncError != null) ...[
                const SizedBox(height:20),ActionButton('Try again',store.retry),
                TextButton(onPressed:store.signOut,child:const Text('Sign out')),
              ],
            ]),
          ))));
        }
        if (store.data.prefs['onboarded'] != true) return const OnboardingScreen();
        return const HomeScreen();
      },
    );
  }
}
