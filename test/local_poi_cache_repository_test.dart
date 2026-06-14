import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/data/repositories/local_poi_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('poi cache repository refreshes and clears local cache', () async {
    final store = MemoryKeyValueStore();
    final repository = LocalPoiCacheRepository(
      placesCollection: LocalJsonCollection('poi.cache.test', store: store),
      store: store,
    );

    const places = [
      CamperPlace(
        name: 'Area Sosta Lago',
        category: 'sosta',
        type: 'Sosta camper',
        distance: '8.4 km',
        rating: '4.8',
        tags: ['24h'],
        latitude: 45.6,
        longitude: 10.6,
      ),
      CamperPlace(
        name: 'GPL Service Ovest',
        category: 'gpl',
        type: 'GPL',
        distance: '11 km',
        rating: '4.5',
        tags: ['GPL'],
        latitude: 45.5,
        longitude: 10.4,
      ),
    ];

    final refreshed = await repository.refresh(
      region: 'North Italy',
      places: places,
    );
    expect(refreshed.itemCount, 2);
    expect(refreshed.region, 'North Italy');
    expect(refreshed.updatedAt, isNotNull);

    final loaded = await repository.loadSnapshot();
    expect(loaded.itemCount, 2);
    expect(loaded.sizeBytes, greaterThan(0));

    final cleared = await repository.clear();
    expect(cleared.itemCount, 0);
    expect((await repository.loadSnapshot()).itemCount, 0);
  });
}
