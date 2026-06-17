import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/camper_place.dart';

class PersonalMapMarker {
  const PersonalMapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.icon,
    this.color,
  });

  final String id;
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color? color;
}

class MapMarkerMapper {
  const MapMarkerMapper();

  Marker buildPoiMarker(
    CamperPlace poi, {
    required bool selected,
    VoidCallback? onTap,
  }) {
    return Marker(
      key: ValueKey(poiMarkerId(poi)),
      point: LatLng(poi.latitude, poi.longitude),
      width: selected ? 52 : 40,
      height: selected ? 52 : 40,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.gold : AppColors.surface,
            border: Border.all(
              color:
                  selected ? AppColors.text : _colorForCategory(poi.category),
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: selected ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _iconForCategory(poi.category),
            color: selected ? AppColors.night : _colorForCategory(poi.category),
            size: selected ? 28 : 22,
          ),
        ),
      ),
    );
  }

  Marker buildPersonalMarker(
    PersonalMapMarker marker, {
    VoidCallback? onTap,
  }) {
    return Marker(
      key: ValueKey('personal:${marker.id}'),
      point: LatLng(marker.latitude, marker.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: marker.color ?? AppColors.surfaceSoft,
            border: Border.all(color: AppColors.text, width: 2),
          ),
          child: Icon(marker.icon, color: AppColors.text, size: 20),
        ),
      ),
    );
  }

  IconData iconForCategory(String category) => _iconForCategory(category);

  Color colorForCategory(String category) => _colorForCategory(category);

  static String poiMarkerId(CamperPlace poi) {
    return '${poi.name}|${poi.latitude}|${poi.longitude}|${poi.category}';
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'camping':
        return Icons.cabin_outlined;
      case 'parcheggio':
        return Icons.local_parking_outlined;
      case 'acqua':
        return Icons.water_drop_outlined;
      case 'scarico':
        return Icons.delete_outline;
      case 'gpl':
        return Icons.local_gas_station_outlined;
      case 'assistenza':
        return Icons.build_outlined;
      case 'sosta':
      default:
        return Icons.rv_hookup;
    }
  }

  static Color _colorForCategory(String category) {
    switch (category) {
      case 'camping':
        return AppColors.forest;
      case 'parcheggio':
        return AppColors.text;
      case 'acqua':
        return AppColors.gold;
      case 'scarico':
        return Colors.blueGrey;
      case 'gpl':
        return Colors.deepOrange;
      case 'assistenza':
        return Colors.redAccent;
      case 'sosta':
      default:
        return AppColors.moss;
    }
  }
}

List<Marker> buildClusterablePoiMarkers({
  required List<CamperPlace> places,
  required MapMarkerMapper mapper,
  CamperPlace? selectedPlace,
  required void Function(CamperPlace place) onTap,
}) {
  return [
    for (final place in places)
      if (selectedPlace == null ||
          MapMarkerMapper.poiMarkerId(place) !=
              MapMarkerMapper.poiMarkerId(selectedPlace))
        mapper.buildPoiMarker(
          place,
          selected: false,
          onTap: () => onTap(place),
        ),
  ];
}
