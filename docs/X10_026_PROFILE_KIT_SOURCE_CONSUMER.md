# X10-026 — Pinned internal copy of pure-Dart profile kit (CamperBoss)

Factory baseline Core@c5adc147046beb7024629466d10eeb799c3c2619. Source: internal App Factory X10-021 `factory_profile_kit` v0.1.0 from `riccardopinato/Idee-app-Archivi-riferimenti@1d1a8628e25f58b788b013cf6955763d00363cdc`, `19-APP-FACTORY-10X/flutter_kits/profile/lib/factory_profile_kit.dart`.

CamperBoss's existing supply-chain guard (`tool/ci/release_guard.py`) explicitly rejects Git dependencies. We therefore **do not weaken the guard or add a dependency**. This source pilot vendors one unmodified pure-Dart source file as an INTERNAL_DONOR with immutable provenance under `lib/factory_kits/profile/`, and tests the actual file in CamperBoss Flutter CI. Future updates require a reviewed source hash/delta and new consumer checks. No new store, login, UI, permission, analytics, cloud or native APIs; no existing user data touched.

**CamperBoss product roadmap constraint:** STEP16 remains BLOCKED, no CURRENT step authorized. This is a **draft** and should not merge on CI alone. Completion of X10-026 also needs an independent Anna's Diary consumer, rollback receipts, native/physical checks where relevant and explicit Golden admission decision. Removing the one vendored source + test entirely reverts this source-only pilot; no user data rollback needed.

Source ownership is internal; this is scoped copying for a local compatibility test, not a certified Golden or public package release.
