# CamperBoss Android delivery

This directory implements the project-specific candidate derived from the Master
Prompt v20 Fastlane standard.

The lane never builds the app. GitHub Actions builds the signed AAB once and
passes that exact path to Fastlane, preserving artifact provenance.

Required GitHub Actions secrets:

- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD
- PLAY_SERVICE_ACCOUNT_JSON

Optional repository variable:

- PLAY_PACKAGE_NAME (defaults to com.camperboss.camperboss)

Metadata/images/screenshots are prepared for later enablement. They are skipped
by default until the Play listing assets are reviewed.
