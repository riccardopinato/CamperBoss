import '../database/local_json_collection.dart';
import '../models/download_models.dart';

abstract interface class OfflineManifestRepository {
  Future<DownloadManifest> loadManifest();
  Future<DownloadManifest?> loadCachedManifest();
  Future<void> cacheManifest(DownloadManifest manifest);
}

typedef ManifestLoader = Future<String> Function();

class LocalOfflineManifestRepository implements OfflineManifestRepository {
  LocalOfflineManifestRepository({
    ManifestLoader? remoteLoader,
    LocalJsonCollection? cacheCollection,
    this.allowedHosts = const {},
  })  : _remoteLoader = remoteLoader,
        _cacheCollection = cacheCollection ??
            LocalJsonCollection('camperboss.offline_manifest');

  final ManifestLoader? _remoteLoader;
  final LocalJsonCollection _cacheCollection;
  final Set<String> allowedHosts;

  @override
  Future<DownloadManifest> loadManifest() async {
    try {
      final loader = _remoteLoader;
      if (loader == null) {
        throw const OfflineManifestUnavailable(
            'Remote manifest not configured');
      }
      final manifest = DownloadManifest.fromJson(await loader());
      manifest.validate(allowedHosts: allowedHosts);
      await cacheManifest(manifest);
      return manifest;
    } catch (error) {
      final cached = await loadCachedManifest();
      if (cached != null) return cached.copyWith(fromCache: true);
      throw OfflineManifestUnavailable(
        'Manifest unavailable and no cached copy exists',
        error,
      );
    }
  }

  @override
  Future<DownloadManifest?> loadCachedManifest() async {
    final rows = await _cacheCollection.listRows();
    if (rows.isEmpty) return null;
    final raw = rows.first['manifest_json'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DownloadManifest.fromJson(raw).copyWith(fromCache: true);
  }

  @override
  Future<void> cacheManifest(DownloadManifest manifest) async {
    manifest.validate(allowedHosts: allowedHosts);
    await _cacheCollection.saveRow({
      'id': 'current',
      'manifest_json': manifest.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

class OfflineManifestUnavailable implements Exception {
  const OfflineManifestUnavailable(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
