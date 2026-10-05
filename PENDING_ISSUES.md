# CamperBoss — open release gates

This file is a compact pointer only. The authoritative backlog is `ROADMAP.md`.

Completed remediation groups in the current stacked release candidate:

- STEP 16J: heavy audit, Product Truth and governance baseline.
- STEP 16K: backup recovery, data safety and referential integrity.
- STEP 16L: Map/POI/offline Product Truth, truthful distance semantics, storage preflight and updated AppLab harness.
- STEP 16N software scope: localization/platform truth, iOS notification state, Web routing/branding and expanded local search implemented; runtime accessibility/Web evidence remains deferred to STEP 16Q; iOS is deferred out of the current release scope.

Current unresolved groups:

- STEP 16M: deterministic CI/CD, version/signing/build-once automation implemented; external Play Internal Testing evidence still required (upload key + service account + successful internal-track upload of the recorded AAB hash).
- STEP 16N: software scope implemented; Android/Web automated gates are the active release gates. TalkBack, 200% text scale, keyboard/focus, real-browser quota/back/deep-link and visual assets remain open. iOS runtime/build/IAP evidence is deferred and non-blocking.
- STEP 16O: security/privacy/provider/licensing boundaries and production POI/routing provider approval.
- STEP 16P: performance, memory, battery and large-data stress.
- STEP 16Q: final AppLab/device/Web certification, including physical MapLibre no-network proof.

Do not duplicate detailed issue tracking here.
