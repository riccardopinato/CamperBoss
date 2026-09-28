# CamperBoss

CamperBoss is a Flutter app for camper, vanlife and motorhome owners. The
product is local-first: core vehicle, trip, document, maintenance, journal,
finance and offline data remain useful without requiring an account or cloud
connection.

## Product direction

CamperBoss is being developed as a personal camper operating system rather than
only a campsite finder.

Primary areas:

- Home: real readiness and actions derived from local data.
- Map: POI, routing and future verified offline cartography.
- Trips: planner, checklists, journal, budgets, bookings, GPX and memories.
- Camper: vehicle profile, private documents and maintenance.
- More: local search, downloads, guides, notifications and setup.

The primary navigation is intentionally limited to five destinations. Secondary
tools live inside their product context instead of occupying a permanent tab.

## Current capabilities

- Flutter Android, iOS and Web targets.
- Material 3 light/dark themes following the system setting.
- Runtime localization assets for IT, EN, DE, FR, ES and PT.
- Local persistence for trips, checklists, journal, vehicle profile, documents,
  maintenance, reminders, route previews, finance and travel history.
- Private vehicle document archive with import/scanning/OCR flows where
  supported.
- Local maintenance history with due-date and mileage logic.
- Open-Meteo weather and geocoding.
- OpenStreetMap online rendering through `flutter_map`.
- POI filters and clustering.
- OpenRouteService route preview abstraction.
- Versioned offline-content/download infrastructure.
- Offline guides and guided onboarding.
- Local search architecture with AI gateway disabled by default.
- GPX, memories and travel statistics.
- Backup/export/import services.
- Local notification/reminder infrastructure.

Demo trips, journal entries, checklist items and POIs are no longer inserted
silently into real user data. Empty states stay empty until the user creates or
explicitly imports content.

## Current engineering focus

1. Product-truth cleanup and five-destination shell.
2. Verified Map Engine V2 proof of concept for real offline maps.
3. Camper-aware routing using the saved vehicle dimensions where the routing
   provider can support them.
4. Release hardening: privacy, CI, monetization, localization completeness and
   device QA.
5. Optional on-device AI only after the non-AI core is reliable.

The future local-AI track must remain optional and provider-abstracted. Candidate
micro-models such as Cactus/Needle-class models should be benchmarked before
adoption for binary/model size, RAM, latency, supported devices, quality,
license and offline privacy. The target for the first experiment is a model
artifact around or below 50 MB; no specific model is considered selected yet.

## Local commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Routing configuration

Route previews compile without secrets and stay disabled until an ORS key is
provided at runtime:

```bash
flutter run --dart-define=ORS_API_KEY=your-local-key
```

Do not commit real API keys. Routing remains behind an application service so
the provider can be replaced or proxied later.

## Quality

GitHub Actions runs dependency resolution, `flutter analyze` and
`flutter test` for the active development branch and pull requests to
`main`.
