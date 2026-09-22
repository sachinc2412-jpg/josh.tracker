import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/screens/intro_screen.dart';

void main() {
  testWidgets('reveals child after intro, without replaying on rebuild', (tester) async {
    Widget app(String label) => MaterialApp(
      home: IntroScreen(child: Scaffold(body: Text(label))),
    );
    await tester.pumpWidget(app('Login'));
    expect(find.text('Login'), findsNothing);
    expect(find.text('Josh Tracker'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    await tester.pumpWidget(app('Dashboard'));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Josh Tracker'), findsNothing);
  });

  testWidgets('skips intro when animations are disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: IntroScreen(child: Text('Login')),
      ),
    ));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Josh Tracker'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can be removed while animating', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IntroScreen(child: Text('Login')),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
