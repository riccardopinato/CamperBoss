# STEP 16Q — Final Android/Web certification

Snapshot: 2026-10-05
Canonical active platforms: Android + Web
iOS: deferred / non-blocking

## Current verdict

**BLOCKED — EXTERNAL RUNTIME / STORE EVIDENCE**

The STEP 16 software scope is implemented through STEP 16Q, but CamperBoss is
not declared CERTIFIED until the external gates below have real evidence tied
to the same canonical source SHA.

## Automated/static preflight

The repository final-certification guard verifies:
- Android + Web are the only active platform release gates;
- iOS build/StoreKit/IAP are not required;
- release identity, supply-chain, secrets, SAST and provider trust gates exist;
- six localization catalogs exist;
- STEP 16P stress baseline and size budgets exist;
- final AppLab/Maestro flows exist;
- Android backup and cleartext protections remain enforced;
- Web uses Flutter hash routing under GitHub Pages rather than claiming
  server-side path rewrites.

## External gates still required

| Gate | Evidence required | Status |
| --- | --- | --- |
| Google Play Internal | signed build-once AAB, SHA-256 match, successful internal-track upload | BLOCKED |
| Android AppLab/device | first launch, CRUD, permissions, import/OCR, reminders, routing, process-death/recovery | BLOCKED |
| MapLibre no-network | approved offline provider, completed region, relaunch, network disabled, zoom/pan from cached region | BLOCKED |
| Accessibility | TalkBack, keyboard/focus where applicable, 200% text scale, visual contrast on real device | BLOCKED |
| Android performance | cold/warm start, map jank/FPS, RSS/memory pressure, battery observation, storage-near-full | BLOCKED |
| Web runtime | GitHub Pages candidate on canonical SHA, #/ deep-link refresh/back/forward, responsive widths, localStorage quota/recovery | BLOCKED |
| Visual assets | launcher icon, splash and store listing visual QA | BLOCKED |

## Web routing truth

GitHub Pages is a static host. CamperBoss therefore keeps Flutter's default hash
URL strategy for the current preview. Named routes are:

- `/`
- `/map`
- `/trips`
- `/camper`
- `/more`

In the deployed preview they are expected as hash URLs such as
`/CamperBoss/#/map`. This avoids claiming that GitHub Pages rewrites direct
server paths such as `/CamperBoss/map`.

## Certification rule

A build PASS or static preflight PASS is not a runtime certification. The final
verdict becomes `CERTIFIED` only after all applicable P0/P1 external gates
above are PASS on the same source SHA/artifact lineage.
