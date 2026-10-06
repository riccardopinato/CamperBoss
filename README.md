# CamperBoss

CamperBoss is a Flutter Android/Web application for camper, vanlife and motorhome owners. The iOS target is intentionally deferred and is not part of the current release or IAP scope. The core is local-first: vehicle, trips, documents, maintenance, journal, finance, search and offline resources remain usable without a mandatory account or cloud service.

## Product areas

- **Home** — readiness and actions derived only from real local data.
- **Map** — MapLibre map, local/offline POI, routing and native offline map regions.
- **Trips** — planner, checklists, journal, budget, bookings, GPX and memories.
- **Camper** — vehicle profile, private documents and maintenance.
- **More** — local search, offline content, notifications, language and guided setup.

No demo trips, journal entries, checklist items or POI are inserted silently into user data.

## Current release-candidate capabilities

The active STEP 16 release-candidate stack contains:

- Active release targets: Android and Web. iOS code may remain in-tree for future work, but iOS build/runtime/IAP gates are deferred.
- Material 3 light/dark themes.
- Runtime locales IT/EN/DE/FR/ES/PT.
- SQLite persistence on mobile and local key/value JSON persistence on Web.
- Private vehicle documents. Native document scanning is Android-only; Android/iOS support image/PDF import and mobile OCR where supported. Web never pretends to provide native document capture.
- Maintenance history and local reminders.
- MapLibre as the production renderer; native offline regions on Android/iOS.
- Provider-neutral POI catalog/package install path, local repository and filtering. Production source/licensing selection remains a STEP 16O release gate.
- Open-Meteo weather/geocoding.
- OpenRouteService routing abstraction with camper-aware HGV restrictions when a valid vehicle profile is available. Production credential architecture is still a release gate.
- Offline download/guide infrastructure.
- Local search across documents, maintenance, journal, trips, bookings, expenses, fuel, trip budget context, checklists, GPX tracks, travel memories, offline guides and vehicle data.
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
- STEP 17 local AI;
- TalkBack, keyboard/focus, 200% text scaling and browser runtime certification, which remain STEP 16Q evidence gates;
- visual store-asset/icon/splash certification.

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

## Localization and platform truth

CamperBoss ships IT/EN/DE/FR/ES/PT catalogs with automated key and placeholder
parity checks. Core Map, Finance, Trip Planner, Travel History, Checklist,
Offline Guides and Search surfaces are guarded against fixed user-facing
literals. Geocoding receives the current application language, and shared
formatters handle localized dates, decimal values, distances, currencies and
storage sizes.

iOS implementation details may remain in-tree for future reuse, but iOS build,
runtime and StoreKit/IAP behavior are not part of the current release scope.

Web metadata is branded for CamperBoss and no longer forces portrait
orientation. The app exposes named routes `/`, `/map`, `/trips`, `/camper`
and `/more`. GitHub Pages uses Flutter's default hash routing, so deployed
URLs are truthful forms such as `/CamperBoss/#/map` and
`/CamperBoss/#/trips`; server-side `/CamperBoss/map` rewrites are not
claimed.
Native-only document/media capability remains explicitly unavailable on Web.
Storage write failures propagate without replacing the previous JSON value and
do not poison later serialized writes; real browser quota/runtime evidence
remains part of STEP 16Q.

## Release delivery

Release identity is source-controlled in `pubspec.yaml` and
`release/release_identity.json`. Android Play delivery requires an exact
source SHA and real upload signing. The Play workflow builds one AAB, records
its SHA-256, stores it as an immutable candidate artifact, then Fastlane uploads
those same bytes from a separate job without rebuilding.

QA release APKs may use debug signing but are labelled QA-only and are never
eligible for Play upload. See `release/README.md`.

## Provider configuration

Production routing must use an HTTPS server-side boundary supplied through
`CAMPERBOSS_ROUTING_PROXY_URL`; provider credentials stay outside the Flutter
binary. Direct ORS/HeiGIT access is development-only and requires both
`ORS_API_KEY` and `CAMPERBOSS_ALLOW_DIRECT_ORS_DEV=true`.

Open-Meteo public endpoints are permitted only for explicitly non-commercial
builds. Before ads/IAP/subscriptions are enabled, configure commercial-capable
weather/geocoding proxy endpoints. Any upstream provider credential must remain
server-side and must not be embedded in the Flutter client.

Online MapLibre rendering may use OpenFreeMap. Offline region bulk collection
requires a separately approved/self-hosted style URL through
`CAMPERBOSS_OFFLINE_MAP_STYLE_URL`; the public OpenFreeMap endpoint is not used
as an implicit offline-download source.

See `docs/security/step-16o-threat-model.md`,
`docs/security/provider-licensing-ledger.md` and
`docs/privacy/data-inventory.md`.

## Monetization

Production monetization is deferred. The current release candidate does not expose invented prices or checkout. Account/cloud/AI must not become prerequisites for the local-first core.

## Repository governance

The latest Master Prompt / Golden Rules govern reuse, data safety, review, delivery and certification. See `AGENTS.md`, `ROADMAP.md`, `docs/governance/` and `docs/release/`.


## Current platform scope

For the current release train, Android is the native production target and Web is the verification/companion target. iOS is explicitly deferred until a future product decision. iOS failures do not block STEP 16 or release certification, and Apple StoreKit / iOS IAP integration is out of scope. Android monetization, when introduced, will use the Google Play path only.
