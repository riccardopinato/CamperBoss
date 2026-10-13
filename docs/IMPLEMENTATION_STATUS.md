# CamperBoss implementation status

Last updated: 2026-10-13

## Canonical development baseline

`main` is currently pinned at
`6c866bf8884b78703401db8ce08dbcf97d3f893c`, the STEP 16Q release-candidate
and AppLab-remediation baseline.

The current audit/certification status remains **NOT CERTIFIED / BLOCKED**.
Green Flutter/platform builds do not substitute for runtime, physical-device,
store-delivery or no-network evidence.

STEP 16R is documented as **DONE SOFTWARE — RETEST DEVICE REQUIRED** in
`ROADMAP.md`; it does not by itself close STEP 16Q certification.

## Implemented on main

- Five-area product shell: Home / Map / Trips / Camper / More.
- Local-first persistence across trips, checklists, journal, vehicle, documents,
  maintenance, reminders, finance, routes and travel history.
- MapLibre renderer consolidation and native offline-region support where the
  current platform boundary allows it.
- Camper-aware route request adapter.
- Real-data Home readiness model.
- Vehicle document archive, Android scanner, PDF/image import and mobile OCR.
- Maintenance attachments and reminders.
- Local search with revision-driven freshness.
- Offline guide/download coordination.
- GPX, memories and statistics.
- Versioned backup with manifest/hash verification, safety snapshot and
  physical-file remapping.
- Reference-safe media cleanup for documents, maintenance, memories and GPX.
- Android privacy flags and platform-specific data-safety boundaries.
- Flutter CI and Android/Web release workflows.
- CodeRabbit configuration and Fastlane immutable-artifact delivery scaffolding.

## Open release gates

The authoritative backlog is `ROADMAP.md` and the compact pointer is
`PENDING_ISSUES.md`.

Current unresolved release evidence includes:

- STEP 16M external Google Play Internal Testing evidence.
- STEP 16Q Android AppLab/device and Web runtime certification.
- Physical MapLibre no-network proof with an approved offline provider.
- Accessibility/performance runtime evidence and visual asset QA.
- STEP 16R physical retest of the first-device hotfix.

Commercial monetization remains gated on production-capable provider
configuration. iOS build/runtime/StoreKit/IAP is deferred and non-blocking for
the current release train.

## Platform truth

- Android: scanner + import + OCR supported by the current candidate.
- iOS: implementation may remain in-tree for future work, but iOS release/runtime
  is deferred for the current release train.
- Web: UI/navigation/local-data preview is supported; native file/media
  capability can degrade or be unavailable.
- Offline map regions: implementation exists, but restart/no-network physical
  certification remains required for the supported release target.

## AI

STEP 17 is intentionally gated. The non-AI baseline must be stable and measured
before any local model is selected.
