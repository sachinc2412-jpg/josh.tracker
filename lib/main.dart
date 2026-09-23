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
  runApp( JoshApp());
}

class JoshApp extends StatefulWidget {
  const JoshApp({super.key});
  @override
  State<JoshApp> createState()=>_JoshAppState();
}
class _JoshAppState extends State<JoshApp> with WidgetsBindingObserver {
  @override
  void initState(){super.initState();WidgetsBinding.instance.addObserver(this);}
  @override
  void dispose(){WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override
  void didChangePlatformBrightness(){setState((){});}


  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:store,builder:(context,_){
    final prefs=store.data.prefs,mode=prefs['theme'] as String? ?? 'dark';
    final light=mode=='light'||(mode=='system'&&WidgetsBinding.instance.platformDispatcher.platformBrightness==Brightness.light);
    C.configure(light,prefs['accent'] as String? ?? 'blue');
    final base = light?ThemeData.light(useMaterial3:true):ThemeData.dark(useMaterial3: true);
    SystemChrome.setSystemUIOverlayStyle(light?SystemUiOverlayStyle.dark:SystemUiOverlayStyle.light);
    return MaterialApp(
      title: 'Josh Tracker',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        dividerColor: C.sep,
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: C.card2,
          contentPadding:  EdgeInsets.symmetric(horizontal:16,vertical:16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          labelStyle:  TextStyle(color:C.label2),
        ),
        textSelectionTheme:  TextSelectionThemeData(cursorColor: C.blue),
        pageTransitionsTheme:  PageTransitionsTheme(builders: {
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
      home:  IntroScreen(child: Root()),
    );
  });
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) {
          return  Scaffold(
            body: Center(child: CircularProgressIndicator(color: C.blue)),
          );
        }
        if (store.user == null) return  AuthScreen();
        if (!store.accountReady) {
          return Scaffold(body: SafeArea(child: Center(child: Padding(
            padding:  EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min,children:[
              if (store.syncError == null)  CircularProgressIndicator()
              else  Icon(Icons.cloud_off_outlined,size:36,color:C.label2),
               SizedBox(height:20),
              Text(store.syncError ?? 'Bringing your progress home…',textAlign:TextAlign.center),
              if (store.syncError != null) ...[
                 SizedBox(height:20),ActionButton('Try again',store.retry),
                TextButton(onPressed:store.signOut,child: Text('Sign out')),
              ],
            ]),
          ))));
        }
        if (store.data.prefs['onboarded'] != true) return  OnboardingScreen();
        return  HomeScreen();
      },
    );
  }
}
