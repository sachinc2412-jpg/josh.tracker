# Install Josh Tracker 3

## 1. Keep your current setup and sync first

Before upgrading, open the old app while online so its latest changes reach Supabase. Keep a backup of the original project and optionally export its data. The old version’s unscoped cache cannot safely be assigned to an account, so migration reads the authenticated account’s cloud record. V2 offline edits are account-scoped and remain queued through restarts and sign-out.

Extract this project into a separate folder. Preserve your own signing keystore, key.properties and machine-specific Android setup. Use the same Android package (`com.josh.tracker`) and signing key if installing over your existing app. Do not uninstall first if you have unsynced local changes.

The Supabase URL, public client key and Google OAuth web client ID from your supplied project are retained. No service-role secret is included or required. Keep your existing Android OAuth certificate fingerprints registered; if you change the signing key, update the Android OAuth client to match.

## 2. Apply the cloud upgrade once

1. Open the existing project in the Supabase dashboard.
2. Open **SQL Editor → New query**.
3. Paste all of `supabase/UPGRADE_V3.sql`.
4. Click **Run**.

For an existing V2 installation, this updates its existing sync function to accept journal entries, reviews and rest days. Existing V2 rows, habits and queued edits are preserved. It is safe to run again. For a V1 installation, it creates two account-protected tables and one authenticated RPC function. It does not delete or modify `tracker_state`; the old table remains as a migration source and backup. The new app copies each account’s cloud history on first use. Do not continue editing the old app after migrating: V1 and V2 do not mirror changes between their separate tables.

If the SQL has not been applied, the app shows “Cloud upgrade needed” and keeps edits queued locally. After running SQL, tap **Retry**. The SQL was parsed locally but has not been executed against your Supabase project.

## 3. Run the Flutter project

Open the extracted `josh_tracker_app` folder in VS Code. Select your **Android phone or emulator**, then run:

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

The earlier Cupertino import error is corrected in `lib/main.dart`.

Alternatively, run `powershell -ExecutionPolicy Bypass -File validation/validate.ps1` from the project folder to resolve dependencies, format source, analyze, run widget/model tests and build a debug APK. ExecutionPolicy Bypass applies only to that process; you can instead run the listed commands manually.

For a debug APK:

```powershell
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`.

Release signing still uses your existing `android/key.properties` setup. Build a release APK only after configuring your own signing key:

```powershell
flutter build apk --release
```

## 4. Find the new features

| Feature | Where to use it |
| --- | --- |
| Daily priorities | Today → What matters today. Up to three priorities; check each off separately from habits. |
| Mood & energy | Today → A moment for you. Five-point scales and an optional note. |
| Evening reflection | Today → Evening reflection. What went well, what got in the way, what matters tomorrow. Available all day; evening copy changes after 5 PM. |
| Past daily entries | History → select a date → Your daily journal. Revisit or edit notes and priorities. |
| Personal weekly review | Insights → Personal weekly review. On Sunday a shortcut also appears on Today. Includes habit completion, strongest habit, mood/energy averages, priorities, reflections and a saved intention for next week. Navigate previous weeks with the arrows. |
| Rest days and pauses | Today → Need a little space? or Settings → Personalization → Rest days & pauses. Rest today, select recurring rest weekdays or pause an individual habit for an inclusive date range. Resume early or cancel a future pause. |
| Milestones | Insights → Milestones. Habit-day wins, active-day streaks and logged learning hours; a small in-app message marks newly reached thresholds when logging. |
| Personalization | Settings → Personalization. Dark, light or system theme; Ocean, Sage, Iris or Rose accent; gentle or direct daily voice. |
| Android home-screen widget | See the next section. |

These entries use the same account-scoped offline queue as habits. A full JSON backup includes journals, intentions, rest rules and appearance preferences; the CSV remains a habit-progress export. Mood and energy are personal five-point ratings, not clinical assessments. Review summaries use your recorded data and local rules; there is no AI subscription.

### Add the Android widget

A **new full APK installation is required** for the native widget receiver and resources. Hot reload and Dart-only patches cannot install these native additions. Preserve the same package and signing key when installing over the old app.

1. Install the new build and open it once. Sign in and let it sync.
2. Long-press an empty space on the Android home screen → **Widgets** → **Josh Tracker · Today**.
3. Drag the widget onto the home screen; resize if needed.
4. It shows today's progress and up to three remaining habits. Tap to open the app; a quantity habit opens its logging sheet. Checkbox habits are checked inside the app.

The widget follows the selected theme/accent and uses the local snapshot. It refreshes after local saves and successful sync, and requests periodic Android refreshes every 30 minutes; the launcher/OS may delay periodic updates. It does not independently fetch Supabase data. Changes from another device appear after this app next syncs. Sign-out clears the displayed account. Mood, energy and reflection notes are never displayed on the widget.

