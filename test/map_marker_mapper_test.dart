import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/features/map/domain/maplibre_poi_clusterer.dart';
import 'package:camperboss/features/map/presentation/map_place_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('filters are applied before MapLibre clustering', () {
    final places = [
      _place(name: 'Area Sosta Lago', category: 'sosta', latitude: 45.6),
      _place(name: 'Camping Bella Vista', category: 'camping', latitude: 45.7),
      _place(name: 'GPL Service Ovest', category: 'gpl', latitude: 45.5),
    ];

    final filtered = filterAndSortPlaces(
      places: places,
      activeFilters: const {'sosta', 'gpl'},
      selectedPoint: const LatLng(45.6, 10.6),
      distance: const Distance(),
    );
    final clusters = const MapLibrePoiClusterer().cluster(
      places: filtered,
      zoom: 14,
    );

    expect(filtered.map((place) => place.category), ['sosta', 'gpl']);
    expect(clusters.expand((cluster) => cluster.places), hasLength(2));
  });

  test('MapLibre cluster identities stay stable and unique for large POI sets', () {
    final places = List.generate(
      1000,
      (index) => _place(
        name: 'POI $index',
        category: index.isEven ? 'sosta' : 'camping',
        latitude: 45.0 + index / 10000,
        longitude: 10.0 + index / 10000,
      ),
    );

    final clusters = const MapLibrePoiClusterer().cluster(
      places: places,
      zoom: 17,
    );

    expect(clusters.expand((cluster) => cluster.places), hasLength(1000));
    expect(clusters.map((cluster) => cluster.id).toSet(), hasLength(clusters.length));
  });
}

CamperPlace _place({
  required String name,
  required String category,
  double latitude = 45.6049,
  double longitude = 10.6351,
}) {
  return CamperPlace(
    name: name,
    category: category,
    type: category,
    distance: '1 km',
    rating: '4.5',
    tags: const ['tag'],
    latitude: latitude,
    longitude: longitude,
  );
}
