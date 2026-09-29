import 'dart:convert';

import '../database/local_key_value_store.dart';

class MapViewportState {
  const MapViewportState({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final double latitude;
  final double longitude;
  final double zoom;

  Map<String, Object> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
      };

  factory MapViewportState.fromMap(Map<String, Object?> map) {
    return MapViewportState(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      zoom: (map['zoom'] as num).toDouble(),
    );
  }
}

class OfflineRegionViewport {
  const OfflineRegionViewport({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.zoom,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double zoom;
  final double south;
  final double west;
  final double north;
  final double east;

  Map<String, Object> toMap() => {
        'id': id,
        'name': name,
        'centerLatitude': centerLatitude,
        'centerLongitude': centerLongitude,
        'zoom': zoom,
        'south': south,
        'west': west,
        'north': north,
        'east': east,
      };

  factory OfflineRegionViewport.fromMap(Map<String, Object?> map) {
    return OfflineRegionViewport(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Offline area',
      centerLatitude: (map['centerLatitude'] as num).toDouble(),
      centerLongitude: (map['centerLongitude'] as num).toDouble(),
      zoom: (map['zoom'] as num).toDouble(),
      south: (map['south'] as num).toDouble(),
      west: (map['west'] as num).toDouble(),
      north: (map['north'] as num).toDouble(),
      east: (map['east'] as num).toDouble(),
    );
  }
}

class MapViewStateRepository {
  MapViewStateRepository({LocalKeyValueStore? store})
      : _store = store ?? createLocalKeyValueStore();

  static const _cameraKey = 'camperboss.map.camera.v2';
  static const _offlineRegionsKey = 'camperboss.map.offline_regions.v2';

  final LocalKeyValueStore _store;

  Future<MapViewportState?> loadCamera() async {
    final raw = await _store.read(_cameraKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return MapViewportState.fromMap(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await _store.remove(_cameraKey);
      return null;
    }
  }

  Future<void> saveCamera(MapViewportState state) {
    return _store.write(_cameraKey, jsonEncode(state.toMap()));
  }

  Future<List<OfflineRegionViewport>> listRegionViewports() async {
    final raw = await _store.read(_offlineRegionsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => OfflineRegionViewport.fromMap(
              Map<String, Object?>.from(item),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      await _store.remove(_offlineRegionsKey);
      return const [];
    }
  }

  Future<OfflineRegionViewport?> findRegion(String id) async {
    final regions = await listRegionViewports();
    for (final region in regions) {
      if (region.id == id) return region;
    }
    return null;
  }

  Future<void> saveRegion(OfflineRegionViewport region) async {
    final regions = await listRegionViewports();
    final updated = [
      for (final current in regions)
        if (current.id != region.id) current,
      region,
    ];
    await _store.write(
      _offlineRegionsKey,
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> deleteRegion(String id) async {
    final regions = await listRegionViewports();
    final updated = regions.where((item) => item.id != id).toList();
    if (updated.isEmpty) {
      await _store.remove(_offlineRegionsKey);
      return;
    }
    await _store.write(
      _offlineRegionsKey,
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
  }
}
