import 'package:camperboss/core/services/app_download_manager.dart';
import 'package:camperboss/core/services/poi_catalog_service.dart';
import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/data/repositories/offline_manifest_repository.dart';
import 'package:camperboss/data/repositories/poi_package_state_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const poiPackage = DownloadablePackage(
    id: 'italy-poi',
    type: DownloadPackageType.poiDatabase,
    title: 'Italy camper POI',
    description: 'Verified POI package',
    version: '1',
    url: 'https://downloads.example.test/italy.json',
    fileName: 'italy.json',
    fileSizeBytes: 100,
    expectedSha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    requiresWifiByDefault: true,
    destinationDirectory: 'offline/poi',
    metadata: {
      'region': 'Italy',
      'license': 'ODbL-1.0',
      'attribution': 'OpenStreetMap contributors',
      'source': 'Configured production catalog',
    },
  );

  test('unconfigured catalog is explicit and never invents packages', () async {
    final store = MemoryKeyValueStore();
    final service = PoiCatalogService(
      manifestRepository: LocalOfflineManifestRepository(
        cacheCollection: LocalJsonCollection('manifest', store: store),
      ),
      downloadManager: FakeDownloadManager(),
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      remoteConfigured: false,
    );

    final snapshot = await service.snapshot();

    expect(snapshot.remoteConfigured, isFalse);
    expect(snapshot.entries, isEmpty);
    expect(snapshot.message, contains('not configured'));
  });

  test('catalog exposes only validated POI packages and enqueues selected one',
      () async {
    final store = MemoryKeyValueStore();
    final manifestRepository = LocalOfflineManifestRepository(
      cacheCollection: LocalJsonCollection('manifest', store: store),
      allowedHosts: {'downloads.example.test'},
      remoteLoader: () async => DownloadManifest(
        schemaVersion: 1,
        updatedAt: DateTime.utc(2026, 10, 3),
        packages: const [
          poiPackage,
          DownloadablePackage(
            id: 'guide',
            type: DownloadPackageType.guide,
            title: 'Guide',
            description: '',
            version: '1',
            url: 'https://downloads.example.test/guide.json',
            fileName: 'guide.json',
            fileSizeBytes: 1,
            expectedSha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            requiresWifiByDefault: true,
            destinationDirectory: 'offline/guides',
          ),
        ],
      ).toJson(),
    );
    final manager = FakeDownloadManager();
    final service = PoiCatalogService(
      manifestRepository: manifestRepository,
      downloadManager: manager,
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      remoteConfigured: true,
    );

    final snapshot = await service.snapshot();
    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.region, 'Italy');

    await service.install('italy-poi');
    final records = await manager.watchDownloads().first;
    expect(records.single.packageId, 'italy-poi');
  });

  test('missing checksum prevents POI install before enqueue', () async {
    final store = MemoryKeyValueStore();
    final unverifiable = DownloadablePackage(
      id: 'unverifiable-poi',
      type: DownloadPackageType.poiDatabase,
      title: 'Unverifiable',
      description: '',
      version: '1',
      url: 'https://downloads.example.test/unverifiable.json',
      fileName: 'unverifiable.json',
      fileSizeBytes: 100,
      expectedSha256: '',
      requiresWifiByDefault: true,
      destinationDirectory: 'offline/poi',
      metadata: const {
        'region': 'Italy',
        'license': 'ODbL-1.0',
        'attribution': 'OpenStreetMap contributors',
        'source': 'test',
      },
    );
    final manifestRepository = LocalOfflineManifestRepository(
      cacheCollection: LocalJsonCollection('manifest', store: store),
      allowedHosts: {'downloads.example.test'},
      remoteLoader: () async => DownloadManifest(
        schemaVersion: 1,
        updatedAt: DateTime.utc(2026, 10, 6),
        packages: [unverifiable],
      ).toJson(),
    );
    final manager = FakeDownloadManager();
    final service = PoiCatalogService(
      manifestRepository: manifestRepository,
      downloadManager: manager,
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      remoteConfigured: true,
    );

    await expectLater(
      service.install('unverifiable-poi'),
      throwsFormatException,
    );
    expect(await manager.watchDownloads().first, isEmpty);
  });
  test('missing attribution prevents install before download is created',
      () async {
    final store = MemoryKeyValueStore();
    final bad = DownloadablePackage(
      id: 'bad-poi',
      type: DownloadPackageType.poiDatabase,
      title: 'Bad',
      description: '',
      version: '1',
      url: 'https://downloads.example.test/bad.json',
      fileName: 'bad.json',
      fileSizeBytes: 1,
      expectedSha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      requiresWifiByDefault: true,
      destinationDirectory: 'offline/poi',
      metadata: const {
        'region': 'Italy',
        'license': 'ODbL-1.0',
        'source': 'test',
      },
    );
    final manifestRepository = LocalOfflineManifestRepository(
      cacheCollection: LocalJsonCollection('manifest', store: store),
      allowedHosts: {'downloads.example.test'},
      remoteLoader: () async => DownloadManifest(
        schemaVersion: 1,
        updatedAt: DateTime.utc(2026, 10, 3),
        packages: [bad],
      ).toJson(),
    );
    final manager = FakeDownloadManager();
    final service = PoiCatalogService(
      manifestRepository: manifestRepository,
      downloadManager: manager,
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      remoteConfigured: true,
    );

    await expectLater(service.install('bad-poi'), throwsFormatException);
    expect(await manager.watchDownloads().first, isEmpty);
  });
}
