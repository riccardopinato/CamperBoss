# CamperBoss — Static functional inventory + AppLab working register

Date: 2026-10-09
Baseline audited: `main@26f966f58934f6cfffbdb0d70c573a15f5445a9f`
Hotfix candidate: `fix/applab-notification-icon-runtime` / `0.2.2+18`

This is a working audit register, not the final STEP 16Q certification verdict.
Runtime evidence is never promoted from build/static/debug evidence.

## Runtime evidence separation

### Release 0.2.1+17
- Android API 35 / Pixel 7 Pro: build + install PASS, launch runtime FAIL.
- Failure: `PlatformException(invalid_icon, The resource app_notification could not be found...)`.
- Downstream Maestro/network/offline/persistence/process-death/storage/performance/visual lanes remain SKIPPED.
- Release API 29 lane was cancelled before this release verification and must be rerun separately.

### Older debug screen audit
AppLab run `37802021571` completed its debug screen-audit jobs on API 35 and API 29.
That is useful navigation/emulator evidence but does not override the release failure above.

## Screen-by-screen functional inventory

| Surface | Real implementation | Static status / caveat |
| --- | --- | --- |
| App shell | Home / Map / Trips / Camper / More, named routes for Web | IMPLEMENTED |
| Home | Local-data readiness, metrics, weather, attention actions, onboarding, guides | IMPLEMENTED |
| Map | MapLibre, geocoding, current/selected position, POI filters/clusters, POI details, offline-region controls | IMPLEMENTED WITH OPEN FINDINGS |
| Trips hub | Planner, Checklists, Journal, Finance, Travel History | IMPLEMENTED |
| Trip Planner | CRUD trips, stages/geocoding, saved route preview, ORS abstraction, camper/HGV profile, deletion lifecycle | IMPLEMENTED; production route provider is configuration-gated |
| Checklists | CRUD/toggle, categories, readiness progress | IMPLEMENTED; one hard-coded error remains |
| Journal | CRUD, km/cost aggregation | IMPLEMENTED; user-facing hard-coded errors remain |
| Finance | Expenses, fuel, bookings, trip budget/route context and vehicle-document associations | IMPLEMENTED |
| Travel History | History/statistics, GPX and photo/export paths, memories | IMPLEMENTED; some raw exception text can reach UI |
| Camper hub | Profile, Documents, Maintenance | IMPLEMENTED |
| Vehicle profile | Vehicle metadata used by readiness and camper-aware routing | IMPLEMENTED |
| Vehicle Documents | CRUD, private storage, Android scan, image/PDF import, OCR where supported, reminder integration | IMPLEMENTED; native Web capture intentionally unavailable |
| Maintenance | CRUD, attachments, deletion, reminders | IMPLEMENTED |
| More hub | Search, Offline content, Backup, Language, Notifications, Guided setup | IMPLEMENTED |
| Local Search | Rebuild/search local index across release domains | IMPLEMENTED |
| Offline Content | Catalog/download/reconciliation infrastructure for packages | IMPLEMENTED; production provider remains configuration/licensing-gated |
| Offline Guides | Bundled/installable guide path | IMPLEMENTED |
| Backup Tools | Export/import/inspect/merge/replace recovery path on IO platforms | IMPLEMENTED; runtime destructive-path proof remains STEP 16Q evidence |
| Language | System + EN/IT/DE/FR/ES/PT | IMPLEMENTED |
| Notifications | Permission/settings/test/reminder coordinator | CODE IMPLEMENTED; RELEASE RUNTIME BLOCKED by P0-01 until retest |
| Guided Onboarding | locale/country, vehicle, location, notifications, guide/checklist setup | IMPLEMENTED |
| Privacy/Data | Provider/local/network/document/account disclosure screen exists | UNREACHABLE from current production navigation |
| Pro/Subscription | Provider-neutral deferred UI/service exists | INTENTIONALLY DORMANT / no fake checkout |

## Map / POI analysis

### Canonical map/POI path
- Map renderer: MapLibre.
- Online style: OpenFreeMap.
- Offline bulk map source: intentionally requires an approved/self-hosted style URL; public OSM/OpenFreeMap bulk collection is not implicitly used.
- Canonical POI persistence: `LocalOfflinePoiRepository`.
- POI package pipeline requires source, licence, attribution, region, size and SHA-256 metadata.
- Production POI provider is intentionally not selected/enabled yet.
- Filters cover: sosta, camping, parcheggio, acqua, scarico, GPL, assistenza.
- Distance ordering is truthful: it is applied only when there is a real selected/current point.
- Trip Planner contains the camper-aware ORS/HGV routing implementation.

### Finding: legacy duplicate POI cache
`LocalPoiCacheRepository` stores a second copy of the current POI list in
`camperboss.poi_cache`. The map does not consume this collection as its
canonical POI source; it renders `LocalOfflinePoiRepository`.

The cache also synthesizes `North Italy` when no region metadata exists.
This violates Product Truth and reintroduces the exact ambiguity STEP 16L was
supposed to remove.

### Finding: POI directions bypass camper-aware routing
The Map POI action currently launches external Google Maps directly with the
destination coordinates. It does not send that POI through CamperBoss
`CamperRoutingProfileResolver` / ORS HGV routing.

