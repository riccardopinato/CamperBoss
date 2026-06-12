# CamperBoss

CamperBoss is a Flutter mobile app concept for camper, vanlife, and motorhome
travelers.

Current milestone: visual MVP baseline with mock data.

## What is included

- Material 3 dark premium theme.
- Bottom navigation shell.
- Mock screens for Home, Map, Trips, Checklist, Journal, Profile, and Pro.
- Reusable UI widgets for cards, buttons, action tiles, section headers, weather
  summary, place cards, trip cards, checklist items, empty states, loading
  overlay, and badges.
- Centralized mock data models and repository.
- Translation JSON placeholders for IT, EN, DE, FR, ES, PT.
- Android, iOS, and Web platform folders.
- Passing `flutter analyze` and `flutter test`.
- No real Firebase, RevenueCat, Drift, map, or weather integration yet.

## Local commands

Flutter is required on the machine PATH. In this Codex environment it was
verified through `C:\Users\Riccardo\Documents\Codex\tools\flutter`.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Next milestone

Run the mock UI on Android/iOS/Web, polish the visual experience, then wire
runtime localization and connect real services one at a time.
