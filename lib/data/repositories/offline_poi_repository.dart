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
  }) : _collection =
            collection ?? LocalJsonCollection('camperboss.offline_poi');

  final LocalJsonCollection _collection;

  @override
  Stream<List<CamperPlace>> watchInBounds(
    GeoBounds bounds,
    Set<String> categories,
  ) async* {
    final places = await listAll();
    yield places
        .where((place) =>
            categories.isEmpty || categories.contains(place.category))
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
    final normalizedPackageId = packageId.trim();
    if (normalizedPackageId.isEmpty) {
      throw const FormatException('POI package id is required');
    }

    final decoded = jsonDecode(source);
    final places = _parsePlaces(normalizedPackageId, decoded);
    if (places.isEmpty) {
      throw const FormatException('POI package does not contain valid POI');
    }

    final nextPackageRows = <Map<String, Object?>>[];
    final ids = <String>{};
    for (final place in places) {
      final id = place.id ??
          [
            place.packageId,
            place.name,
            place.latitude.toString(),
            place.longitude.toString(),
          ].join(':');
      if (!ids.add(id)) {
        throw const FormatException('POI package contains duplicate ids');
      }
      nextPackageRows.add({...place.toMap(), 'id': id});
    }

    final current = await _collection.listRows();
    final next = <Map<String, Object?>>[
      for (final row in current)
        if (row['package_id'] != normalizedPackageId) row,
      ...nextPackageRows,
    ];
    await _collection.replaceRows(next);
    return places.length;
  }

  @override
  Future<void> removePackage(String packageId) async {
    final rows = await _collection.listRows();
    final next = rows
        .where((row) => row['package_id'] != packageId)
        .toList(growable: false);
    await _collection.replaceRows(next);
  }

  List<CamperPlace> _parsePlaces(String packageId, Object? decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) =>
              _placeFromMap(packageId, Map<String, Object?>.from(item)))
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

    final latitudeRaw = map['latitude'];
    final longitudeRaw = map['longitude'];
    if (latitudeRaw is! num || longitudeRaw is! num) {
      throw const FormatException('POI coordinates are required');
    }
    final latitude = latitudeRaw.toDouble();
    final longitude = longitudeRaw.toDouble();
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('POI coordinates are invalid');
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
      rating: map['rating']?.toString() ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      latitude: latitude,
      longitude: longitude,
      address: street ?? address,
      city: map['city'] as String?,
      description: map['description'] as String?,
      services: _serviceList(map['services']),
      source: map['source'] as String?,
      updatedAt: DateTime.tryParse(
        (map['updatedAt'] ?? map['updated_at'])?.toString() ?? '',
      ),
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
    if (services is List) {
      return services.map((item) => item.toString()).toList(growable: false);
    }
    if (services is Map) {
      return services.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toList(growable: false);
    }
    return const [];
  }
}