This is not a crash, but it is a material product-truth/safety mismatch if the
user interprets "directions" as camper-aware guidance.

### Provider truth
The current provider/licensing ledger is internally consistent:
- OpenFreeMap/OSM online rendering requires attribution;
- public OpenFreeMap is not a bulk offline source;
- ORS production credentials remain server-side via approved proxy;
- Open-Meteo public endpoints are non-commercial-only under current policy;
- production POI/offline provider remains NOT SELECTED / NOT PRODUCTION ENABLED.

Therefore "no production POI catalog on fresh install" is an explicit release
configuration gate, not evidence that fake POI should be inserted.

## Unified working defect register

### P0

**P0-01 — Android release startup crash: notification icon removed**
- Source drawable exists, runtime release resource does not.
- `flutter_local_notifications` resolves `app_notification` by resource name.
- AppShell also duplicated the notification initialization after the guarded
  process-wide bootstrap.
- Candidate fix 0.2.2+18:
  - `res/raw/keep.xml` keeps `@drawable/app_notification`;
  - duplicate AppShell initialization removed;
  - packaging contract regression test added.
- Release retest on API 29 and API 35 no longer reproduces `invalid_icon`; both lanes reach the Home UI and Maestro.
- The first retest then failed only because the smoke expected `Boss Readiness` on a clean install, while CamperBoss intentionally hides readiness until enough real data exists. The smoke contract was corrected to use the Home cockpit title instead.
- Status: **RUNTIME STARTUP FIX VERIFIED; CORRECTED MAESTRO RERUN IN PROGRESS**.

### P1

**P1-01 — Legacy POI cache is non-canonical and synthesizes "North Italy"**
- Refresh duplicates existing POI rather than acquiring or representing an
  authoritative package/region.
- Remediation branch removes the duplicate cache surface/repository entirely; Map uses the canonical POI repository only.
- Status: **FIXED IN PR #24 / CI PENDING**.

**P1-02 — Map "Directions" bypasses camper-aware routing**
- External Google Maps launch does not apply vehicle dimensions/HGV restrictions.
- Remediation branch relabels this as external navigation and shows a disclosure before hand-off, explicitly directing camper-aware routing to Trip Planner.
- Status: **PRODUCT-TRUTH FIX IN PR #24 / CI PENDING**.

**P1-03 — Declared multi-language coverage contained substantial English fallback copy**
- The audit found large copied-English blocks in DE/FR/ES/PT despite green key/placeholder parity.
- Remediation translated the affected long-form Documents/OCR, Notifications, Offline, Backup, Home and routing-safety copy without overwriting already-localized values.
- Added `localization_translation_quality_test.dart`: IT/DE/FR/ES/PT may not ship long user-facing strings identical to EN.
- Current static check: zero identical EN strings of 18+ characters in all five non-English catalogs.
- Status: **FIXED IN PR #24 / FULL CI REVALIDATION REQUIRED**.

### P2

**P2-01 — Privacy/Data screen exists but is unreachable**
- Disclosure content is implemented but no current More/navigation entry opens it.
- Remediation branch adds a production More entry.
- Status: **FIXED IN PR #24 / CI PENDING**.

**P2-02 — Hard-coded runtime failure copy**
- Journal exposed hard-coded English error messages.
- Checklist add failure exposed `Checklist save failed` directly despite an existing translation key.
- Remediation branch replaces these with localized keys.
- Status: **FIXED IN PR #24 / CI PENDING**.

**P2-03 — Raw technical exception strings could reach users**
- Map/MapLibre, Travel History, backup recovery/tools and offline download rows exposed raw/internal errors.
- Remediation replaces those user-facing paths with localized safe states while retaining technical details only in internal service/model evidence where useful for diagnosis.
- Residual `error.toString()` occurrences are internal OCR/catalog/download diagnostics and are not rendered directly by the audited UI.
- Status: **FIXED IN PR #24 / FULL CI REVALIDATION REQUIRED**.

### P3

**P3-01 — Legacy production class name**
- Production map widget is still named `MapEngineV2PreviewScreen`.
- No runtime impact; maintenance debt only.
- Status: **OPEN**.

**P3-02 — README offline-platform wording is broader than active implementation**
- README said native offline regions on Android/iOS while iOS is explicitly deferred and the active offline manager supports Android in the current train.
- Remediation branch now states Android-only active support and iOS deferred.
- Status: **FIXED IN PR #24 / CI PENDING**.

## Evidence gaps — not product defects

These are certification gates and must not be counted as code PASS/FAIL without
execution:

- release API 35 retest on 0.2.2+18;
- release API 29 retest;
- Maestro journey after successful launch;
- notification permission + immediate test + scheduled reminder delivery;
- network/offline transitions;
- persistence + process death/recovery;
- storage-near-full;
- MapLibre physical no-network cached-region proof;
- performance/memory/battery runtime;
- visual journey/accessibility;
- Web deployed runtime;
- Play Internal evidence.

## No false closure

Do not emit STEP 16Q CERTIFIED while P0-01 has not passed release runtime and
the applicable external gates remain without evidence.
