# CamperBoss — Master v20 / Golden Rules Heavy Audit

Date: 2026-10-03  
Audit baseline: `step-16i-lifecycle-media-safety` @ `3bec9e5857dad94258d0cff32dfa23beba336417`

## Scope and reference model

This audit applies the latest project rules recovered from the Master Prompt v20 / Golden Rules project history:

- Product Truth / Product Bible as source of truth;
- Architecture Before Scale;
- reuse order: Master/Golden → existing implementation → CERTIFIED internal donor → approved OSS → external docs/tools → new code;
- evidence-based FAST / FULL / CERTIFIED validation;
- Golden component states must not be promoted by assumption;
- Batch Data Safety: lifecycle, media ownership, backup/recovery and staged restore;
- CodeRabbit PR review and Fastlane build-once delivery;
- Heavy Audit across governance, Git lineage, supply chain, security/privacy, performance/battery/size, UX/accessibility/localization and runtime evidence.

The exact Master/Golden source files are not stored as directly searchable repository files in CamperBoss. This audit therefore uses the latest rules available in the project conversation plus the real repository baseline above.

## Executive verdict

Automated compilation and unit/widget coverage are strong, but CamperBoss is **NOT CERTIFIED for production**.

The main problem is not one isolated bug. The repository currently has several layers of truth that disagree:

- `main` is still STEP 15 while STEP 16D–16I live in a stacked PR chain;
- GitHub Pages deploys from `main`, so the public Web preview is not the current candidate;
- documentation claims capabilities that the implementation does not fully expose or support;
- data-safety mechanisms are improved but not yet transactional/complete;
- POI acquisition, Play delivery, runtime AppLab/device certification and provider/legal boundaries remain incomplete.

## P0 — release blockers

### P0-01 — Canonical baseline / main is stale
Evidence:
- `main` = `f3cbd5437f3cbbdc93e89a9dc3a0741fb00ce831` (STEP 15).
- Current candidate = `3bec9e5857dad94258d0cff32dfa23beba336417`.
- Open stack: PR #5 → #6 → #7 → #8 → #9 → #10; old draft PR #4 still exists.
- `.github/workflows/deploy-pages.yml` deploys only pushes to `main`.

Impact:
- “current app”, “web preview” and release evidence can refer to different code.

Action:
- STEP 16J. Consolidate only after gates; certify and deploy the same canonical SHA.

### P0-02 — Backup/restore does not meet the original transactional contract
Evidence:
- `docs/roadmap/step-09-backup-export-import.md` requires transaction, staging and commit only after success.
- `DataBackupService._replaceAll` deletes/saves repositories sequentially.
- Safety backup/rollback is better after STEP 16H, but it is not an atomic DB unit-of-work.

Additional gaps:
- no reachable Backup/Restore UI in More/other current hubs;
- user settings/state are not complete in the snapshot;
- merge can materialize physical files for incoming records that are later skipped, leaving orphan copies;
- v1 ambiguous/unmapped paths may be left unresolved;
- ZIP/files are assembled in memory and are not safe for large datasets.

Action:
- STEP 16K. Reopen Backup Recovery until failure-injection + large dataset tests pass.

### P0-03 — Cross-domain destructive operations are not atomic enough
Evidence:
- `TripDeletionService` deletes finance → history/media → route → trip sequentially.
- DB schema does not provide FK/cascade constraints for these domain references.
- Vehicle document deletion can leave `document_id` references in expense/fuel/booking rows.
- `DataIntegrityService` detects only a subset of possible orphan relationships.

Impact:
- partial failure can leave inconsistent local data.

Action:
- STEP 16K. Unit-of-work/saga + expanded integrity and lifecycle recovery.

### P0-04 — POI Product Truth is incomplete
Evidence:
- `MapScreen` loads POI from `LocalOfflinePoiRepository`.
- That repository imports already-available packages but does not fetch a real provider.
- default `LocalOfflineManifestRepository` has no remote loader configured.
- “Refresh cache” persists the current list; it does not acquire POI.

Impact:
- a fresh install can have a technically functional map/filter UI with zero real POI supply.

Action:
- STEP 16L. Approved POI source/catalog, licensing, install/update pipeline and runtime proof.

### P0-05 — Routing production credential boundary unresolved
Evidence:
- ORS key is read from `String.fromEnvironment('ORS_API_KEY')`.
- A key compiled into a mobile/web client is extractable and cannot be treated as a secret.
- without the define, routing is intentionally unavailable.

Action:
- STEP 16O. Choose an approved public-client/proxy/token architecture before production routing is enabled.

### P0-06 — Physical offline/device certification remains open
Evidence:
- Android/iOS/Web builds are green.
- No build result proves a MapLibre region reopens after restart with network disabled.
- current Maestro/AppLab scripts are stale and still reference Lake Garda / legacy Preview flow.

