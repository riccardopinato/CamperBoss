# App Factory v26 Agent Governance / Code Hygiene Pilot — 2026-10-13

## Baselines

- App Factory Core: `a1713e5acc9e157543038bebb4ba83b6d26e5f91`
  - Master v26 FULL
  - Golden Index v11
  - Agent Governance v0.1 DRAFT
  - Code Hygiene v0.1 DRAFT
- CamperBoss main before pilot:
  `6c866bf8884b78703401db8ce08dbcf97d3f893c`

## Scope

Pilot the new repository-local Agent Governance and bounded obsolete-code sweep
without changing CamperBoss product scope or release certification claims.

## Findings and decisions

### REMOVE

1. `lib/core/constants/app_strings.dart`
   - no import/reference found in the repository;
   - constants were not the runtime source for the app title/localized copy.

2. `lib/core/constants/app_radius.dart`
   - `AppRadius` had no consumer;
   - active shared widgets use their own current radius values.

3. `open_route_service: 1.2.7`
   - no `package:open_route_service` import or symbol usage exists in CamperBoss;
   - routing is implemented by CamperBoss through its HTTP/provider boundary;
   - package metadata for 1.2.7 lists only `http` as a dependency, and CamperBoss
     already keeps `http` as a direct dependency;
   - removed from both `pubspec.yaml` and `pubspec.lock`.

Provider/package verification:
https://pub.dev/packages/open_route_service/versions/1.2.7
(reviewed 2026-10-13).

### KEEP

1. `FakeLocalNotificationService`
   - active test double used by reminder and More-screen tests.

2. `NoopOfflinePackageInstaller`
   - intentional default adapter used by `AppDownloadManager` when no package
     installer is supplied.

3. `MapEngineV2PreviewScreen`
   - historical name is maintenance debt, but the class is the active production
     MapLibre surface and is referenced by product code and tests;
   - renaming it during this pilot would be unrelated refactor churn.

4. Platform `*_io.dart` / `*_stub.dart` adapters
   - retained as explicit platform boundaries, not duplicates.

### DOCUMENTATION / GOVERNANCE DRIFT

1. Root `AGENTS.md` selected an unspecified "latest" Master/Golden from the
   ChatGPT project.
   - replaced with deterministic App-Factory-Core CURRENT resolution and pinned
     session-baseline semantics.

2. `docs/IMPLEMENTATION_STATUS.md` still claimed `main` was on STEP 15 / early
   STEP 16J.
   - updated to the actual STEP 16Q main baseline and current external gates.

3. Provenance ledger still referenced Master v20 and described the unused
   `open_route_service` wrapper as an active dependency.
   - updated to Factory v26 and the actual provider/API architecture.

4. README governance wording relied on "latest" prompt semantics.
   - replaced with deterministic CURRENT resolver wording.

## Bounded-cleanup boundary

Not changed in this pilot:

- large screens/services solely because of LOC;
- active MapLibre class naming;
- database migrations/history;
- platform stubs;
- release evidence;
- provider architecture;
- STEP 17 AI.

These require a concrete product/maintenance reason, not cleanup for aesthetics.

## Validation target

Final validation must run after the deletions and dependency cleanup:

- `flutter pub get` with zero `pubspec.lock` drift;
- release identity/supply-chain/security/trust guards;
- `flutter analyze`;
- integration contracts;
- full Flutter tests + coverage gate.

Runtime/device/AppLab evidence is not required to prove this governance-only
pilot, and no existing STEP 16Q physical gate is promoted by this work.

## Pilot verdict

Status before CI: **IMPLEMENTED — AUTOMATED VALIDATION PENDING**.

Promotion evidence for the Factory Agent Governance / Code Hygiene Golden must
use the actual PR/CI result, not this document alone.
