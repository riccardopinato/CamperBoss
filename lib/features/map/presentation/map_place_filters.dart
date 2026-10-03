import 'package:latlong2/latlong.dart';

import '../../../data/models/camper_place.dart';

const mapFilterLabels = <String, String>{
  'sosta': 'Sosta',
  'camping': 'Camping',
  'parcheggio': 'Parcheggio',
  'acqua': 'Acqua',
  'scarico': 'Scarico',
  'gpl': 'GPL',
  'assistenza': 'Assistenza',
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
