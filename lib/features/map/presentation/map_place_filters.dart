import 'package:latlong2/latlong.dart';

import '../../../data/models/camper_place.dart';

const mapFilterLabels = <String, String>{
  'sosta': 'map_filter_stopover',
  'camping': 'map_filter_camping',
  'parcheggio': 'map_filter_parking',
  'acqua': 'map_filter_water',
  'scarico': 'map_filter_waste',
  'gpl': 'map_filter_lpg',
  'assistenza': 'map_filter_service',
};

List<CamperPlace> filterAndSortPlaces({
  required List<CamperPlace> places,
  required Set<String> activeFilters,
  required LatLng? selectedPoint,
  required Distance distance,
}) {
  final filtered =
      places.where((place) => activeFilters.contains(place.category)).toList();

  // Without a real user-selected/current position there is no truthful
  // distance ordering. Preserve package/provider order instead.
  if (selectedPoint == null) return filtered;

  filtered.sort(
    (a, b) => distance
        .as(
          LengthUnit.Kilometer,
          selectedPoint,
          LatLng(a.latitude, a.longitude),
        )
        .compareTo(
          distance.as(
            LengthUnit.Kilometer,
            selectedPoint,
            LatLng(b.latitude, b.longitude),
          ),
        ),
  );
  return filtered;
}
