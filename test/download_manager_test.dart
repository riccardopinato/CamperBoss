import 'dart:io';

import 'package:camperboss/core/providers/download_manager_provider.dart';
import 'package:camperboss/core/services/app_download_manager.dart';
import 'package:camperboss/core/services/download_file_verifier.dart';
import 'package:camperboss/data/models/download_models.dart';
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

  test('parses manifest without fake production URLs', () {
    const source = '''
{
  "schemaVersion": 1,
  "packages": [
    {
      "id": "italy-north-map",
      "type": "map",
      "title": "Nord Italia",
      "version": "2026.06",
      "url": "",
      "fileName": "italy_north.pmtiles",
      "fileSizeBytes": 0,
      "sha256": ""
    }
  ]
}
''';

    final manifest = DownloadManifest.fromJson(source);

    expect(manifest.schemaVersion, 1);
    expect(manifest.packages.single.id, 'italy-north-map');
    expect(manifest.packages.single.url, isEmpty);
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
}
