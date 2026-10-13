# Reuse & Provenance Ledger — CamperBoss

Factory reference: App-Factory-Core CURRENT resolved at
`a1713e5acc9e157543038bebb4ba83b6d26e5f91` (Master v26 / Golden Index v11).

## Decision order

1. Product Truth / current Roadmap and applicable Factory Golden
2. Existing CamperBoss implementation
3. Internal donor marked CERTIFIED
4. Approved OSS repository
5. Current provider/framework documentation
6. New code

No retrospective donor search is required when a stronger internal source
already exists.

## Current ledger

| Area | Source | Mode | Status | Notes |
| --- | --- | --- | --- | --- |
| Map Engine V2 / offline patterns | TrailPath internal project | ADAPT / pattern reuse | INTERNAL DONOR — not promoted here to CERTIFIED | Step 14 explicitly reused known TrailPath patterns; CamperBoss retained its own domain/storage boundaries. |
| Flutter application core | CamperBoss | EXTEND | PROJECT SOURCE | Steps 13–16 consolidated existing repositories/providers rather than duplicating them. |
| Map rendering runtime | maplibre_gl package | DEPENDENCY | PACKAGE | No vendored/copied source in CamperBoss. |
| Routing | OpenRouteService provider API + CamperBoss HTTP adapter | API / PROJECT ADAPTER | PROVIDER API | The unused `open_route_service` Dart wrapper was removed in the Factory v26 code-hygiene pilot; routing remains CamperBoss code using the project/provider boundary. |
| Document scan/OCR | Google ML Kit Flutter packages | DEPENDENCY | PACKAGE | No ML Kit source copied into repository. |
| Code review automation | CodeRabbit | TOOL CONFIG | CANDIDATE INTEGRATION | Project config is not promoted to Golden until verified on real PR reviews. |
| Android delivery | Fastlane | TOOL CONFIG | CANDIDATE INTEGRATION | Build-once lane uploads an already-built AAB; no Fastlane source vendored. |

## Rules

- COPYING OSS SOURCE requires repository URL, exact revision/tag, license,
  selected files and modification notes before merge.
- IDEA ONLY / aesthetic inspiration must be recorded as such and must not
  silently become source copying.
- Internal donor status is distinct from Golden certification.
- Generated files and build artifacts are never provenance sources.
- Secrets, signing keys and service-account JSON are never committed.
