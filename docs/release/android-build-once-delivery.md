# Android Delivery — Build Once

CamperBoss uses a two-part delivery boundary:

1. GitHub Actions materializes the signing key from repository secrets and
   builds exactly one release AAB.
2. Fastlane receives the path to that already-built AAB and uploads that same
   artifact to the Play Internal track.

Fastlane is forbidden from rebuilding the Flutter application in the delivery
lane. The workflow publishes the AAB as an Actions artifact before upload so
the delivered binary can be matched to CI evidence.

The workflow is manual until Play Console credentials and the Android upload
key are configured. Default release status is draft; select completed only when
the internal testing release is ready for testers.
