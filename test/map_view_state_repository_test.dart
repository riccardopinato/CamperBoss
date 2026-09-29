import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/repositories/map_view_state_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('persists map camera across repository instances', () async {
    final store = _MemoryStore();
    final first = MapViewStateRepository(store: store);

    await first.saveCamera(
      const MapViewportState(latitude: 45.4, longitude: 11.8, zoom: 12.5),
    );

    final restored = await MapViewStateRepository(store: store).loadCamera();
    expect(restored?.latitude, 45.4);
    expect(restored?.longitude, 11.8);
    expect(restored?.zoom, 12.5);
  });

  test('persists and deletes offline region viewport metadata', () async {
    final store = _MemoryStore();
    final repository = MapViewStateRepository(store: store);

    const region = OfflineRegionViewport(
      id: 'veneto',
      name: 'Veneto',
      centerLatitude: 45.4,
      centerLongitude: 11.8,
      zoom: 10,
      south: 44.8,
      west: 10.8,
      north: 46.2,
      east: 13.2,
    );

    await repository.saveRegion(region);
    expect((await repository.findRegion('veneto'))?.name, 'Veneto');

    await repository.deleteRegion('veneto');
    expect(await repository.findRegion('veneto'), isNull);
  });
}
