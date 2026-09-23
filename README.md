# Josh Tracker 3 — a little better, every day

Android / Flutter personal habit tracker with Google and email sign-in, Supabase, an Apple-inspired adaptive light/dark interface, adaptive dashboard, quantity and weekly goals, onboarding, insights, offline edits and native Android reminders.

**Start with [START_HERE.md](START_HERE.md). This version requires a one-time Supabase SQL upgrade before cloud sync works.**

Shorebird is not included. This is a source project, not a compiled APK.

## New in V3

Daily priorities, mood/energy check-ins, evening reflections, personal weekly reviews, planned rest and dated habit pauses, milestones, a native Android home-screen widget, and synced theme/accent/voice preferences.

- Today keeps the daily essentials together; History opens date-specific journals.
- Insights contains weekly reviews and milestones.
- Settings → Personalization controls appearance, voice and recovery.
- Run `supabase/UPGRADE_V3.sql` once, including when upgrading from V2. It extends the existing state and sync function without deleting data.
- The native widget requires a full APK build/install. It is a local snapshot and opens the app for logging.

## Existing features retained

- Dashboard: time-aware greeting, original motivational prompts based on incomplete habits, animated progress ring, next useful action, current streak, weekly wins and bigger goal.
- Habits: daily checkboxes, measured daily amounts, selected weekdays, and goals such as gym on four days each week. Edit targets, categories and reminder times; archive without deleting earlier history.
- Insights: this week’s completion rate, same-weekday comparison, active-day streaks, daily chart and individual habit progress.
- Onboarding: name, bigger goal, optional starter habits, notification opt-in and quiet hours. Existing habits stay; starter habits are optional additions.
- Reminders: each habit’s time, remaining-habit daily summary, 30-minute snooze, quiet hours, Android permission UI and a test notification.
- Sync: account-specific local cache and durable pending edits; automatic retry while foregrounded, on resume, pull-to-refresh and a manual Retry action. Atomic cloud merge and operation IDs prevent retry duplication.
- Native Android scheduling rechecks local progress at delivery, restores after reboot and uses inexact battery-friendly alarms. No paid notification provider or additional Flutter runtime package.

## Build

From the project folder on your existing Flutter machine:

```sh
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

Use an Android device/emulator. Restart the app fully after the native code changes. A Windows desktop launch does not exercise Android notifications or native Google sign-in.

See START_HERE.md for installation, migration and notification details. See VALIDATION.md for the exact checks performed and remaining device tests.