Action:
- STEP 16Q. Rewrite runtime flows and execute physical/runtime gates.

## P1 — must fix before production maturity

### P1-01 — Governance files contradict Master v20
- `AGENTS.md` forbids global audits and says to reimplement external patterns instead of the current REUSE-FIRST hierarchy.
- `docs/IMPLEMENTATION_STATUS.md` is dated 2026-06-12 and still describes a mock MVP.
- `README.md` still mentions user-facing `flutter_map`.
- `PENDING_ISSUES.md` is obsolete.
- ROADMAP had two simultaneous `CURRENT` steps.

Action: STEP 16J.

### P1-02 — Branch protection / required check governance not demonstrated
- repository rulesets API returns no rulesets.
- classic branch protection could not be verified with the installed GitHub integration.
- required checks/review/no-direct-release policy is therefore NOT VERIFIED.

Action: STEP 16J.

### P1-03 — CodeRabbit integration exists but review gate is not yet certified
- `.coderabbit.yaml` is recognized.
- stacked PRs targeting non-default branches can skip automatic review unless explicitly triggered.
- no completed final review gate has been captured for the canonical release PR.

Action: STEP 16J/16Q.

### P1-04 — CI pull-request triggers are too narrow
- `flutter-ci.yml` and Release Core rely on `ready_for_review` for PR events.
- opened/synchronize/reopened are not covered generically; STEP 16 branches happen to get push CI but future branches may not.

Action: STEP 16M.

### P1-05 — Supply-chain versions are mutable
- Actions use tags such as `actions/checkout@v4`, `subosito/flutter-action@v2`, `ruby/setup-ruby@v1`.
- Flutter is `channel: stable`, not a fixed SDK.
- `Gemfile.lock` is absent.

Action: STEP 16M.

### P1-06 — Fastlane lane path is unverified and likely launched from wrong working directory
- workflow runs `bundle exec fastlane android internal` from repository root.
- project `Fastfile` is under `android/fastlane/Fastfile`.
- delivery workflow has not been proven with real secrets/Play.

Action: STEP 16M. Run from `android` or configure explicit lane path and prove build-once hash continuity.

### P1-07 — Release version identity is still template-level
- `pubspec.yaml` = `0.1.0+1`.
- no monotonic versionCode/versioning release process is defined.

Action: STEP 16M.

### P1-08 — Static analysis and security gates are too shallow
- `analysis_options.yaml` only enables `prefer_single_quotes`.
- no demonstrated coverage threshold, dependency/license gate, secret scan or SAST gate.

Action: STEP 16M.

### P1-09 — Reminder service graph is not actually single-instance
- `AppSystemServices.instance` owns a ReminderCoordinator and initializes it.
- `AppShell` creates a second ReminderCoordinator and initializes/reconciles it again.
- some screens use the global coordinator, More receives the shell-local coordinator.
- notification rescheduling calls `cancelAll()`, increasing race potential.

Action: STEP 16K/N. One process-wide coordinator.

### P1-10 — stale reminder repository entries are not reconciled away
- reconcile rebuilds reminders for existing sources but does not globally purge source IDs that no longer exist.
- a later `activeReminders()` call can read future stale rows if a delete/sync path failed.

Action: STEP 16K. Reconcile source set + integrity audit.

### P1-11 — Web/local JSON writes can lose concurrent updates
- `LocalJsonCollection` uses read-modify-write without mutex/revision compare.
- Map region state uses the same pattern.
- multiple repository/service instances exist.

Action: STEP 16K. Serialized write boundary or optimistic revision.

### P1-12 — Offline storage “available” is not device free space
- `LocalStorageInspector` uses a fixed 5 GiB app budget.
- native MapLibre region bytes are managed outside the installed-resource accounting.

Impact:
- storage pressure can be materially different from the real device state.

Action: STEP 16L.

### P1-13 — Localization parity test is not localization completeness
Concrete hard-coded UI remains in:
- `map_screen.dart`;
- `map_engine_v2_preview_screen.dart`;
- `finance_screen.dart`;
- `trip_planner_screen.dart`.

`GeocodingService.search` defaults to English and Map does not pass current locale.

Action: STEP 16N. Literal audit + locale-aware geocoder/formatting.

### P1-14 — iOS notification permission truth is incomplete
- `getPermissionState()` returns `unavailable` on iOS even though requesting permission is implemented.

Action: STEP 16N.

### P1-15 — iOS scanner claim is false in current implementation
- document capture selects the ML Kit document scanner only on Android.
- iOS fallback supports import and OCR, not the scanner.
- ROADMAP STEP 4 says “scansione Android/iOS”.

