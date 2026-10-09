import 'package:camperboss/core/services/geocoding_service.dart';
import 'package:camperboss/core/services/maplibre_offline_region_manager.dart';
import 'package:camperboss/core/state/selected_location.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/features/map/presentation/map_engine_v2_preview_screen.dart';
import 'package:camperboss/features/map/presentation/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_localization.dart';

void main() {
  tearDown(() => selectedLocationController.value = null);

  testWidgets('map filters update the canonical POI list', (
    tester,
  ) async {
    selectedLocationController.value = const GeoLocationResult(
      name: 'Lake Garda',
      latitude: 45.6049,
      longitude: 10.6351,
      country: 'Italy',
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

    await pumpLocalizedHome(
      tester,
      home: Scaffold(
        body: SafeArea(
          child: MapScreen(
              places: places,
              mapLibreOfflineManager: const _UnsupportedOfflineManager(),
              renderMap: false,
              onOpenDirections: (_) async {
                directionsCount++;
              },
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('map-filter-camping')),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-filter-camping')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-filter-gpl')), findsOneWidget);
    expect(find.text('2 visible'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('map-filter-camping')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-filter-camping')));
    await tester.pumpAndSettle();
    expect(find.text('1 visible'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('map-filter-camping')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-filter-camping')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Camping Bella Vista'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Camping Bella Vista'), findsOneWidget);
    expect(find.text('GPL Service Ovest'), findsOneWidget);
    await tester.ensureVisible(find.text('Directions').first);
    await tester.tap(find.text('Directions').first);
    await tester.pumpAndSettle();
    expect(directionsCount, 1);
  });

  testWidgets('map does not invent distance without a real reference point', (
    tester,
  ) async {
    selectedLocationController.value = null;

    const places = [
      CamperPlace(
        name: 'Unlocated stop',
        category: 'camping',
        type: 'Camping',
        distance: '999 km',
        rating: '4.2',
        tags: [],
        latitude: 45.0,
        longitude: 10.0,
        source: 'Local POI package',
      ),
    ];

    await pumpLocalizedHome(
      tester,
      home: Scaffold(
        body: SafeArea(
          child: MapScreen(
              places: places,
              mapLibreOfflineManager: const _UnsupportedOfflineManager(),
              renderMap: false,
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Unlocated stop'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Unlocated stop'), findsOneWidget);
    expect(find.text('Camping - Camping'), findsOneWidget);
    expect(find.textContaining('999 km'), findsNothing);
  });

  testWidgets('main map uses the unified MapLibre surface', (tester) async {
    selectedLocationController.value = const GeoLocationResult(
      name: 'Lake Garda',
      latitude: 45.6049,
      longitude: 10.6351,
      country: 'Italy',
    );

    await pumpLocalizedHome(
      tester,
      home: MapScreen(
          places: const [],
          mapLibreOfflineManager: const _UnsupportedOfflineManager(),
          renderMap: false,
      ),
    );

    expect(find.byType(MapEngineV2PreviewScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('primary-maplibre-map')), findsOneWidget);
    expect(find.text('Map & offline'), findsOneWidget);
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
