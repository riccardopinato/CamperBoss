import 'dart:convert';

import '../database/local_json_collection.dart';
import '../models/camper_place.dart';

abstract interface class PoiRepository {
  Stream<List<CamperPlace>> watchInBounds(
    GeoBounds bounds,
    Set<String> categories,
  );
  Future<List<CamperPlace>> listAll();
  Future<List<CamperPlace>> loadPackage(String packageId);
  Future<int> importPackageFromJson(String packageId, String source);
  Future<void> removePackage(String packageId);
}

class LocalOfflinePoiRepository implements PoiRepository {
  LocalOfflinePoiRepository({
    LocalJsonCollection? collection,
  }) : _collection = collection ?? LocalJsonCollection('camperboss.offline_poi');

  final LocalJsonCollection _collection;

  @override
  Stream<List<CamperPlace>> watchInBounds(
    GeoBounds bounds,
    Set<String> categories,
  ) async* {
    final places = await listAll();
    yield places
        .where((place) => categories.isEmpty || categories.contains(place.category))
        .where((place) => bounds.contains(place.latitude, place.longitude))
        .toList(growable: false);
  }

  @override
  Future<List<CamperPlace>> listAll() async {
    final rows = await _collection.listRows();
    return rows.map(CamperPlace.fromMap).toList(growable: false);
  }

  @override
  Future<List<CamperPlace>> loadPackage(String packageId) async {
    final places = await listAll();
    return places
        .where((place) => place.packageId == packageId)
        .toList(growable: false);
  }

  @override
  Future<int> importPackageFromJson(String packageId, String source) async {
    final decoded = jsonDecode(source);
    final places = _parsePlaces(packageId, decoded);
    if (places.isEmpty) {
      throw const FormatException('POI package does not contain valid POI');
    }
    await removePackage(packageId);
    for (final place in places) {
      await _collection.saveRow({
        ...place.toMap(),
        'id': place.id ?? '${place.packageId}:${place.name}:${place.latitude}:${place.longitude}',
      });
    }
    return places.length;
  }

  @override
  Future<void> removePackage(String packageId) async {
    final rows = await _collection.listRows();
    for (final row in rows) {
      if (row['package_id'] == packageId) {
        await _collection.deleteRow(row['id']);
      }
    }
  }

  List<CamperPlace> _parsePlaces(String packageId, Object? decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => _placeFromMap(packageId, Map<String, Object?>.from(item)))
          .toList(growable: false);
    }
    if (decoded is Map && decoded['type'] == 'FeatureCollection') {
      final features = decoded['features'] as List<dynamic>? ?? const [];
      return features
          .whereType<Map>()
          .map((feature) => _placeFromFeature(packageId, feature))
          .toList(growable: false);
    }
    throw const FormatException('Unsupported POI package format');
  }

  CamperPlace _placeFromMap(String packageId, Map<String, Object?> map) {
    final name = (map['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw const FormatException('POI name is required');
    }
    final category = map['category'] as String? ?? 'servicePoint';
    final street = map['street'] as String?;
    final address = map['address'] as String?;
    return CamperPlace(
      id: map['id']?.toString(),
      packageId: packageId,
      name: name,
      category: _normalizeCategory(category),
      type: map['type'] as String? ?? category,
      distance: '',
      rating: '',
      tags: (map['tags'] as List<dynamic>? ?? const []).cast<String>(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: street ?? address,
      city: map['city'] as String?,
      description: map['description'] as String?,
      services: _serviceList(map['services']),
      source: map['source'] as String?,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }

  CamperPlace _placeFromFeature(String packageId, Map feature) {
    final geometry = feature['geometry'] as Map?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (geometry?['type'] != 'Point' ||
        coordinates == null ||
        coordinates.length < 2) {
      throw const FormatException('Only Point GeoJSON POI are supported');
    }
    final properties = Map<String, Object?>.from(
      feature['properties'] as Map? ?? const {},
    );
    return _placeFromMap(packageId, {
      ...properties,
      'longitude': coordinates[0],
      'latitude': coordinates[1],
    });
  }

  String _normalizeCategory(String category) {
    return switch (category) {
      'camperArea' => 'sosta',
      'campsite' => 'camping',
      'parking' => 'parcheggio',
      'water' => 'acqua',
      'wasteDisposal' => 'scarico',
      'lpg' => 'gpl',
      'workshop' || 'servicePoint' => 'assistenza',
      _ => category,
    };
  }

  List<String> _serviceList(Object? services) {
    if (services is List) return services.cast<String>();
    if (services is Map) {
      return services.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toList(growable: false);
    }
    return const [];
  }
}
