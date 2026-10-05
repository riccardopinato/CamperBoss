import 'provider_trust_config.dart';

abstract final class MapEngineV2Config {
  static const String engineId = 'maplibre';

  /// Public online rendering style. Offline bulk download is intentionally
  /// separated and must use an explicitly approved/self-hosted style URL.
  static const String styleUrl =
      'https://tiles.openfreemap.org/styles/liberty';

  static String? get offlineStyleUrl =>
      ProviderTrustConfig.offlineMapStyleUri?.toString();

  static bool get isOfflineDownloadConfigured =>
      ProviderTrustConfig.isOfflineMapDownloadConfigured;

  static const String attribution =
      'OpenFreeMap © OpenMapTiles · Data © OpenStreetMap contributors';

  static const double initialZoom = 10.2;
  static const double minimumOfflineZoom = 8.0;

  static double offlineMaxZoomForSpan(double largestSpanDegrees) {
    if (largestSpanDegrees <= 0.08) return 16.0;
    if (largestSpanDegrees <= 0.25) return 15.0;
    if (largestSpanDegrees <= 0.70) return 14.0;
    return 13.0;
  }
}
