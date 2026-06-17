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
- Live Open-Meteo weather card with safe timeout/fallback.
- OpenStreetMap tile map through `flutter_map`.
- Runtime localization wiring with `easy_localization`.
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

## Open services connected

- Weather: Open-Meteo Forecast API.
- Maps: OpenStreetMap tiles via `flutter_map`.
- Routing: OpenRouteService route previews via `open_route_service`/Directions.
- Translations: local JSON assets loaded at runtime via `easy_localization`.

## Routing configuration

Route previews compile without secrets and stay disabled until an ORS key is
provided at runtime:

```bash
flutter run --dart-define=ORS_API_KEY=your-local-key
```

Do not commit real API keys. The current client is behind `RoutingService` so it
can be replaced by a server-side proxy later.

## Next milestone

Run the UI on Android/iOS/Web, polish the live map/weather experience, then add
local persistence with Drift/SQLite.