### Rest and milestone rules

- Rest today is an explicit date override, including overriding a recurring rest day when switched off.
- Recurring rest changes start today. Dated rule versions retain previous weeks' schedules.
- Pauses include their start and end dates. Resuming today keeps the earlier pause history.
- Rest/paused habits disappear from the due list and do not send habit reminders, including snoozes. Their scheduled opportunities are excluded from completion rates.
- A weekly goal is capped at the number of eligible days in that week. For example, a four-day goal with only two available days becomes two for that week; it returns to its usual target afterward.
- A planned rest day preserves an existing streak without incrementing it. When every habit otherwise due is paused, the same protection applies. Pausing one habit does not excuse an unfinished day for other scheduled habits.
- Existing progress entries are kept even if today is later marked as rest; History continues to show logged amounts. Rest-day logs do not contribute to scheduled completion rates.
- Milestones are calculated from current logs, including archived habits. Correcting or undoing progress can remove a milestone. Learning hours use actual recorded minutes/hours, not just whether the daily target was reached.
- Update all devices to V3 to apply rest rules consistently. V2 preserves unfamiliar fields during sync but does not understand the new scheduling rules.

## 5. Personalize it for Joshua

On first sign-in, choose a display name, bigger goal and optional starter habits. If existing habits are present, they are kept and no starters are preselected. Change an existing checkbox to a quantity/weekly habit in Settings rather than adding a duplicate.

Examples:

- Sleep: daily amount, target 8, unit hours. Enter the actual total for the day.
- Learn: daily amount, target 60, unit minutes.
- Gym: days per week, target 4. One check-in counts as one day.
- Eat well: daily checkbox.

Habit target/schedule changes retain dated definitions for earlier dates; progress entries also retain the target used when they were logged. Archiving removes future daily entries but preserves earlier records and exports.

## 6. Enable reminders

Enable notifications during onboarding or in Settings and accept the Android permission request. For each habit, enable its reminder and choose its time. The daily remaining-habits summary defaults to 8 PM; quiet hours default to 10 PM–8 AM. All times follow the phone’s local timezone.

- Notifications recheck locally saved completion at delivery time.
- Completed daily habits are quiet; weekly goals stop prompting once their target is reached.
- Habit reminders scheduled inside quiet hours are skipped. Choose a reminder time outside quiet hours.
- Snooze schedules 30 minutes later; if that lands in quiet hours, it moves to the end of quiet hours.
- Notification taps open the dashboard; quantity-habit taps open its logging sheet.
- Notification actions include **Snooze 30 min**.
- Android may delay these inexact alarms for battery management. No exact-alarm access is requested.
- Restarting the phone, changing its timezone/time or updating the APK restores/recalculates reminders.
- Android force-stop blocks reminders until the app is opened again. OEM battery restrictions may also affect delivery.
- Progress changed on another device is reflected after this phone next syncs. There is no server background push in this version.
- Disable notifications in Settings to cancel reminders. Sign-out cancels reminders and clears this account’s reminder snapshot.

## Sync behavior

Each edit is applied immediately and written to an account-specific persistent queue before network sync. Sync sends independent operations under a server row lock; operation IDs are deduplicated. Different habits/days merge without overwriting unrelated changes. Edits to the **same habit/day total, same journal field, same weekly note, or same setting** use the last operation accepted by the server. This is a deliberate conflict rule, not collaborative arithmetic merging.

A timed-out request can safely retry. New edits made during an upload stay queued and are reapplied over the server response. The queue is processed in batches of 250, retried every 30 seconds while foregrounded and on app resume. Saving failures on the device are distinguished from waiting for cloud sync.

No background network worker runs when the app is closed. Local reminders still work; queued changes sync when the app opens again.

## Insights definitions

- Dashboard ring includes partial quantity progress, capped at each target.
- A “win” is a completed habit/day, not every incremental quantity log.
- Weekly habits count distinct completed days toward their weekly target (Monday–Sunday).
- Completion rates count scheduled daily opportunities up to the current weekday and the full target for weekly habits. Comparisons use the same elapsed weekdays of last week.
- Current/best streaks count active days with at least one completed habit, skipping planned rest without adding a day. An unfinished current day does not break yesterday’s streak.
- Quotes are original, rule-based copy chosen from local time and incomplete categories. No AI API or ongoing quote-generation fee.

## Validation limits

Flutter/Dart SDK and an Android emulator are not available in the editing environment. The source has passed Dart/Kotlin syntax parsing, Android XML parsing, SQL and PL/pgSQL parsing, and 10 production Java reminder-policy tests. Flutter model/widget tests, including V3 journal/rest/milestone and screen regressions, are included but have NOT been executed here. The widget has not been tested in an Android launcher. No APK was compiled, and no Google/Supabase live-account test was performed. Run the commands and device checks in VALIDATION.md before sharing a release.
