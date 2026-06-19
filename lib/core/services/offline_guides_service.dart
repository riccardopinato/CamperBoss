import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/local_key_value_store.dart';
import '../../data/models/download_models.dart';
import '../../data/models/guide_models.dart';
import '../../data/repositories/installed_resource_repository.dart';

abstract interface class OfflineGuidesService {
  Future<bool> isBundledPackageInstalled();
  Future<void> installBundledPackage();
  Future<List<GuidePackage>> listInstalledPackages();
  Future<GuideDocument> loadDocument(String packageId, String entryId);
  Future<Set<String>> loadFavorites();
  Future<void> toggleFavorite(String entryId);
  Future<GuideReadingProgress?> loadReadingProgress(String entryId);
  Future<void> saveReadingProgress(GuideReadingProgress progress);
  Future<List<GuideEntrySearchResult>> search(String query);
  GuideCollectionState collectionState(
    ContentCollection collection,
    List<ContentCollection> collections,
    Set<String> installedPackageIds, {
    Set<String> updatablePackageIds = const {},
  });
  String sanitizeHtml(String html);
}

class GuideEntrySearchResult {
  const GuideEntrySearchResult({
    required this.packageId,
    required this.packageTitle,
    required this.entry,
  });

  final String packageId;
  final String packageTitle;
  final GuideEntry entry;
}

class LocalOfflineGuidesService implements OfflineGuidesService {
  LocalOfflineGuidesService({
    InstalledResourceRepository? installedRepository,
    LocalKeyValueStore? store,
    Future<String> Function(String assetPath)? assetTextLoader,
    Future<ByteData> Function(String assetPath)? assetByteLoader,
    Future<Directory> Function()? appDirectoryProvider,
  })  : _installedRepository =
            installedRepository ?? LocalInstalledResourceRepository(),
        _store = store ?? createLocalKeyValueStore(),
        _assetTextLoader = assetTextLoader ?? rootBundle.loadString,
        _assetByteLoader = assetByteLoader ?? rootBundle.load,
        _appDirectoryProvider =
            appDirectoryProvider ?? getApplicationSupportDirectory;

  static const bundledPackageId = 'camperboss-essential';
  static const bundledManifestAsset =
      'assets/guides/essential/package_manifest.json';
  static const _favoritesKey = 'camperboss.guideFavorites';
  static const _progressKey = 'camperboss.guideProgress';

  final InstalledResourceRepository _installedRepository;
  final LocalKeyValueStore _store;
  final Future<String> Function(String assetPath) _assetTextLoader;
  final Future<ByteData> Function(String assetPath) _assetByteLoader;
  final Future<Directory> Function() _appDirectoryProvider;

  @override
  Future<bool> isBundledPackageInstalled() async {
    final resource =
        await _installedRepository.findByPackageId(bundledPackageId);
    return resource?.status == InstalledResourceStatus.installed;
  }

