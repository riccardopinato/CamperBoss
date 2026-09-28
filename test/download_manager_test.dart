import 'dart:io';

import 'package:camperboss/core/providers/download_manager_provider.dart';
import 'package:camperboss/core/services/app_download_manager.dart';
import 'package:camperboss/core/services/download_file_verifier.dart';
import 'package:camperboss/core/services/storage_inspector.dart';
import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/data/repositories/installed_resource_repository.dart';
import 'package:camperboss/data/repositories/offline_manifest_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const package = DownloadablePackage(
    id: 'guide-demo',
    type: DownloadPackageType.guide,
    title: 'Guide demo',
    description: 'Small fixture',
    version: '2026.06',
    url: 'https://example.com/guide.pdf',
    fileName: 'guide.pdf',
    fileSizeBytes: 11,
    expectedSha256:
        'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
    requiresWifiByDefault: true,
    destinationDirectory: 'offline/guides',
  );

  test('parses and validates a versioned HTTPS manifest', () {
    const source = '''
{
  "schemaVersion": 1,
  "updatedAt": "2026-06-17T00:00:00Z",
  "packages": [
    {
      "id": "italy-north-map",
      "type": "map",
      "title": "Nord Italia",
      "version": "2026.06",
      "url": "https://downloads.camperboss.test/italy_north.pmtiles",
      "fileName": "italy_north.pmtiles",
      "fileSizeBytes": 0,
      "sha256": ""
    }
  ]
}
''';

    final manifest = DownloadManifest.fromJson(source);

    expect(manifest.schemaVersion, 1);
    expect(manifest.updatedAt.toUtc().year, 2026);
    expect(manifest.packages.single.id, 'italy-north-map');
    expect(manifest.packages.single.hasSecureUrl, isTrue);
  });

  test('manifest rejects duplicate ids and unsafe file names', () {
    const source = '''
{
  "schemaVersion": 1,
  "updatedAt": "2026-06-17T00:00:00Z",
  "packages": [
    {
      "id": "dup",
      "type": "guide",
      "title": "A",
      "version": "1",
      "url": "https://downloads.camperboss.test/a.pdf",
      "fileName": "../a.pdf",
      "fileSizeBytes": 1,
      "sha256": ""
    },
    {
      "id": "dup",
      "type": "guide",
      "title": "B",
      "version": "1",
      "url": "https://downloads.camperboss.test/b.pdf",
      "fileName": "b.pdf",
      "fileSizeBytes": 1,
      "sha256": ""
    }
  ]
}
''';

    expect(() => DownloadManifest.fromJson(source), throwsFormatException);
  });

  test('manifest repository falls back to cached manifest', () async {
    final collection = LocalJsonCollection(
      'manifest-test',
      store: MemoryKeyValueStore(),
    );
    const cached = '''
{
  "schemaVersion": 1,
  "updatedAt": "2026-06-17T00:00:00Z",
  "packages": [
    {
      "id": "guide",
      "type": "guide",
      "title": "Guide",
      "version": "1",
      "url": "https://downloads.camperboss.test/guide.pdf",
      "fileName": "guide.pdf",
      "fileSizeBytes": 1,
      "sha256": ""
    }
  ]
}
''';
    final writer = LocalOfflineManifestRepository(
      cacheCollection: collection,
      allowedHosts: {'downloads.camperboss.test'},
    );
    await writer.cacheManifest(DownloadManifest.fromJson(cached));

    final reader = LocalOfflineManifestRepository(
      cacheCollection: collection,
      allowedHosts: {'downloads.camperboss.test'},
      remoteLoader: () => throw StateError('offline'),
    );
    final manifest = await reader.loadManifest();

    expect(manifest.fromCache, isTrue);
    expect(manifest.packages.single.id, 'guide');
  });

  test('lost task recovery only reuses matching cached package metadata', () {
    final now = DateTime(2026);
    final record = DownloadRecord(
      packageId: package.id,
      taskId: package.deterministicTaskId,
      type: package.type,
      title: package.title,
      version: package.version,
      fileName: package.fileName,
      localPath: '/tmp/${package.fileName}',
      status: DownloadStatus.failed,
      downloadedBytes: 0,
      totalBytes: package.fileSizeBytes,
      expectedSha256: package.expectedSha256,
      installedSha256: '',
      createdAt: now,
      updatedAt: now,
    );
    final manifest = DownloadManifest(
      schemaVersion: 1,
      updatedAt: now,
      packages: const [package],
      fromCache: true,
    );

    expect(findRetryPackage(manifest, record), same(package));

    final wrongVersion = DownloadManifest(
      schemaVersion: 1,
      updatedAt: now,
      packages: [package.copyWithVersionForTest('2026.99')],
      fromCache: true,
    );
    expect(findRetryPackage(wrongVersion, record), isNull);
    expect(findRetryPackage(null, record), isNull);
  });

  test('download task id is deterministic and URL based', () {
    expect(buildDownloadTaskId(package), package.deterministicTaskId);
    expect(buildDownloadTaskId(package), hasLength(24));
    expect(
      buildDownloadTaskId(package),
      isNot(buildDownloadTaskId(package.copyWithVersionForTest('2026.07'))),
    );
  });

  test('fake manager supports enqueue pause resume cancel retry delete',
      () async {
    final manager = FakeDownloadManager();
    final seen = <List<DownloadRecord>>[];
    final sub = manager.watchDownloads().listen(seen.add);

    await manager.enqueue(package);
    await _settleStream();
    expect(seen.last.single.status, DownloadStatus.queued);

    await manager.resume(package.id);
    await _settleStream();
    expect(seen.last.single.status, DownloadStatus.running);

    await manager.pause(package.id);
    await _settleStream();
    expect(seen.last.single.status, DownloadStatus.paused);

    await manager.cancel(package.id);
    await _settleStream();
    expect(seen.last.single.status, DownloadStatus.canceled);

    await manager.retry(package.id);
    await _settleStream();
    expect(seen.last.single.status, DownloadStatus.queued);

    await manager.delete(package.id);
    await _settleStream();
    expect(seen.last, isEmpty);
    await sub.cancel();
  });

  test('enqueueing a new version replaces the existing package record',
      () async {
    final manager = FakeDownloadManager();
    final seen = <List<DownloadRecord>>[];
    final sub = manager.watchDownloads().listen(seen.add);

    await manager.enqueue(package);
    await manager.enqueue(
      package.copyWithVersionForTest('2026.07'),
    );
    await _settleStream();

    expect(seen.last, hasLength(1));
    expect(seen.last.single.version, '2026.07');
    await sub.cancel();
  });

  test('SHA-256 verification accepts valid file and rejects corrupt file',
      () async {
    final verifier = const DownloadFileVerifier();
    final dir = await Directory.systemTemp.createTemp('camperboss-download-');
    final file = File('${dir.path}/fixture.txt');
    await file.writeAsString('hello world');

    final valid = await verifier.verify(
      file: file,
      expectedBytes: 11,
      expectedSha256: package.expectedSha256,
    );
    expect(valid.valid, isTrue);

    final corrupt = await verifier.verify(
      file: file,
      expectedBytes: 12,
      expectedSha256: package.expectedSha256,
    );
    expect(corrupt.valid, isFalse);
    await dir.delete(recursive: true);
  });

  test('provider can be overridden with fake manager', () async {
    final fake = FakeDownloadManager();
    final container = ProviderContainer(
      overrides: [downloadManagerProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      downloadsProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await container.read(downloadManagerProvider).enqueue(package);
    await _settleStream();
    final records = container.read(downloadsProvider).value;

    expect(records?.single.packageId, package.id);
  });

  test('reconcile is idempotent on fake manager', () async {
    final manager = FakeDownloadManager();
    await manager.enqueue(package);
    await manager.reconcile();
    final records = await manager.watchDownloads().first;
    expect(records.single.packageId, package.id);
  });

  test('storage projection warns and blocks when space is insufficient',
      () async {
    final repository = _MemoryInstalledResourceRepository([
      InstalledResource(
        packageId: 'map',
        type: DownloadPackageType.map,
        version: '1',
        localPath: '/tmp/map.pmtiles',
        fileSizeBytes: 80,
        status: InstalledResourceStatus.installed,
      ),
    ]);
    final inspector = LocalStorageInspector(
      repository: repository,
      appStorageBudgetBytes: 100,
    );

    final warning = await inspector.projectInstallation([
      package.copyWithSizeForTest(5),
    ]);
    expect(warning.pressure, StoragePressure.warning);

    final blocked = await inspector.projectInstallation([
      package.copyWithSizeForTest(30),
    ]);
    expect(blocked.pressure, StoragePressure.insufficient);
  });
}

Future<void> _settleStream() => Future<void>.delayed(Duration.zero);

extension on DownloadablePackage {
  DownloadablePackage copyWithVersionForTest(String version) {
    return DownloadablePackage(
      id: id,
      type: type,
      title: title,
      description: description,
      version: version,
      url: url,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      expectedSha256: expectedSha256,
      requiresWifiByDefault: requiresWifiByDefault,
      destinationDirectory: destinationDirectory,
      metadata: metadata,
      priority: priority,
      group: this.group,
    );
  }

  DownloadablePackage copyWithSizeForTest(int fileSizeBytes) {
    return DownloadablePackage(
      id: id,
      type: type,
      title: title,
      description: description,
      version: version,
      url: url,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      expectedSha256: expectedSha256,
      requiresWifiByDefault: requiresWifiByDefault,
      destinationDirectory: destinationDirectory,
      metadata: metadata,
      priority: priority,
      group: this.group,
    );
  }
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
