# STEP 16Q — AppLab runtime evidence — 2026-10-09

## Baseline

- App version under test: `0.2.2+18`.
- Target source SHA: `dca585edb4d057ffde5a4e623e82092683ce9b5a`.
- AppLab workflow run: `37928499130`.
- Package: `com.camperboss.camperboss`.
- Trusted verifier lanes: Android API 29 and Android API 35.
- Result: **PASS on both API levels**.

## Original P0

Release `0.2.1+17` failed at startup on API 35 with:

```text
PlatformException(
  invalid_icon,
  The resource app_notification could not be found...
)
```

Root cause:
- `flutter_local_notifications` resolves `app_notification` by resource name;
- release resource shrinking could remove the drawable because the runtime reference is string-based;
- AppShell also repeated notification initialization after the guarded process-wide bootstrap.

## Fix 0.2.2+18

- `android/app/src/main/res/raw/keep.xml` protects `@drawable/app_notification`.
- Duplicate AppShell notification initialization removed.
- Packaging regression test verifies drawable + keep rule + Dart resource-name contract.
- Release workflow verifies the notification resource in the built APK resource table.
- Maestro first-run sentinel follows Product Truth: Home cockpit is expected on a clean install; `Boss Readiness` is not required before sufficient real data exists.
- Navigation selectors use Flutter semantic tab nodes rather than localized exact-label text.

## Trusted runtime result

Both API 29 and API 35 completed, on the first Maestro attempt:

1. clean-state launch;
2. Home cockpit visible;
3. screenshot Home;
4. Tab 2/5 → Map;
5. screenshot Map;
6. Tab 3/5 → Trips;
7. screenshot Trips;
8. Tab 4/5 → Camper;
9. screenshot Camper;
10. Tab 5/5 → More;
11. screenshot More;
12. stop app;
13. relaunch without clearing state;
14. Home cockpit visible;
15. relaunch screenshot.

No `invalid_icon` / notification startup exception reappeared.

## Trusted evidence artifacts

### API 29

- Evidence artifact ID: `11616480056`.
- Artifact: `applab-camperboss-release-hotfix-api29-r3-2026-10-09-37928499130`.
- Artifact digest: `sha256:61ef247384091124849ca6bdd1f4e4aa8171e2dcb3800bfc0eb7d58d8c75d80e`.
- Build artifact digest: `sha256:45f0dada19180b329e01008ccec689d516aaab0a379c2d638e9fec9ab5999cf9`.

### API 35

- Evidence artifact ID: `11615389883`.
- Artifact: `applab-camperboss-release-hotfix-api35-r3-2026-10-09-37928499130`.
- Artifact digest: `sha256:f9e3fc35d97933e94e66a1f80c75cedf890e1a2577667df5866a63f30e0e4638`.
- Build artifact digest: `sha256:aa190baab42e2ebebffc8f501ac1a480907dbcb73e179e7d7e5f0255ffa3cfce`.

The trusted evidence manifests report `hashes_cover_all_evidence_files: true` and include Maestro logs, device logcat, UI/window dumps and screenshots.

## Certification truth

This closes the release-startup P0 and the top-level Android AppLab smoke for API 29/API 35.

It does **not** by itself certify:
- physical notification delivery;
- MapLibre cached-region use with real network disabled;
- storage-near-full behavior on a physical device;
- complete process-death/destructive recovery matrix;
- physical accessibility/performance/battery acceptance;
- real deployed Web acceptance;
- Play Internal distribution/signing evidence.

Those remain separate STEP 16Q / Release Reality gates. Therefore the global STEP 16Q verdict remains **BLOCKED by external/runtime-distribution evidence**, not CERTIFIED.
