# CamperBoss Release Core checklist

## Automated gates

- `flutter analyze`
- full `flutter test`
- Android ARM64 release APK build and 1-day downloadable artifact
- iOS release build without codesign
- Web release build
- translation catalog parity
- deferred-monetization/no-fake-checkout tests
- offline lost-task recovery and explicit retry-state coverage
- Android backup/cleartext policy assertions
- Android APK size report with 80 MiB optimization warning
- iOS Runner.app size report
- Web bundle size report
- stable GitHub Pages build/deploy

## Monetization boundary

- Production billing is intentionally deferred.
- No RevenueCat or other billing SDK is required by Release Core.
- No fake plans, fake prices or dead purchase CTA may be reachable in the UI.
- Keep the entitlement abstraction provider-neutral for a future monetization step.
- Do not gate existing core/offline functionality until a monetization model is explicitly approved.

## Privacy

- Android automatic OS backup is disabled for private app data.
- Android cleartext traffic is disabled.
- iOS imported private document files are marked excluded from automatic cloud backup.
- User-triggered export/backup remains explicit and separate from OS backup.

## Device QA

Before production certification, run at least:

1. Android physical device: install release APK, first launch, locale switch, vehicle save, document import/OCR, reminder permission, route calculation and MapLibre preview.
2. Android offline: download a map region, relaunch, disable network and verify the downloaded region opens.
3. iPhone physical device: repeat document import, notifications, routing and offline-map lifecycle checks.
4. Web: verify navigation, persistence, language, route graceful degradation and Pages deep refresh.
5. AppLab or equivalent emulator pass for launch, persistence, lifecycle and no-network recovery when GitHub Actions runners are available.

## Production blockers

Do not mark Step 16 DONE until:

- physical offline-map reopen test passes;
- final device/AppLab QA passes;
- release analyze/test/build gates are green again after GitHub Actions runner availability is restored.
