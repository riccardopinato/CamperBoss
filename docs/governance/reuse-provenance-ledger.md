# Reuse & Provenance Ledger — CamperBoss

Reference hierarchy: Master Prompt v20.

## Decision order

1. Product Bible / Master / internal Golden
2. Existing CamperBoss implementation
3. Internal donor marked CERTIFIED
4. Approved OSS repository
5. External documentation/tooling
6. New code

This order is mandatory for future work. No retrospective donor search is
required when a stronger internal source already existed.

## Current ledger

| Area | Source | Mode | Status | Notes |
| --- | --- | --- | --- | --- |
| Map Engine V2 / offline patterns | TrailPath internal project | ADAPT / pattern reuse | INTERNAL DONOR — not promoted here to CERTIFIED | Step 14 explicitly reused known TrailPath patterns; CamperBoss retained its own domain/storage boundaries. |
| Flutter application core | CamperBoss | EXTEND | PROJECT SOURCE | Steps 13–16 consolidated existing repositories/providers rather than duplicating them. |
| Map rendering runtime | maplibre_gl package | DEPENDENCY | PACKAGE | No vendored/copied source in CamperBoss. |
| Routing | open_route_service package + provider API | DEPENDENCY/API | PACKAGE/API | Camper-aware adapter remains CamperBoss code. |
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