  @override
  Future<void> installBundledPackage() async {
    final manifest = await _loadBundledManifest();
    final appDir = await _appDirectoryProvider();
    final root = Directory(
      p.join(appDir.path, 'offline', 'guides', manifest.id),
    );
    await root.create(recursive: true);

    await _copyAsset(
        bundledManifestAsset, p.join(root.path, 'package_manifest.json'));
    for (final entry in manifest.entries) {
      await _copyAsset(
        'assets/guides/essential/${entry.relativePath}',
        p.join(root.path, entry.relativePath),
      );
      for (final imagePath in entry.imagePaths) {
        await _copyAsset(
          'assets/guides/essential/$imagePath',
          p.join(root.path, imagePath),
        );
      }
    }

    final manifestFile = File(p.join(root.path, 'package_manifest.json'));
    await _installedRepository.upsert(
      InstalledResource(
        packageId: manifest.id,
        type: DownloadPackageType.guide,
        version: manifest.version,
        localPath: manifestFile.path,
        fileSizeBytes: await _directorySize(root),
        status: InstalledResourceStatus.installed,
        installedAt: DateTime.now(),
        lastVerifiedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<GuidePackage>> listInstalledPackages() async {
    final resources = await _installedRepository.listAll();
    final packages = <GuidePackage>[];
    for (final resource in resources) {
      if ((resource.type != DownloadPackageType.guide &&
              resource.type != DownloadPackageType.manual) ||
          resource.status != InstalledResourceStatus.installed) {
        continue;
      }
      final file = File(resource.localPath);
      if (!await file.exists()) continue;
      final manifest = GuidePackage.fromMap(
        Map<String, Object?>.from(
          jsonDecode(await file.readAsString()) as Map,
        ),
      );
      packages.add(
        GuidePackage.fromMap({
          ...manifest.toMap(),
          'localRootPath': file.parent.path,
        }),
      );
    }
    packages.sort((a, b) => a.title.compareTo(b.title));
    return packages;
  }

  @override
  Future<GuideDocument> loadDocument(String packageId, String entryId) async {
    final packages = await listInstalledPackages();
    final package =
        packages.where((item) => item.id == packageId).toList(growable: false);
    if (package.isEmpty) throw StateError('Guide package not installed');
    final selectedPackage = package.first;
    final entries =
        selectedPackage.entries.where((item) => item.id == entryId).toList();
    if (entries.isEmpty) throw StateError('Guide entry not found');
    final entry = entries.first;
    final localRoot = selectedPackage.localRootPath;
    if (localRoot == null) throw StateError('Guide package root unavailable');
    final file = File(p.join(localRoot, entry.relativePath));
    if (!await file.exists()) throw StateError('Guide file missing');
    var content = await file.readAsString();
    if (entry.contentType == GuideContentType.html) {
      content = sanitizeHtml(content);
    }
    if (entry.contentType == GuideContentType.json) {
      content = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(content));
    }
    return GuideDocument(
      packageId: packageId,
      entryId: entryId,
      title: entry.title,
      contentType: entry.contentType,
      content: content,
      attribution: selectedPackage.attribution,
      localPath: file.path,
    );
  }

  @override
  Future<Set<String>> loadFavorites() async {
    final raw = await _store.read(_favoritesKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.whereType<String>().toSet();
  }

  @override
  Future<void> toggleFavorite(String entryId) async {
    final favorites = await loadFavorites();
    if (!favorites.add(entryId)) {
      favorites.remove(entryId);
    }
    await _store.write(_favoritesKey, jsonEncode(favorites.toList()..sort()));
  }

  @override
  Future<GuideReadingProgress?> loadReadingProgress(String entryId) async {
    final raw = await _store.read(_progressKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, Object?>.from(jsonDecode(raw) as Map);
    final value = map[entryId];
    if (value is! Map) return null;
    return GuideReadingProgress.fromMap(Map<String, Object?>.from(value));
  }

  @override
  Future<void> saveReadingProgress(GuideReadingProgress progress) async {
    final raw = await _store.read(_progressKey);
    final data = raw == null || raw.isEmpty
        ? <String, Object?>{}
        : Map<String, Object?>.from(jsonDecode(raw) as Map);
    data[progress.entryId] = progress.toMap();
    await _store.write(_progressKey, jsonEncode(data));
  }

  @override
  Future<List<GuideEntrySearchResult>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final packages = await listInstalledPackages();
    if (normalized.isEmpty) {
      return [
        for (final package in packages)
          for (final entry in package.entries)
            GuideEntrySearchResult(
              packageId: package.id,
              packageTitle: package.title,
              entry: entry,
            ),
      ];
    }
    return [
      for (final package in packages)
        for (final entry in package.entries)
          if (_matches(entry, normalized))
            GuideEntrySearchResult(
              packageId: package.id,
              packageTitle: package.title,
              entry: entry,
            ),
    ];
  }

  @override
  GuideCollectionState collectionState(
    ContentCollection collection,
    List<ContentCollection> collections,
    Set<String> installedPackageIds, {
    Set<String> updatablePackageIds = const {},
  }) {
    final packageIds = _resolveCollectionPackages(
      collection: collection,
      collections: collections,
      visiting: {},
    );
    final installedCount =
        packageIds.where(installedPackageIds.contains).length;
    if (packageIds.any(updatablePackageIds.contains)) {
      return GuideCollectionState.updateAvailable;
    }
    if (installedCount == 0) return GuideCollectionState.notInstalled;
    if (installedCount == packageIds.length)
      return GuideCollectionState.installed;
    return GuideCollectionState.partiallyInstalled;
  }

  @override
  String sanitizeHtml(String html) {
    var sanitized = html.replaceAll(
      RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'on\w+\s*=\s*"[^"]*"', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"on\w+\s*=\s*'[^']*'", caseSensitive: false),
      '',
    );
    return sanitized;
  }

  Future<GuidePackage> _loadBundledManifest() async {
    return GuidePackage.fromMap(
      Map<String, Object?>.from(
        jsonDecode(await _assetTextLoader(bundledManifestAsset)) as Map,
      ),
    );
  }

  Future<void> _copyAsset(String assetPath, String destinationPath) async {
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    final bytes = await _assetByteLoader(assetPath);
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }

  bool _matches(GuideEntry entry, String query) {
    return entry.title.toLowerCase().contains(query) ||
        (entry.summary ?? '').toLowerCase().contains(query) ||
        entry.keywords.any((item) => item.toLowerCase().contains(query));
  }

  Set<String> _resolveCollectionPackages({
    required ContentCollection collection,
    required List<ContentCollection> collections,
    required Set<String> visiting,
  }) {
    if (!visiting.add(collection.id)) {
      throw const FormatException('Content collection cycle detected');
    }
    final resolved = <String>{...collection.packageIds};
    final includedId = collection.includesCollectionId;
    if (includedId != null) {
      final matches =
          collections.where((item) => item.id == includedId).toList();
      if (matches.isEmpty) {
        throw const FormatException('Included content collection not found');
      }
      resolved.addAll(
        _resolveCollectionPackages(
          collection: matches.first,
          collections: collections,
          visiting: visiting,
        ),
      );
    }
    visiting.remove(collection.id);
    return resolved;
  }

  Future<int> _directorySize(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
