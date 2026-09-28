import 'dart:math' as math;

import '../../../data/models/camper_place.dart';

class MapLibrePoiCluster {
  const MapLibrePoiCluster({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.places,
  });

  final String id;
  final double latitude;
  final double longitude;
  final List<CamperPlace> places;

  int get count => places.length;
  bool get isCluster => count > 1;
  CamperPlace? get singlePlace => count == 1 ? places.single : null;
}

class MapLibrePoiClusterer {
  const MapLibrePoiClusterer();

  List<MapLibrePoiCluster> cluster({
    required List<CamperPlace> places,
    required double zoom,
  }) {
    if (places.isEmpty) return const [];

    final cellDegrees = _cellSizeDegrees(zoom);
    final buckets = <String, List<CamperPlace>>{};

    for (final place in places) {
      final x = (place.longitude / cellDegrees).floor();
      final y = (place.latitude / cellDegrees).floor();
      final key = '$x:$y';
      buckets.putIfAbsent(key, () => <CamperPlace>[]).add(place);
    }

    final clusters = <MapLibrePoiCluster>[];
    for (final entry in buckets.entries) {
      final bucket = entry.value;
      final latitude =
          bucket.fold<double>(0, (sum, item) => sum + item.latitude) /
              bucket.length;
      final longitude =
          bucket.fold<double>(0, (sum, item) => sum + item.longitude) /
              bucket.length;

      bucket.sort((a, b) {
        final aId = a.id ?? '${a.name}|${a.latitude}|${a.longitude}';
        final bId = b.id ?? '${b.name}|${b.latitude}|${b.longitude}';
        return aId.compareTo(bId);
      });

      clusters.add(
        MapLibrePoiCluster(
          id: '${entry.key}:${bucket.length}',
          latitude: latitude,
          longitude: longitude,
          places: List<CamperPlace>.unmodifiable(bucket),
        ),
      );
    }

    clusters.sort((a, b) => a.id.compareTo(b.id));
    return List<MapLibrePoiCluster>.unmodifiable(clusters);
  }

  double _cellSizeDegrees(double zoom) {
    final normalized = (zoom - 8).clamp(0.0, 8.0);
    final size = 0.42 / math.pow(2, normalized);
    return size.clamp(0.0025, 0.42).toDouble();
  }
}
