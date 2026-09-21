# Josh Tracker — Flutter (native Android)

Native rewrite of the tracker. Same features, native UI, and **native Google sign-in**
(account picker — no WebView, no deep links). Supabase keys are already baked into
`lib/config.dart`. You only need to fill the Google **web client ID**.

## 0. Prereqs
- Flutter SDK installed and green:  `flutter doctor`
- Android Studio / SDK (you already have it)

## 1. Create the shell, drop in this code
Flutter needs the native `android/` + `ios/` folders generated for your machine:

```bash
flutter create --org com.josh --project-name tracker josh_tracker_app
cd josh_tracker_app
```
Then copy from this bundle into that project, overwriting:
- `pubspec.yaml`
- the whole `lib/` folder
- the `assets/` folder (holds `icon-512.png`)

Set the Android package id — open `android/app/build.gradle`, confirm:
```
applicationId "com.josh.tracker"
```
(matches `--org com.josh` + name `tracker`). Then:
```bash
flutter pub get
```

## 2. Google sign-in setup (the one real chore)
Native Google needs two OAuth clients in the **same** Google Cloud project you used
for the web version.

1. **Get your app's SHA-1** (debug key):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Copy the `SHA1` under `Variant: debug`.
2. Google Cloud → **APIs & Services → Credentials → Create credentials → OAuth client ID → Android**:
   - Package name: `com.josh.tracker`
   - SHA-1: paste the one above.
3. You already have a **Web** OAuth client (from the web build). Copy its **Client ID**
   and paste into `lib/config.dart`:
   ```dart
   static const googleServerClientId = '....apps.googleusercontent.com';
   ```
   (Use the **Web** client ID here, not the Android one — that's what makes Google
   return an ID token Supabase accepts.)
4. Supabase → Authentication → Providers → Google: already enabled with that Web
   client ID + secret. Nothing to change.

> Release builds use a different signing key → add that keystore's SHA-1 as a second
> Android OAuth client when you ship.

## 3. Run
```bash
flutter run
```
Plug in the phone (USB debugging on) or use an emulator. Tap **Continue with Google** —
native account sheet appears, pick account, you're in. Email/password fallback also works.

## 4. App icon + name
- Launcher icon: drop your 1024px logo at `assets/icon.png` and use
  `flutter_launcher_icons` (add to dev_deps), or set it in Android Studio.
- Name under the icon: `android/app/src/main/AndroidManifest.xml` → `android:label`.

## 5. Build the apk
```bash
flutter build apk --debug     # sideload on your phone
flutter build apk --release   # signed release (set up signing first)
```
Output: `build/app/outputs/flutter-apk/`.

## Notes / honest limits
- Data model unchanged: one JSON row per user in `tracker_state`, offline cache in
  shared_preferences, **last-write-wins** on a timestamp. Not a multi-device merge.
- Not compile-tested in my environment. Run `flutter analyze` after `pub get`; if
  anything errors, paste it and I'll patch — most likely a package-version tweak.
- The Google "G" on the button is a plain mark; swap for the multicolour SVG if you want.
