import '../../data/models/download_models.dart';
import '../../data/models/poi_catalog_models.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import '../../data/repositories/poi_package_state_repository.dart';
import 'app_download_manager.dart';

class PoiCatalogService {
  PoiCatalogService({
    required OfflineManifestRepository manifestRepository,
    required AppDownloadManager downloadManager,
    required PoiPackageStateRepository stateRepository,
    required bool remoteConfigured,
  })  : _manifestRepository = manifestRepository,
        _downloadManager = downloadManager,
        _stateRepository = stateRepository,
        _remoteConfigured = remoteConfigured;

  final OfflineManifestRepository _manifestRepository;
  final AppDownloadManager _downloadManager;
  final PoiPackageStateRepository _stateRepository;
  final bool _remoteConfigured;

  Future<PoiCatalogSnapshot> snapshot() async {
    final installed = await _stateRepository.listStates();
    DownloadManifest? manifest;
    String? message;

    if (_remoteConfigured) {
      try {
        manifest = await _manifestRepository.loadManifest();
      } catch (error) {
        message = error.toString();
      }
    } else {
      try {
        manifest = await _manifestRepository.loadCachedManifest();
      } catch (_) {
        manifest = null;
      }
      if (manifest == null) {
        message = 'Remote POI catalog is not configured';
      }
    }

    final statesById = {
      for (final state in installed) state.packageId: state,
    };
    final entries = <PoiCatalogEntry>[];
    for (final package in manifest?.packages ?? const <DownloadablePackage>[]) {
      if (package.type != DownloadPackageType.poiDatabase) continue;
      try {
        entries.add(
          PoiCatalogEntry(
            package: package,
            region: _requiredMeta(package, 'region'),
            license: _requiredMeta(package, 'license'),
            attribution: _requiredMeta(package, 'attribution'),
            source: _requiredMeta(package, 'source'),
            installed: statesById[package.id],
          ),
        );
      } on FormatException catch (error) {
        message ??= error.message;
      }
    }

    return PoiCatalogSnapshot(
      remoteConfigured: _remoteConfigured,
      fromCache: manifest?.fromCache ?? false,
      entries: List.unmodifiable(entries),
      installed: List.unmodifiable(installed),
      message: message,
    );
  }

  Future<void> install(String packageId) async {
    final manifest = await _manifestRepository.loadManifest();
    DownloadablePackage? match;
    for (final package in manifest.packages) {
      if (package.id == packageId &&
          package.type == DownloadPackageType.poiDatabase) {
        match = package;
        break;
      }
    }
    if (match == null) {
      throw StateError('POI package is not present in the catalog');
    }

    _requiredMeta(match, 'region');
    _requiredMeta(match, 'license');
    _requiredMeta(match, 'attribution');
    _requiredMeta(match, 'source');
    await _downloadManager.enqueue(match);
  }

  Future<void> remove(String packageId) {
    return _downloadManager.delete(packageId);
  }

  String _requiredMeta(DownloadablePackage package, String key) {
    final value = package.metadata[key]?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw FormatException(
        'POI package metadata "' + key + '" is required',
      );
    }
    return value;
  }
}
