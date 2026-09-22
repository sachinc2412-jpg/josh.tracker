import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/main.dart';
import 'package:tracker/models.dart';
import 'package:tracker/screens/home_screen.dart';

void main() {
  testWidgets('compact dashboard and tabs render with large text', (tester) async {
    tester.view.physicalSize=const Size(360,780);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    store.now=DateTime(2026,9,22,14);
    store.data=TrackerData.empty(store.now);
    store.data.habitMap['learn']={'id':'learn','name':'Learning','kind':'quantity','target':60,'unit':'minutes','category':'Learning','created':'2026-09-01'};
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(useMaterial3:true),
      home:MediaQuery(data:const MediaQueryData(size:Size(360,780),textScaler:TextScaler.linear(1.3)),child:HomeScreen())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Good afternoon'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('THIS WEEK SO FAR'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Your name'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
