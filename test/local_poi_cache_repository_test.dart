import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/data/models/offline_map_models.dart';
import 'package:camperboss/data/repositories/installed_resource_repository.dart';
import 'package:camperboss/data/repositories/local_poi_cache_repository.dart';
import 'package:camperboss/data/repositories/offline_map_repository.dart';
import 'package:camperboss/data/repositories/offline_poi_repository.dart';
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

  test('offline POI repository imports JSON and filters by bounds', () async {
    final repository = LocalOfflinePoiRepository(
      collection: LocalJsonCollection(
        'offline.poi.test',
        store: MemoryKeyValueStore(),
      ),
    );

    final count = await repository.importPackageFromJson('italy-north-poi', '''
[
  {
    "id": "area-1",
    "name": "Area Lago",
    "category": "camperArea",
    "type": "Area sosta",
    "latitude": 45.6,
    "longitude": 10.6,
    "city": "Peschiera",
    "services": {"water": true, "waste": true},
    "source": "fixture"
  },
  {
    "id": "gpl-1",
    "name": "GPL Ovest",
    "category": "lpg",
    "type": "GPL",
    "latitude": 44.1,
    "longitude": 8.9
  }
]
''');

    expect(count, 2);
    final visible = await repository.watchInBounds(
      const GeoBounds(south: 45, west: 10, north: 46, east: 11),
      {'sosta'},
    ).first;
    expect(visible, hasLength(1));
    expect(visible.single.name, 'Area Lago');
    expect(visible.single.services, ['water', 'waste']);
  });

  test('offline POI import rolls back previous package on invalid format',
      () async {
    final repository = LocalOfflinePoiRepository(
      collection: LocalJsonCollection(
        'offline.poi.rollback.test',
        store: MemoryKeyValueStore(),
      ),
    );

    await repository.importPackageFromJson('pkg', '''
[
  {
    "name": "Area Lago",
    "category": "camperArea",
    "type": "Area sosta",
    "latitude": 45.6,
    "longitude": 10.6
  }
]
''');

    expect(
      () => repository.importPackageFromJson('pkg', '{"bad": true}'),
      throwsFormatException,
    );
    expect(await repository.loadPackage('pkg'), hasLength(1));
  });

  test('offline map repository activates only openable installed PMTiles',
      () async {
    final store = MemoryKeyValueStore();
    final installed = _MemoryInstalledResourceRepository([
      InstalledResource(
        packageId: 'italy_north_2026-06',
        type: DownloadPackageType.map,
        version: '2026.06',
        localPath: '/app/offline/italy_north_2026-06.pmtiles',
        fileSizeBytes: 2048,
        status: InstalledResourceStatus.installed,
        installedSha256: 'abc',
        lastVerifiedAt: DateTime.utc(2026, 6, 17),
      ),
    ]);
    final repository = LocalOfflineMapRepository(
      installedRepository: installed,
      store: store,
    );

    await repository.activateRegion('italy_north_2026-06');
    final source = await repository.resolveActiveSource();
    final regions = await repository.listInstalledRegions();

    expect(source?.type, MapSourceType.pmtiles);
    expect(source?.localPath, contains('.pmtiles'));
    expect(regions.single.active, isTrue);
  });

  test('offline map repository rejects missing or unreadable source', () async {
    final repository = LocalOfflineMapRepository(
      installedRepository: _MemoryInstalledResourceRepository([
        const InstalledResource(
          packageId: 'broken-map',
          type: DownloadPackageType.map,
          version: '2026.06',
          localPath: '/app/offline/broken.pmtiles',
          fileSizeBytes: 2048,
          status: InstalledResourceStatus.installed,
        ),
      ]),
      store: MemoryKeyValueStore(),
      canOpenSource: (_) => false,
    );

    expect(
      () => repository.activateRegion('broken-map'),
      throwsStateError,
    );
    expect(await repository.resolveActiveSource(), isNull);
  });
}

class _MemoryInstalledResourceRepository
    implements InstalledResourceRepository {
  _MemoryInstalledResourceRepository(this.resources);

  final List<InstalledResource> resources;

  @override
  Future<void> delete(String packageId) async {
    resources.removeWhere((resource) => resource.packageId == packageId);
  }

  @override
  Future<InstalledResource?> findByPackageId(String packageId) async {
    for (final resource in resources) {
      if (resource.packageId == packageId) return resource;
    }
    return null;
  }

  @override
  Future<List<InstalledResource>> listAll() async => List.of(resources);

  @override
  Future<ReconciliationReport> reconcile() async {
    return const ReconciliationReport();
  }

  @override
  Future<void> upsert(InstalledResource resource) async {
    await delete(resource.packageId);
    resources.add(resource);
  }

  @override
  Stream<List<InstalledResource>> watchAll() async* {
    yield List.of(resources);
  }
}
