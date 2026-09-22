# Validation record

## Executed in this environment

- Parsed all application and test Dart files with a Dart grammar.
- Parsed the Android Kotlin sources with a Kotlin grammar.
- Parsed Android XML resources and manifest.
- Parsed PostgreSQL statements and the PL/pgSQL function body.
- Compiled the actual production ReminderTimes.java class and ran its JVM regression test: **10 checks passed**, including quiet-hour boundaries, snooze crossing midnight, equal endpoints, daytime intervals and DST transitions.
- Checked that original Google sign-in methods and Supabase/Google connection values remain intact.
- Checked archive integrity.

These syntax checks do not replace Dart type analysis, Kotlin/Android compilation, or integration testing.

## Included tests to run on your Flutter machine

`flutter test` includes:

- Original intro completion, rebuild, reduced motion and disposal tests.
- Data migration, fractional quantities, weekly reset, same-weekday comparison, scheduling, historical target snapshots, archive behavior, streaks, edit replay and contextual dashboard copy.
- A compact large-text dashboard/tab rendering test.

## Required device/integration checks

1. Run the SQL upgrade in your development Supabase project; sign in to the same account used in V1. Compare its history and goal.
2. Create one of each habit type; edit a goal and confirm the previous day's target/history stays intact.
3. Turn off internet, enter quantities, fully close/reopen, verify values survive and “Waiting to sync” remains. Reconnect and retry.
4. Edit while a sync is in flight. Verify the final value persists. On two devices, edit different days/habits and confirm both survive; same-field conflicts use last synchronized edit.
5. Sign out with queued edits, use a different account, and confirm there is no data crossover. Return to the first account and sync.
6. Test Google sign-in success, cancellation and email sign-in using the phone's actual signing certificate configuration.
7. Enable notifications; use the test button. Set a habit reminder a few minutes ahead, close the app without force-stopping, and confirm delivery. Inexact alarms may run later.
8. Complete a habit before its scheduled reminder and confirm suppression. Complete a weekly goal and confirm no more prompts that week.
9. Test snooze from the notification and from the dashboard. Test quiet-hour start/end and phone reboot/timezone change.
10. Deny notification permission; tracking must keep working and Settings must explain the permission state.
11. Test narrow display widths, large system font size, the keyboard in habit/setup forms, and reduced motion.
12. Inspect current/previous-week insights around Sunday/Monday. Check CSV/JSON exports and archived history.

## Re-run the standalone Java reminder-policy test

From the project root with a JDK:

```sh
javac -d validation/classes android/app/src/main/java/com/josh/tracker/ReminderTimes.java validation/ReminderTimesTest.java
java -cp validation/classes ReminderTimesTest
```

No live cloud changes, account messages, publishing or store submission were performed by this update.
