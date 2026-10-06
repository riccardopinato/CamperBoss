import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camperboss/core/services/offline_guides_service.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/data/models/guide_models.dart';
import 'package:camperboss/data/repositories/installed_resource_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('production bundled guide assets are packaged and installable',
      (tester) async {
    final temp = await Directory.systemTemp.createTemp('guides_bundle_test');
    addTearDown(() => temp.delete(recursive: true));
    final installed = _MemoryInstalledResourceRepository();
    final service = LocalOfflineGuidesService(
      installedRepository: installed,
      store: _MemoryStore(),
      appDirectoryProvider: () async => temp,
    );

    final manifestRaw = await rootBundle.loadString(
      LocalOfflineGuidesService.bundledManifestAsset,
    );
    final manifest = GuidePackage.fromMap(
      Map<String, Object?>.from(jsonDecode(manifestRaw) as Map),
    );
    expect(manifest.id, LocalOfflineGuidesService.bundledPackageId);
    for (final entry in manifest.entries) {
      final bytes = await rootBundle.load(
        'assets/guides/essential/${entry.relativePath}',
      );
      expect(bytes.lengthInBytes, greaterThan(0));
    }

    await service.installBundledPackage();
    final packages = await service.listInstalledPackages();

    expect(packages.single.id, LocalOfflineGuidesService.bundledPackageId);
  });

  test('installs bundled guide package and loads searchable entries', () async {
    final temp = await Directory.systemTemp.createTemp('guides_test');
    addTearDown(() => temp.delete(recursive: true));
    final installed = _MemoryInstalledResourceRepository();
    final service = LocalOfflineGuidesService(
      installedRepository: installed,
      store: _MemoryStore(),
      assetTextLoader: (path) async => _assets[path]!,
      assetByteLoader: (path) async => ByteData.sublistView(
        Uint8List.fromList(utf8.encode(_assets[path]!)),
      ),
      appDirectoryProvider: () async => temp,
    );

    await service.installBundledPackage();
    final packages = await service.listInstalledPackages();
    final results = await service.search('sosta');

    expect(await service.isBundledPackageInstalled(), isTrue);
    expect(packages.single.id, LocalOfflineGuidesService.bundledPackageId);
    expect(results.single.entry.id, 'overnight-rules');
  });

  test('sanitizes html and persists favorites plus reading progress', () async {
    final store = _MemoryStore();
    final service = LocalOfflineGuidesService(
      installedRepository: _MemoryInstalledResourceRepository(),
      store: store,
      assetTextLoader: (path) async => _assets[path]!,
      assetByteLoader: (path) async => ByteData.sublistView(
        Uint8List.fromList(utf8.encode(_assets[path]!)),
      ),
      appDirectoryProvider: () async => Directory.systemTemp,
    );

    final sanitized = service.sanitizeHtml(
      '<div onclick="bad()">ok</div><script>alert(1)</script>',
    );
    await service.toggleFavorite('emergency-basics');
    await service.saveReadingProgress(
      GuideReadingProgress(
        entryId: 'emergency-basics',
        offset: 120,
        updatedAt: DateTime(2026, 6, 18),
      ),
    );

    expect(sanitized, '<div >ok</div>');
    expect(await service.loadFavorites(), {'emergency-basics'});
    expect(
        (await service.loadReadingProgress('emergency-basics'))?.offset, 120);
  });

  test('computes collection states and rejects cycles', () {
    final service = LocalOfflineGuidesService(
      installedRepository: _MemoryInstalledResourceRepository(),
      store: _MemoryStore(),
      assetTextLoader: (path) async => _assets[path]!,
      assetByteLoader: (path) async => ByteData.sublistView(
        Uint8List.fromList(utf8.encode(_assets[path]!)),
      ),
      appDirectoryProvider: () async => Directory.systemTemp,
    );

    expect(
      service.collectionState(
        const ContentCollection(
          id: 'essential',
          title: 'Essential',
          packageIds: ['camperboss-essential'],
        ),
        const [],
        {'camperboss-essential'},
      ),
      GuideCollectionState.installed,
    );
    expect(
      () => service.collectionState(
        const ContentCollection(
          id: 'a',
          title: 'A',
          packageIds: [],
          includesCollectionId: 'b',
        ),
        const [
          ContentCollection(
            id: 'a',
            title: 'A',
            packageIds: [],
            includesCollectionId: 'b',
          ),
          ContentCollection(
            id: 'b',
            title: 'B',
            packageIds: [],
            includesCollectionId: 'a',
          ),
        ],
        const {},
      ),
      throwsFormatException,
    );
  });
}

class _MemoryInstalledResourceRepository
    implements InstalledResourceRepository {
  final resources = <InstalledResource>[];

  @override
  Future<void> delete(String packageId) async {
    resources.removeWhere((item) => item.packageId == packageId);
  }

  @override
  Future<InstalledResource?> findByPackageId(String packageId) async {
    for (final resource in resources) {
      if (resource.packageId == packageId) return resource;
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

const _assets = {
  'assets/guides/essential/package_manifest.json':
      '{"id":"camperboss-essential","title":"CamperBoss Essential","version":"1.0.0","language":"it","countryCodes":["IT"],"category":"guides","requiresPro":false,"updatedAt":"2026-06-18T00:00:00.000Z","attribution":"CamperBoss editorial starter content.","entries":[{"id":"emergency-basics","title":"Emergenze essenziali","relativePath":"emergency-basics.md","contentType":"markdown","summary":"Numeri, priorita e verifiche da fare prima di muovere il mezzo.","keywords":["emergenza","sicurezza","soccorso"],"imagePaths":[]},{"id":"overnight-rules","title":"Sosta e comportamento responsabile","relativePath":"overnight-rules.html","contentType":"html","summary":"Promemoria pratici per sosta, rumore, rifiuti e scarichi.","keywords":["sosta","regole","scarico"],"imagePaths":[]}]}',
  'assets/guides/essential/emergency-basics.md': '# Test',
  'assets/guides/essential/overnight-rules.html': '<h1>Regole sosta</h1>',
};
