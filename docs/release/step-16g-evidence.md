# Step 16G — Release Core Evidence Bundle

Certified app commit: `e88d586fc41e31c5175050f7934a383e5e480c1d`

## Automated quality

- Flutter CI run: `37012499351`
- Result: SUCCESS
- `flutter analyze`: PASS
- Full `flutter test`: 113/113 PASS

## Platform release builds

Release Core Platform Builds run: `37012499216`

### Android

- Result: PASS
- Target: ARM64 release APK
- File: `app-arm64-v8a-release.apk`
- File size: `48,029,264` bytes (~45.8 MiB)
- 80 MiB optimization threshold: PASS
- Artifact: `camperboss-arm64-release-apk`
- Artifact ID: `11229115224`
- Uploaded artifact size: `48,029,428` bytes
- `android:allowBackup="false"`: PASS
- `android:usesCleartextTraffic="false"`: PASS

### iOS

- Result: PASS
- Build: release, device target, no codesign
- Runner.app: ~82 MiB
- Flutter build report: 85.3 MB

### Web

- Result: PASS
- Release bundle: ~43 MiB
- `build/web/index.html`: present

## Functional repair chain

- Step 16D: Core Functional Repair — complete
- Step 16E: Offline & System Integration — complete
- Step 16F: UX & Product Polish — complete
- Step 16G: automated certification — complete

## Verdict

Automated evidence: **CERTIFIED**.

Production release remains **BLOCKED** only by manual/runtime evidence that CI cannot truthfully provide:

1. install the release APK on a physical Android device;
2. download a MapLibre region;
3. relaunch CamperBoss;
4. disable network connectivity;
5. verify the downloaded region reopens and remains usable;
6. complete Android/iPhone/Web device QA from the Release Core checklist.

No Step 17 work should be promoted until those manual gates pass.
