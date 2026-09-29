import 'package:camperboss/core/services/geocoding_service.dart';
import 'package:camperboss/core/services/maplibre_offline_region_manager.dart';
import 'package:camperboss/core/state/selected_location.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/data/repositories/local_poi_cache_repository.dart';
import 'package:camperboss/features/map/presentation/map_engine_v2_preview_screen.dart';
import 'package:camperboss/features/map/presentation/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePoiCacheRepository implements PoiCacheRepository {
  FakePoiCacheRepository(this.snapshot);

  PoiCacheSnapshot snapshot;

  @override
  Future<PoiCacheSnapshot> clear() async {
    snapshot = const PoiCacheSnapshot(
      region: 'North Italy',
      itemCount: 0,
      sizeBytes: 0,
    );
    return snapshot;
  }

  @override
  Future<PoiCacheSnapshot> loadSnapshot() async => snapshot;

  @override
  Future<PoiCacheSnapshot> refresh({
    required String region,
    required List<CamperPlace> places,
  }) async {
    snapshot = PoiCacheSnapshot(
      region: region,
      itemCount: places.length,
      sizeBytes: 2048,
      updatedAt: DateTime.utc(2026, 6, 14, 10),
    );
    return snapshot;
  }
}

void main() {
  testWidgets('map filters update POI list and cache controls work', (
    tester,
  ) async {
    selectedLocationController.value = const GeoLocationResult(
      name: 'Lake Garda',
      latitude: 45.6049,
      longitude: 10.6351,
      country: 'Italy',
    );

    final cacheRepository = FakePoiCacheRepository(
      const PoiCacheSnapshot(
        region: 'North Italy',
        itemCount: 0,
        sizeBytes: 0,
      ),
    );

    var directionsCount = 0;
    const places = [
      CamperPlace(
        name: 'Camping Bella Vista',
        category: 'camping',
        type: 'Camping',
        distance: '12 km',
        rating: '4.6',
        tags: ['Docce'],
        latitude: 45.623,
        longitude: 10.728,
        address: 'Strada Panoramica 4',
        city: 'Lazise',
        services: ['Piazzole'],
        source: 'Dataset locale POI',
      ),
      CamperPlace(
        name: 'GPL Service Ovest',
        category: 'gpl',
        type: 'GPL',
        distance: '11 km',
        rating: '4.5',
        tags: ['GPL'],
        latitude: 45.547,
        longitude: 10.481,
        address: 'Tangenziale Ovest 21',
        city: 'Peschiera del Garda',
        services: ['GPL'],
        source: 'Dataset locale POI',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: MapScreen(
              places: places,
              cacheRepository: cacheRepository,
              mapLibreOfflineManager: const _UnsupportedOfflineManager(),
              renderMap: false,
              onOpenDirections: (_) async {
                directionsCount++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1300));
    await tester.pumpAndSettle();
    expect(find.text('Camping'), findsWidgets);
    expect(find.text('GPL'), findsWidgets);
    expect(find.text('2 visible'), findsOneWidget);

    await tester.ensureVisible(find.text('Camping'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camping'));
    await tester.pumpAndSettle();
    expect(find.text('1 visible'), findsOneWidget);

    await tester.ensureVisible(find.text('Refresh'));
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 items'), findsOneWidget);

    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 items'), findsOneWidget);

    await tester.ensureVisible(find.text('Camping'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camping'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Camping Bella Vista'), findsOneWidget);
    expect(find.text('GPL Service Ovest'), findsOneWidget);
    await tester.ensureVisible(find.text('Directions').first);
    await tester.tap(find.text('Directions').first);
    await tester.pumpAndSettle();
    expect(directionsCount, 1);
  });

  testWidgets('main map uses the unified MapLibre surface', (tester) async {
    selectedLocationController.value = const GeoLocationResult(
      name: 'Lake Garda',
      latitude: 45.6049,
      longitude: 10.6351,
      country: 'Italy',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          places: const [],
          cacheRepository: FakePoiCacheRepository(
            const PoiCacheSnapshot(
              region: 'North Italy',
              itemCount: 0,
              sizeBytes: 0,
            ),
          ),
          mapLibreOfflineManager: const _UnsupportedOfflineManager(),
          renderMap: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MapEngineV2PreviewScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('primary-maplibre-map')), findsOneWidget);
    expect(find.text('Mappa & offline'), findsOneWidget);
    expect(find.textContaining('PMTiles'), findsNothing);
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
