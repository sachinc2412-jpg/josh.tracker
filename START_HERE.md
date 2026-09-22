# Install Josh Tracker 2

## 1. Keep your current setup and sync first

Before upgrading, open the old app while online so its latest changes reach Supabase. Keep a backup of the original project and optionally export its data. The old version’s unscoped cache cannot safely be assigned to an account, so migration reads the authenticated account’s cloud record. V2 offline edits are account-scoped and remain queued through restarts and sign-out.

Extract this project into a separate folder. Preserve your own signing keystore, key.properties and machine-specific Android setup. Use the same Android package (`com.josh.tracker`) and signing key if installing over your existing app. Do not uninstall first if you have unsynced local changes.

The Supabase URL, public client key and Google OAuth web client ID from your supplied project are retained. No service-role secret is included or required. Keep your existing Android OAuth certificate fingerprints registered; if you change the signing key, update the Android OAuth client to match.

## 2. Apply the cloud upgrade once

1. Open the existing project in the Supabase dashboard.
2. Open **SQL Editor → New query**.
3. Paste all of `supabase/UPGRADE_V2.sql`.
4. Click **Run**.

This creates two account-protected tables and one authenticated RPC function. It does not delete or modify `tracker_state`; the old table remains as a migration source and backup. The new app copies each account’s cloud history on first use. Do not continue editing the old app after migrating: V1 and V2 do not mirror changes between their separate tables.

If the SQL has not been applied, V2 shows “Cloud upgrade needed” and keeps edits queued locally. After running SQL, tap **Retry**. The SQL was parsed locally but has not been executed against your Supabase project.

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

## 4. Personalize it for Joshua

On first sign-in, choose a display name, bigger goal and optional starter habits. If existing habits are present, they are kept and no starters are preselected. Change an existing checkbox to a quantity/weekly habit in Settings rather than adding a duplicate.

Examples:

- Sleep: daily amount, target 8, unit hours. Enter the actual total for the day.
- Learn: daily amount, target 60, unit minutes.
- Gym: days per week, target 4. One check-in counts as one day.
- Eat well: daily checkbox.

Habit target/schedule changes retain dated definitions for earlier dates; progress entries also retain the target used when they were logged. Archiving removes future daily entries but preserves earlier records and exports.

## 5. Enable reminders

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

Each edit is applied immediately and written to an account-specific persistent queue before network sync. Sync sends independent operations under a server row lock; operation IDs are deduplicated. Different habits/days merge without overwriting unrelated changes. Edits to the **same habit/day total or same setting** use the last operation accepted by the server. This is a deliberate conflict rule, not collaborative arithmetic merging.

A timed-out request can safely retry. New edits made during an upload stay queued and are reapplied over the server response. The queue is processed in batches of 250, retried every 30 seconds while foregrounded and on app resume. Saving failures on the device are distinguished from waiting for cloud sync.

No background network worker runs when the app is closed. Local reminders still work; queued changes sync when the app opens again.

## Insights definitions

- Dashboard ring includes partial quantity progress, capped at each target.
- A “win” is a completed habit/day, not every incremental quantity log.
- Weekly habits count distinct completed days toward their weekly target (Monday–Sunday).
- Completion rates count scheduled daily opportunities up to the current weekday and the full target for weekly habits. Comparisons use the same elapsed weekdays of last week.
- Current/best streaks count consecutive days with at least one completed habit. An unfinished current day does not break yesterday’s streak.
- Quotes are original, rule-based copy chosen from local time and incomplete categories. No AI API or ongoing quote-generation fee.

## Validation limits

Flutter/Dart SDK and an Android emulator are not available in the editing environment. The source has passed Dart/Kotlin syntax parsing, Android XML parsing, SQL and PL/pgSQL parsing, and 10 production Java reminder-policy tests. Flutter model/widget tests are included but have NOT been executed here. No APK was compiled, and no Google/Supabase live-account test was performed. Run the commands and device checks in VALIDATION.md before sharing a release.
