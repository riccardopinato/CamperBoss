# STEP 16P — Performance, memory, battery and stress baseline

Snapshot: 2026-10-05
Active release scope: Android + Web.

## Automated regression baseline

The CI suite includes broad, repeatable stress checks for:
- MapLibre POI clustering with 10,000 POIs;
- GPX parsing/simplification with 5,000 points;
- local-search rebuild/query with 5,000 documents;
- backup creation + inspection with 1,000 trips.

The tests write `build/evidence/performance-baseline.json`. Their wall-clock
limits are intentionally broad. They detect severe regressions and accidental
algorithmic blow-ups; they are not a substitute for device profiling.

## Artifact size budgets

Release Core enforces:
- Android ARM64 QA APK: <= 80 MiB;
- Web release directory: <= 65 MB uncompressed aggregate.

Every platform build records exact bytes in the Evidence Bundle.

## Runtime matrix delegated to STEP 16Q

The following require a real device/browser harness and are measured only in
the final certification pass:
- Android cold/warm start;
- sustained MapLibre pan/zoom jank and FPS;
- process RSS / memory pressure;
- process death + recovery;
- battery/network impact during map/offline download;
- storage-near-full behavior;
- multipage OCR and large-document import;
- large backup/restore with media;
- real browser localStorage quota/recovery.

AppLab/Maestro remains the preferred runtime harness. This repository keeps
stable flows and data policies but does not invent device measurements when no
device harness result exists.

## Non-AI freeze

This is the control baseline for STEP 17. AI work must report delta for:
APK size, installed size, RAM peak, cold start, battery, first-use download,
latency and throughput relative to this non-AI release.
