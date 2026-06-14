import 'dart:convert';

import '../database/local_json_collection.dart';
import '../database/local_key_value_store.dart';
import '../models/camper_place.dart';

class PoiCacheSnapshot {
  const PoiCacheSnapshot({
    required this.region,
    required this.itemCount,
    required this.sizeBytes,
    this.updatedAt,
  });

  final String region;
  final int itemCount;
  final int sizeBytes;
  final DateTime? updatedAt;

  String get sizeLabel {
    if (sizeBytes <= 0) return '0 B';
    if (sizeBytes < 1024) return '$sizeBytes B';
    return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
  }

  String get updatedLabel {
    final value = updatedAt;
    if (value == null) return 'Never';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

abstract interface class PoiCacheRepository {
  Future<PoiCacheSnapshot> loadSnapshot();
  Future<PoiCacheSnapshot> refresh({
    required String region,
    required List<CamperPlace> places,
  });
  Future<PoiCacheSnapshot> clear();
}

class LocalPoiCacheRepository implements PoiCacheRepository {
  LocalPoiCacheRepository({
    LocalJsonCollection? placesCollection,
    LocalKeyValueStore? store,
  })  : _placesCollection =
            placesCollection ?? LocalJsonCollection('camperboss.poi_cache'),
        _store = store ?? createLocalKeyValueStore();

  static const _metaKey = 'camperboss.poi_cache.meta';

  final LocalJsonCollection _placesCollection;
  final LocalKeyValueStore _store;

  @override
  Future<PoiCacheSnapshot> loadSnapshot() async {
    final rows = await _placesCollection.listRows();
    final metaRaw = await _store.read(_metaKey);
    if (metaRaw == null || metaRaw.isEmpty) {
      return PoiCacheSnapshot(
        region: 'North Italy',
        itemCount: rows.length,
        sizeBytes: _estimateSize(rows),
      );
    }

    final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
    return PoiCacheSnapshot(
      region: (meta['region'] as String?) ?? 'North Italy',
      itemCount: rows.length,
      sizeBytes: _estimateSize(rows),
      updatedAt: DateTime.tryParse(meta['updated_at'] as String? ?? ''),
    );
  }

  @override
  Future<PoiCacheSnapshot> refresh({
    required String region,
    required List<CamperPlace> places,
  }) async {
    await clear();
    for (final place in places) {
      await _placesCollection.saveRow(place.toMap());
    }

    final now = DateTime.now();
    await _store.write(
      _metaKey,
      jsonEncode({
        'region': region,
        'updated_at': now.toIso8601String(),
      }),
    );

    final rows = await _placesCollection.listRows();
    return PoiCacheSnapshot(
      region: region,
      itemCount: rows.length,
      sizeBytes: _estimateSize(rows),
      updatedAt: now,
    );
  }

  @override
  Future<PoiCacheSnapshot> clear() async {
    final rows = await _placesCollection.listRows();
    for (final row in rows) {
      final id = row['id'] as int?;
      if (id != null) {
        await _placesCollection.deleteRow(id);
      }
    }
    await _store.remove(_metaKey);
    return const PoiCacheSnapshot(
      region: 'North Italy',
      itemCount: 0,
      sizeBytes: 0,
    );
  }

  int _estimateSize(List<Map<String, Object?>> rows) {
    return utf8.encode(jsonEncode(rows)).length;
  }
}