Action: STEP 16N. Implement iOS scan or correct Product Truth everywhere.

### P1-16 — Web capability is not equivalent to mobile for private documents/media
- web document capture/storage stubs are unsupported.
- current product copy/spec must distinguish graceful degradation from parity.

Action: STEP 16N.

### P1-17 — privacy/legal/provider inventory is incomplete
Needs formal records for:
- Open-Meteo;
- OpenRouteService;
- MapLibre/OpenFreeMap/OSM attribution and offline caching;
- Google ML Kit;
- packages/assets/guides/donors.

Action: STEP 16O.

### P1-18 — no formal at-rest threat-model decision
- Android/iOS app sandbox and OS-backup restrictions are present.
- SQLite/private files/localStorage are not app-encrypted.
- this is not automatically a defect, but the security decision is undocumented.

Action: STEP 16O.

### P1-19 — large backup/photo/GPX/search paths lack stress evidence
- backup reads archived files into memory and ZipEncoder emits the whole archive;
- photo ZIP follows a similar in-memory path;
- large GPX and search-index rebuild can create high memory pressure.

Action: STEP 16P.

### P1-20 — current AppLab/Maestro evidence is stale
- home audit comments still describe an older expected failure;
- map audit expects Lake Garda and a legacy Preview flow;
- coordinate-based bottom navigation is brittle.

Action: STEP 16Q.

## P2 — quality and maintainability backlog

### P2-01 — leftover mock/demo source
`lib/data/repositories/mock_camper_repository.dart` still contains Lake Garda/Dolomites sample data. No production reference was found in the inspected candidate, but keeping it in release source increases regression risk.

Action: quarantine to tests or remove in STEP 16L/J.

### P2-02 — generic map center can create misleading distance semantics
When no real selected location exists, Map uses `LatLng(42.5, 12.5)`. It should be a viewport-only concept and must never be treated as the user's distance origin.

Action: STEP 16L.

### P2-03 — search scope is narrower than a “global search” interpretation
Current source covers documents, maintenance, journal, trips, bookings, guides and vehicle profile, but not expenses, fuel, budgets, checklist, GPX or memories.

Action: decide honestly in STEP 16N: extend or narrow product copy.

### P2-04 — web/PWA metadata remains Flutter template content
- title/name capitalization inconsistent;
- description says “A new Flutter project.”;
- manifest forces portrait-primary.

Action: STEP 16N.

### P2-05 — branding/template residue
- iOS display name uses `Camperboss`;
- Android Gradle retains template TODO text;
- icon/splash/store assets need visual certification.

Action: STEP 16N/16Q.

### P2-06 — database integrity relies mostly on application code
No comprehensive FK/index strategy is evident for domain relationships. Even if explicit FKs are not adopted, indexes and invariants should be reviewed against query/delete patterns.

Action: STEP 16K/16P.

### P2-07 — timezone fallback is silent
If local timezone lookup fails, reminders use UTC. A local deadline can therefore fire at an unexpected time.

Action: STEP 16N.

### P2-08 — artifact evidence retention is short
Release Core APK is retained for one day, too short for asynchronous manual certification.

Action: STEP 16M.

### P2-09 — public-repository hygiene needs an intentionality check
The public tree contains dossier/extracted docs and `chat con grok.txt`. No secret was identified in this audit, but public exposure and long-term history should be intentional.

Action: STEP 16J/O.

## What is already strong

Do not rewrite these areas blindly:

- MapLibre renderer consolidation and persisted offline viewport metadata;
- local-first repositories and no mandatory account/cloud dependency;
- Android `allowBackup=false` and `usesCleartextTraffic=false`;
- iOS private-document backup exclusion bridge;
- data revision driven search freshness;
- map/offline/guide reconciliation architecture;
- backup manifest/hash validation and automatic safety backup;
- STEP 16I reference-safe cleanup for shared document/maintenance/travel media;
- multicurrency travel-statistics correction;
- route fingerprint invalidation against vehicle/stage changes;
- build matrix Android/iOS/Web and APK size discipline;
- six translation catalogs with key-parity test;
- removal of automatic demo inserts.

These are candidates for reuse/Golden extraction only after the relevant audit/certification state is explicit.

## Certification consequence

STEP 17 Local AI remains gated.

The next work order is:

`16J Product Truth/Governance → 16K Data Safety → 16L Map/POI/Offline → 16M Release/Supply Chain → 16N Localization/Accessibility/Web/iOS → 16O Security/Privacy/Licensing → 16P Performance/Stress → 16Q Runtime certification`.

No AI model selection should start before this non-AI baseline is stable enough to provide reliable size/RAM/battery/runtime controls.
