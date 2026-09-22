# Animated intro update

Adapted from your supplied video: a centered logo scales and fades in on a near-black background, the app name and tagline appear, then the welcome header fades in and a rounded charcoal authentication card slides upward. Uses your existing Josh Tracker logo. The animation is native Flutter; no video player, network asset, or animation package is required.

## Run this project

Extract the ZIP, open the josh_tracker_app folder in your existing Flutter setup, and run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Do a full restart to replay the launch intro. Hot reload preserves its completed state. The intro plays once each cold launch; authenticated users go straight to the existing dashboard afterward. Logging out shows the welcome/login panel without replaying the splash. The system's reduced-motion setting skips entrance animations.

Google OAuth, Supabase configuration, data models, and platform configuration are unchanged. No OAuth or database setup is needed for this UI update. Existing initialization still completes before runApp, so the operating-system launch screen may remain visible while a saved session loads.

The reference video's later template-gallery onboarding and dashboard are not included: this update adapts its intro and login transition to the existing tracker.

## Files changed

- lib/main.dart: wraps the current authentication router in IntroScreen.
- lib/screens/intro_screen.dart: 2.2-second logo and title reveal.
- lib/screens/auth_screen.dart: 1.2-second staggered welcome and card entrance, sign-in/sign-up tabs, existing Google/email actions, scrolling layout for keyboards and compact screens, controller cleanup.
- pubspec.yaml: Flutter SDK test dependency.
- test/intro_screen_test.dart: splash completion, rebuild behavior, reduced motion, disposal.

Adjust duration in the two screen controllers to tune timing. Change the welcome copy directly in auth_screen.dart.

## Validation

Source/package review confirmed that OAuth, Supabase connection values, assets and native platform files match the input. Flutter/Dart SDK is not available in the editing environment; analysis, widget tests, emulator rendering and live sign-in have NOT been run. The included tests should be run locally. Check the following on your device before release:

1. Cold start while signed out: logo reveal, welcome header, sliding card.
2. Google sign-in success and cancellation; email sign-in and account creation.
3. Cold start with saved session: intro then dashboard; sign out returns to login.
4. Open the keyboard on a small screen; scroll to submit and any error message.
5. Enable reduced motion: both entrance sequences skip to their end states.

The archive omits generated .dart_tool, .gradle, build and IDE caches, plus machine-specific local.properties. Flutter regenerates these locally. Original source and native platform setup are retained.


## Apple-inspired Android refinement

This version applies the visual treatment throughout the Android app:

- Black backgrounds, grouped charcoal surfaces, thin dividers and clear typography.
- A floating translucent bottom tab bar with soft blur and selection haptics.
- Persistent tab state: calendar position and settings remain while switching tabs.
- Large Today, History and Settings headings with more breathing room.
- Simplified double progress rings and restrained blue highlights.
- Neutral habit icon backgrounds; stored habit names and emoji are retained.
- Matching dark login card, white Google button and a shorter launch animation.
- Cupertino-style route transitions while retaining the Android platform identity.

No additional runtime dependencies. Uses Android's available system typography; does not bundle Apple's SF font or imitate iOS system status bars. Google and email authentication still use the original functions. Backend storage is unchanged.

Run flutter analyze, flutter test and flutter run locally. In addition to the checks above, verify tab switching, habit toggles, history filters, settings edits, keyboard scrolling, large text and the translucent tab bar on your device. Flutter is not installed in the editing environment, so this UI has not been emulator-rendered or device-tested here.
