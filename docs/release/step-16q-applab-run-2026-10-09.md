# STEP 16Q — AppLab runtime evidence — 2026-10-09

## Baseline

- App version under test: `0.2.1+17`.
- Lane: Android API 35 / Pixel 7 Pro emulator.
- Build/install: PASS.
- Runtime: FAIL immediately after launch.
- API 29 lane: runner-cancelled before execution; no result may be inferred.

## P0 observed

Unhandled runtime exception:

```text
PlatformException(
  invalid_icon,
  The resource app_notification could not be found...
)
```

The source drawable exists at
`android/app/src/main/res/drawable/app_notification.xml`, but Flutter local
notifications resolves Android icons by resource name at runtime. Release
resource shrinking can therefore remove the drawable because the only product
references are string-based.

The shell also performed a second notification initialization after
`AppSystemServices.initialize()`. The process-wide bootstrap already catches
notification/plugin failures so they cannot block startup, but the duplicate
shell initialization was unguarded and could surface the same platform failure
as an unhandled async exception.

## Fix candidate 0.2.2+18

- Add `android/app/src/main/res/raw/keep.xml` with
  `tools:keep="@drawable/app_notification"`.
- Remove the duplicate notification initialization from `AppShell`; the shell
  only consumes the launch payload produced by the process-wide initialization.
- Add a regression contract test verifying the drawable, keep rule and Dart
  resource-name references remain aligned.
- Increment release identity to `0.2.2+18`.

## Certification truth

The API 35 failure means all downstream runtime lanes that did not execute
remain **SKIPPED**, not PASS: Maestro journey, network/offline, persistence,
process-death/recovery, storage, performance and visual journey.

The API 29 lane must be rerun independently.

This hotfix is not CERTIFIED until a release build demonstrates that
`app_notification` is present at runtime and the AppLab Android launch smoke
passes. Only then may the remaining STEP 16Q lanes run.
