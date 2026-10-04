# CamperBoss

CamperBoss is a Flutter Android/iOS/Web application for camper, vanlife and motorhome owners. The core is local-first: vehicle, trips, documents, maintenance, journal, finance, search and offline resources remain usable without a mandatory account or cloud service.

## Product areas

- **Home** — readiness and actions derived only from real local data.
- **Map** — MapLibre map, local/offline POI, routing and native offline map regions.
- **Trips** — planner, checklists, journal, budget, bookings, GPX and memories.
- **Camper** — vehicle profile, private documents and maintenance.
- **More** — local search, offline content, notifications, language and guided setup.

No demo trips, journal entries, checklist items or POI are inserted silently into user data.

## Current release-candidate capabilities

The active STEP 16 release-candidate stack contains:

- Flutter targets for Android, iOS and Web.
- Material 3 light/dark themes.
- Runtime locales IT/EN/DE/FR/ES/PT.
- SQLite persistence on mobile and local key/value JSON persistence on Web.
- Private vehicle documents, Android document scanning, image/PDF import and mobile OCR where supported.
- Maintenance history and local reminders.
- MapLibre as the production renderer; native offline regions on Android/iOS.
- Provider-neutral POI catalog/package install path, local repository and filtering. Production source/licensing selection remains a STEP 16O release gate.
- Open-Meteo weather/geocoding.
- OpenRouteService routing abstraction with camper-aware HGV restrictions when a valid vehicle profile is available. Production credential architecture is still a release gate.
- Offline download/guide infrastructure.
- Local search.
- GPX, travel memories and statistics.
- Versioned backup/export/restore services hardened by STEP 16K data-safety and recovery work.
- Dormant provider-neutral Pro entitlement boundary; no active billing SDK or fake checkout.

## Product Truth limitations

Do not describe the following as production-certified yet:

- physical MapLibre offline restart/no-network behavior;
- production POI catalog availability;
- Play Internal Testing delivery;
- iOS document scanning (iOS currently has import + OCR, not the Android scanner flow);
- full Web parity for native document/media flows;
- production ORS credential secrecy;
- STEP 17 local AI.

The authoritative release status is `ROADMAP.md` plus the latest Evidence Bundle.

## Local validation

```bash
flutter pub get
flutter analyze
flutter test
python3 tool/ci/release_guard.py identity
```

CI is pinned to Flutter 3.47.6 and source-controlled lockfiles. Pull requests run
release integration contracts, full tests with coverage, dependency/license
audit, secret scanning and project-specific SAST. Evidence artifacts are kept
for 30 days.

Platform/runtime certification is defined in the STEP 16 evidence and AppLab flows.

## Release delivery

Release identity is source-controlled in `pubspec.yaml` and
`release/release_identity.json`. Android Play delivery requires an exact
source SHA and real upload signing. The Play workflow builds one AAB, records
its SHA-256, stores it as an immutable candidate artifact, then Fastlane uploads
those same bytes from a separate job without rebuilding.

QA release APKs may use debug signing but are labelled QA-only and are never
eligible for Play upload. See `release/README.md`.

## Routing configuration

Development builds may receive an ORS key using `--dart-define=ORS_API_KEY=...`.
Do not commit keys. A key embedded in a client is not treated as a production secret; STEP 16O owns the production network boundary.

## Monetization

Production monetization is deferred. The current release candidate does not expose invented prices or checkout. Account/cloud/AI must not become prerequisites for the local-first core.

## Repository governance

The latest Master Prompt / Golden Rules govern reuse, data safety, review, delivery and certification. See `AGENTS.md`, `ROADMAP.md`, `docs/governance/` and `docs/release/`.
