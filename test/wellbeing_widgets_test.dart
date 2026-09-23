import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/config.dart';
import 'package:tracker/main.dart';
import 'package:tracker/models.dart';
import 'package:tracker/screens/daily_journal.dart';
import 'package:tracker/screens/personalization.dart';
import 'package:tracker/screens/weekly_review.dart';

void main(){
  testWidgets('journal, reviews, milestones and personalization render in light mode with large text',(tester)async{
    tester.view.physicalSize=const Size(360,800);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(()=>C.configure(false,'blue'));
    store.now=DateTime(2026,9,27,20);store.data=TrackerData.empty(store.now);
    store.data.apply({'type':'journal','day':'2026-09-27','key':'checkin','value':{'mood':4,'energy':3}});
    C.configure(true,'violet');
    for(final screen in <Widget>[JournalDayScreen('2026-09-27'),const WeeklyReviewScreen(),const MilestonesScreen(),const PersonalizationScreen(),const RestScreen()]){
      await tester.pumpWidget(MaterialApp(theme:ThemeData.light(useMaterial3:true),home:MediaQuery(data:const MediaQueryData(size:Size(360,800),textScaler:TextScaler.linear(1.5)),child:screen)));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
