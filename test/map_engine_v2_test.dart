import 'package:camperboss/core/services/maplibre_offline_region_manager.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/features/map/domain/maplibre_poi_clusterer.dart';
import 'package:camperboss/features/map/presentation/map_engine_v2_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MapLibre clusterer groups nearby POIs and separates them at high zoom',
      () {
    final places = List.generate(
      8,
      (index) => CamperPlace(
        id: 'poi-$index',
        name: 'POI $index',
        category: 'sosta',
        type: 'Sosta',
        distance: '',
        rating: '',
        tags: const [],
        latitude: 45.00 + index * 0.01,
        longitude: 11.00 + index * 0.01,
      ),
    );

    const clusterer = MapLibrePoiClusterer();
    final lowZoom = clusterer.cluster(places: places, zoom: 8);
    final highZoom = clusterer.cluster(places: places, zoom: 16);

    expect(lowZoom.length, lessThan(highZoom.length));
    expect(lowZoom.any((cluster) => cluster.isCluster), isTrue);
    expect(
      highZoom.fold<int>(0, (sum, cluster) => sum + cluster.count),
      places.length,
    );
  });

  test('offline viewport request normalizes bounds and adapts zoom', () {
    final request = mapLibreOfflineRequestForViewport(
      id: 'test',
      name: 'Test',
      south: 46.0,
      west: 12.0,
      north: 45.0,
      east: 11.0,
      currentZoom: 10.4,
    );

    expect(request.south, 45.0);
    expect(request.north, 46.0);
    expect(request.west, 11.0);
    expect(request.east, 12.0);
    expect(request.minZoom, 8.0);
    expect(request.maxZoom, greaterThanOrEqualTo(11.0));
  });

  testWidgets('Map Engine V2 preview can render without native map in tests',
      (tester) async {
    const places = [
      CamperPlace(
        id: 'one',
        name: 'Area Sosta',
        category: 'sosta',
        type: 'Sosta',
        distance: '',
        rating: '',
        tags: [],
        latitude: 45.60,
        longitude: 10.63,
      ),
      CamperPlace(
        id: 'two',
        name: 'Camping',
        category: 'camping',
        type: 'Camping',
        distance: '',
        rating: '',
        tags: [],
        latitude: 45.61,
        longitude: 10.64,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: MapEngineV2PreviewScreen(
          places: places,
          initialLatitude: 45.60,
          initialLongitude: 10.63,
          offlineManager: _UnsupportedOfflineManager(),
          renderMap: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map Engine V2'), findsOneWidget);
    expect(find.text('MapLibre vector POC'), findsOneWidget);
    expect(find.textContaining('2 POI'), findsOneWidget);
    expect(find.text('online renderer'), findsOneWidget);
  });
}

class _UnsupportedOfflineManager implements MapLibreOfflineRegionManager {
  const _UnsupportedOfflineManager();

  @override
  bool get isSupported => false;

  @override
  Future<void> clearAmbientCache() async {}

  @override
  Future<void> delete(String regionId) async {}

  @override
  Stream<MapLibreOfflineRegionSnapshot> download(
    MapLibreOfflineRegionRequest request,
  ) async* {}

  @override
  Future<List<MapLibreOfflineRegionSnapshot>> listRegions() async => const [];
}
