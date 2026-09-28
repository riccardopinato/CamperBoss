# CamperBoss Release Core checklist

## Automated gates

- `flutter analyze`
- full `flutter test`
- Android ARM64 release APK build
- iOS release build without codesign
- Web release build
- translation catalog parity
- RevenueCat paywall tests
- offline-map Pro entitlement gate test
- Android backup/cleartext policy assertions
- Android APK size report with 80 MiB optimization warning
- iOS Runner.app size report
- Web bundle size report
- stable GitHub Pages build/deploy

## External configuration required before production

### RevenueCat

- Create/confirm entitlement id `pro`.
- Configure Android products in Google Play and attach them to the current Offering.
- Configure iOS products in App Store Connect and attach them to the same entitlement.
- Configure RevenueCat Web Billing / Stripe / Paddle for the Web key if web checkout is desired.
- Supply only public RevenueCat SDK keys through build-time dart defines.
- Verify purchase, cancellation, entitlement refresh and restore on Android/iOS.
- Verify web checkout separately; web restore is intentionally not offered by the app.

### Privacy

- Android automatic OS backup is disabled for private app data.
- Android cleartext traffic is disabled.
- iOS imported private document files are marked excluded from automatic cloud backup.
- User-triggered export/backup remains explicit and separate from OS backup.

## Device QA

Before production certification, run at least:

1. Android physical device: install release APK, first launch, locale switch, vehicle save, document import/OCR, reminder permission, route calculation, MapLibre preview, Pro paywall.
2. Android offline: download a Pro map region, relaunch, disable network, verify the downloaded region opens.
3. iPhone physical device: repeat document import, notifications, route and RevenueCat purchase/restore sandbox flows.
4. Web: verify navigation, persistence, language, route graceful degradation, RevenueCat web configuration state and Pages deep refresh.
5. AppLab or equivalent emulator pass for launch, persistence, lifecycle and no-network recovery when GitHub Actions runners are available.

## Production blockers

Do not mark Step 16 DONE until:

- RevenueCat products/Offering are configured with real sandbox/store products;
- at least one Android and one iOS purchase path has been exercised;
- physical offline-map reopen test passes;
- release builds are green again after GitHub Actions runner/billing availability is restored.
