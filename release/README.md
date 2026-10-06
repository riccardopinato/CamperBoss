# CamperBoss release identity and delivery

This directory contains source-controlled release identity only. It never stores
signing keys, service-account JSON, API keys or other credentials.

## Release identity

`pubspec.yaml` is the mobile version source of truth. The checked-in
`release_identity.json` is a reviewable monotonic ledger for release
candidates and must match the pubspec version exactly.

For every new store candidate:

1. move the current `versionCode` into `previousVersionCode`;
2. increment `versionCode` strictly;
3. update `versionName` according to semantic versioning;
4. update `pubspec.yaml` to the same `versionName+versionCode`;
5. run `python3 tool/ci/release_guard.py identity`.

## QA vs Play signing

Android QA release APKs may use the debug-signing fallback and are always
labelled QA-only artifacts. They are not eligible for Play upload.

The Play workflow sets the Gradle property `requireReleaseSigning=true`.
That path hard-fails unless the upload keystore has been materialized from
GitHub secrets and all signing fields are valid.

## Build once / upload same bytes

Google Play Internal Testing uses two jobs:

- **build** checks out an exact 40-character source SHA and produces one signed
  AAB;
- the AAB SHA-256 is recorded and the candidate is uploaded as a retained
  GitHub artifact;
- **deliver** downloads that exact artifact, verifies the SHA-256 again and
  calls Fastlane from `android/`;
- Fastlane only validates and uploads the supplied AAB. It contains no build
  command.

A successful build therefore does not imply a successful Play upload, and a
Play upload must never rebuild the candidate.

## Evidence

CI/release evidence is retained for 30 days and includes release identity,
coverage, dependency/license audit, secret scan, SAST, candidate SHA-256 and,
when credentials are available, Play Internal delivery evidence.
