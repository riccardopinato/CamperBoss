import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:camperboss/core/services/poi_package_installer.dart';
import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/data/repositories/download_record_repository.dart';
import 'package:camperboss/data/repositories/installed_resource_repository.dart';
import 'package:camperboss/data/repositories/offline_manifest_repository.dart';
import 'package:camperboss/data/repositories/offline_poi_repository.dart';
import 'package:camperboss/data/repositories/poi_package_state_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifest rejects package destinations outside offline root', () {
    final manifest = DownloadManifest(
      schemaVersion: 1,
      updatedAt: DateTime.utc(2026, 10, 6),
      packages: const [
        DownloadablePackage(
          id: 'unsafe',
          type: DownloadPackageType.poiDatabase,
          title: 'Unsafe',
          description: '',
          version: '1',
          url: 'https://downloads.example.test/unsafe.json',
          fileName: 'unsafe.json',
          fileSizeBytes: 1,
          expectedSha256: '',
          requiresWifiByDefault: true,
          destinationDirectory: '../databases',
        ),
      ],
    );

    expect(
      () => manifest.validate(allowedHosts: {'downloads.example.test'}),
      throwsFormatException,
    );
  });

  test('activates verified POI package and persists provenance', () async {
    final temp = await Directory.systemTemp.createTemp('camperboss-poi-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File(temp.path + '/poi.json')
      ..writeAsStringSync('''
[
  {
    "id":"one",
    "name":"Area camper",
    "category":"camperArea",
    "latitude":45.0,
    "longitude":11.0
  }
]
''');

    final store = MemoryKeyValueStore();
    final poi = LocalOfflinePoiRepository(
      collection: LocalJsonCollection('poi', store: store),
    );
    final states = LocalPoiPackageStateRepository(
      collection: LocalJsonCollection('states', store: store),
    );
    final manifest = await _manifestRepository(store, file);
    final installed = _MemoryInstalledRepository();
    final records = _MemoryDownloadRepository();
    final record = _record(file.path);
    await records.saveRecord(record);

    final installer = PoiPackageInstaller(
      poiRepository: poi,
      stateRepository: states,
      manifestRepository: manifest,
      installedRepository: installed,
      downloadRepository: records,
    );

    await installer.install(record, file);

    expect(await poi.loadPackage('italy-poi'), hasLength(1));
    final state = await states.find('italy-poi');
    expect(state?.license, 'ODbL-1.0');
    expect(state?.attribution, 'OpenStreetMap contributors');
  });

  test('activation rejects legacy POI metadata without checksum', () async {
    final temp = await Directory.systemTemp.createTemp('camperboss-poi-legacy-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File(temp.path + '/legacy.json')
      ..writeAsStringSync('[{"id":"one","name":"Legacy","category":"parking","latitude":45.0,"longitude":11.0}]');
    final store = MemoryKeyValueStore();
    final manifestRepository = LocalOfflineManifestRepository(
      cacheCollection: LocalJsonCollection('manifest', store: store),
      allowedHosts: {'downloads.example.test'},
    );
    await manifestRepository.cacheManifest(
      DownloadManifest(
        schemaVersion: 1,
        updatedAt: DateTime.utc(2026, 10, 6),
        packages: const [
          DownloadablePackage(
            id: 'italy-poi',
            type: DownloadPackageType.poiDatabase,
            title: 'Legacy POI',
            description: '',
            version: '1',
            url: 'https://downloads.example.test/legacy.json',
            fileName: 'legacy.json',
            fileSizeBytes: 1,
            expectedSha256: '',
            requiresWifiByDefault: true,
            destinationDirectory: 'offline/poi',
            metadata: {
              'region': 'Italy',
              'license': 'ODbL-1.0',
              'attribution': 'OpenStreetMap contributors',
              'source': 'Legacy catalog',
            },
          ),
        ],
      ),
    );
    final records = _MemoryDownloadRepository();
    final record = _record(file.path);
    await records.saveRecord(record);
    final poi = LocalOfflinePoiRepository(
      collection: LocalJsonCollection('poi', store: store),
    );
    final installer = PoiPackageInstaller(
      poiRepository: poi,
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      manifestRepository: manifestRepository,
      installedRepository: _MemoryInstalledRepository(),
      downloadRepository: records,
    );

    await expectLater(installer.install(record, file), throwsFormatException);
    expect(await poi.loadPackage('italy-poi'), isEmpty);
  });
  test('invalid update keeps previously activated package intact', () async {
    final temp = await Directory.systemTemp.createTemp('camperboss-poi-bad-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File(temp.path + '/bad.json')
      ..writeAsStringSync('{"invalid":true}');

    final store = MemoryKeyValueStore();
    final poi = LocalOfflinePoiRepository(
      collection: LocalJsonCollection('poi', store: store),
    );
    await poi.importPackageFromJson('italy-poi', '''
[
  {
    "id":"old",
    "name":"Old",
    "category":"parking",
    "latitude":45.0,
    "longitude":11.0
  }
]
''');
    final records = _MemoryDownloadRepository();
    final record = _record(file.path);
    await records.saveRecord(record);
    final installer = PoiPackageInstaller(
      poiRepository: poi,
      stateRepository: LocalPoiPackageStateRepository(
        collection: LocalJsonCollection('states', store: store),
      ),
      manifestRepository: await _manifestRepository(store, file),
      installedRepository: _MemoryInstalledRepository(),
      downloadRepository: records,
    );

    await expectLater(installer.install(record, file), throwsFormatException);

    final current = await poi.loadPackage('italy-poi');
    expect(current.single.id, 'old');
  });
}

Future<LocalOfflineManifestRepository> _manifestRepository(
  MemoryKeyValueStore store,
  File file,
) async {
  final bytes = file.readAsBytesSync();
  final checksum = sha256.convert(bytes).toString();
  final repository = LocalOfflineManifestRepository(
    cacheCollection: LocalJsonCollection('manifest', store: store),
    allowedHosts: {'downloads.example.test'},
  );
  await repository.cacheManifest(
    DownloadManifest(
      schemaVersion: 1,
      updatedAt: DateTime.utc(2026, 10, 3),
      packages: [
        DownloadablePackage(
          id: 'italy-poi',
          type: DownloadPackageType.poiDatabase,
          title: 'Italy POI',
          description: '',
          version: '1',
          url: 'https://downloads.example.test/italy.json',
          fileName: 'italy.json',
          fileSizeBytes: bytes.length,
          expectedSha256: checksum,
          requiresWifiByDefault: true,
          destinationDirectory: 'offline/poi',
          metadata: const {
            'region': 'Italy',
            'license': 'ODbL-1.0',
            'attribution': 'OpenStreetMap contributors',
            'source': 'Configured catalog',
          },
        ),
      ],
    ),
  );
  return repository;
}

DownloadRecord _record(String path) {
  final now = DateTime.utc(2026, 10, 3);
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final checksum = sha256.convert(bytes).toString();
  return DownloadRecord(
    packageId: 'italy-poi',
    taskId: 'task',
    type: DownloadPackageType.poiDatabase,
    title: 'Italy POI',
    version: '1',
    fileName: 'italy.json',
    localPath: path,
    status: DownloadStatus.verifying,
    downloadedBytes: bytes.length,
    totalBytes: bytes.length,
    expectedSha256: checksum,
    installedSha256: '',
    createdAt: now,
    updatedAt: now,
  );
}

class _MemoryInstalledRepository implements InstalledResourceRepository {
  final resources = <InstalledResource>[];

  @override
  Future<void> delete(String packageId) async {
    resources.removeWhere((item) => item.packageId == packageId);
  }

  @override
  Future<InstalledResource?> findByPackageId(String packageId) async {
    for (final item in resources) {
      if (item.packageId == packageId) return item;
    }
    return null;
  }

  @override
  Future<List<InstalledResource>> listAll() async => [...resources];

  @override
  Future<ReconciliationReport> reconcile() async =>
      const ReconciliationReport();

  @override
  Future<void> upsert(InstalledResource resource) async {
    await delete(resource.packageId);
    resources.add(resource);
  }

  @override
  Stream<List<InstalledResource>> watchAll() async* {
    yield [...resources];
  }
}

class _MemoryDownloadRepository implements DownloadRecordRepository {
  final records = <DownloadRecord>[];

  @override
  Future<void> deleteRecord(String packageId) async {
    records.removeWhere((item) => item.packageId == packageId);
  }

  @override
  Future<DownloadRecord?> getRecord(String packageId) async {
    for (final item in records) {
      if (item.packageId == packageId) return item;
    }
    return null;
  }

  @override
  Future<DownloadRecord?> getRecordByTaskId(String taskId) async {
    for (final item in records) {
      if (item.taskId == taskId) return item;
    }
    return null;
  }

  @override
  Future<List<DownloadRecord>> listRecords() async => [...records];

  @override
  Future<void> saveRecord(DownloadRecord record) async {
    await deleteRecord(record.packageId);
    records.add(record);
  }
}
