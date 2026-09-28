abstract final class MapEngineV2Config {
  static const String engineId = 'maplibre';
  static const String styleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  static const String attribution =
      'OpenStreetMap contributors - OpenFreeMap';

  static const double initialZoom = 10.2;
  static const double minimumOfflineZoom = 8.0;

  static double offlineMaxZoomForSpan(double largestSpanDegrees) {
    if (largestSpanDegrees <= 0.08) return 16.0;
    if (largestSpanDegrees <= 0.25) return 15.0;
    if (largestSpanDegrees <= 0.70) return 14.0;
    return 13.0;
  }
}
