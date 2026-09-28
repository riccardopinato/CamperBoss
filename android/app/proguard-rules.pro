# google_mlkit_text_recognition references optional script-specific ML Kit
# recognizers from its Android bridge. CamperBoss currently uses the bundled
# Latin recognizer only, so these optional classes are intentionally absent.
# Suppress R8 missing-class diagnostics for those unreachable branches.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
