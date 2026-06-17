import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/features/map/presentation/map_marker_mapper.dart';
import 'package:camperboss/features/map/presentation/map_place_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('filters are applied before clustering', () {
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

    expect(filtered.map((place) => place.category), ['sosta', 'gpl']);
  });

  test('poi mapper builds marker with stable identity and coordinates', () {
    const mapper = MapMarkerMapper();
    final place = _place(name: 'Area Sosta Lago', category: 'sosta');

    final marker = mapper.buildPoiMarker(place, selected: false);

    expect((marker.key as ValueKey).value, MapMarkerMapper.poiMarkerId(place));
    expect(marker.point.latitude, place.latitude);
    expect(marker.point.longitude, place.longitude);
  });

  test('selected marker is excluded from clusterable markers', () {
    const mapper = MapMarkerMapper();
    final selected = _place(name: 'Area Sosta Lago', category: 'sosta');
    final markers = buildClusterablePoiMarkers(
      places: [
        selected,
        _place(name: 'Camping Bella Vista', category: 'camping'),
      ],
      mapper: mapper,
      selectedPlace: selected,
      onTap: (_) {},
    );

    expect(markers, hasLength(1));
    expect((markers.single.key as ValueKey).value,
        isNot(MapMarkerMapper.poiMarkerId(selected)));
  });

  test('clusterable markers do not include user or route placeholders', () {
    const mapper = MapMarkerMapper();
    final markers = buildClusterablePoiMarkers(
      places: [
        _place(
          name: 'Area Sosta Lago',
          category: 'sosta',
          latitude: 45.61,
          longitude: 10.64,
        ),
        _place(
          name: 'Camping Bella Vista',
          category: 'camping',
          latitude: 45.62,
          longitude: 10.65,
        ),
      ],
      mapper: mapper,
      onTap: (_) {},
    );

    expect(
        markers
            .every((marker) => marker.point != const LatLng(45.6049, 10.6351)),
        isTrue);
  });

  test('mapper can generate 1000 markers without duplicating ids', () {
    const mapper = MapMarkerMapper();
    final places = List.generate(
      1000,
      (index) => _place(
        name: 'POI $index',
        category: index.isEven ? 'sosta' : 'camping',
        latitude: 45.0 + index / 10000,
        longitude: 10.0 + index / 10000,
      ),
    );

    final markers = buildClusterablePoiMarkers(
      places: places,
      mapper: mapper,
      onTap: (_) {},
    );

    expect(markers, hasLength(1000));
    expect(
      markers.map((marker) => (marker.key as ValueKey).value).toSet(),
      hasLength(1000),
    );
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
