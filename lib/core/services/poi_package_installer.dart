import 'dart:io';

import '../../data/models/download_models.dart';
import '../../data/models/poi_catalog_models.dart';
import '../../data/repositories/download_record_repository.dart';
import '../../data/repositories/installed_resource_repository.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import '../../data/repositories/offline_poi_repository.dart';
import '../../data/repositories/poi_package_state_repository.dart';
import 'offline_package_installer.dart';

class PoiPackageInstaller implements OfflinePackageInstaller {
  PoiPackageInstaller({
    required PoiRepository poiRepository,
    required PoiPackageStateRepository stateRepository,
    required OfflineManifestRepository manifestRepository,
    required InstalledResourceRepository installedRepository,
    DownloadRecordRepository? downloadRepository,
    this.maxPackageBytes = 64 * 1024 * 1024,
  })  : _poiRepository = poiRepository,
        _stateRepository = stateRepository,
        _manifestRepository = manifestRepository,
        _installedRepository = installedRepository,
        _downloadRepository =
            downloadRepository ?? LocalDownloadRecordRepository();

  final PoiRepository _poiRepository;
  final PoiPackageStateRepository _stateRepository;
  final OfflineManifestRepository _manifestRepository;
  final InstalledResourceRepository _installedRepository;
  final DownloadRecordRepository _downloadRepository;
  final int maxPackageBytes;

  @override
  Future<void> install(DownloadRecord record, File file) async {
    if (record.type != DownloadPackageType.poiDatabase) return;
    if (!await file.exists()) {
      throw StateError('POI package file is missing');
    }
    final size = await file.length();
    if (size <= 0 || size > maxPackageBytes) {
      throw StateError('POI package exceeds the supported activation limit');
    }

    final package = await _manifestPackage(record.packageId, record.version);
    if (package == null) {
      throw StateError('POI package metadata is unavailable');
    }
    final meta = _metadataFor(package);

    final source = await file.readAsString();
    final count = await _poiRepository.importPackageFromJson(
      record.packageId,
      source,
    );

    await _stateRepository.save(
      PoiPackageState(
        packageId: record.packageId,
        version: record.version,
        title: record.title,
        region: meta.region,
        itemCount: count,
        fileSizeBytes: size,
        license: meta.license,
        attribution: meta.attribution,
        source: meta.source,
        installedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> uninstall(DownloadRecord record) async {
    if (record.type != DownloadPackageType.poiDatabase) return;
    await _poiRepository.removePackage(record.packageId);
    await _stateRepository.delete(record.packageId);
  }

  @override
  Future<void> reconcile() async {
    final resources = await _installedRepository.listAll();
    for (final resource in resources) {
      if (resource.type != DownloadPackageType.poiDatabase ||
          resource.status != InstalledResourceStatus.installed) {
        continue;
      }

      final state = await _stateRepository.find(resource.packageId);
      if (state != null &&
          state.version == resource.version &&
          state.itemCount > 0) {
        continue;
      }

      final record = await _downloadRepository.getRecord(resource.packageId);
      if (record == null || record.version != resource.version) continue;
      final file = File(resource.localPath);
      try {
        await install(record, file);
      } catch (_) {
        // Keep the currently activated local package untouched. Download/retry
        // remains the user-facing recovery surface.
      }
    }
  }

  Future<DownloadablePackage?> _manifestPackage(
    String packageId,
    String version,
  ) async {
    DownloadManifest? manifest;
    try {
      manifest = await _manifestRepository.loadCachedManifest();
    } catch (_) {
      manifest = null;
    }
    if (manifest == null) return null;

    for (final package in manifest.packages) {
      if (package.id == packageId &&
          package.version == version &&
          package.type == DownloadPackageType.poiDatabase) {
        return package;
      }
    }
    return null;
  }

  _PoiRequiredMetadata _metadataFor(DownloadablePackage package) {
    String required(String key) {
      final value = package.metadata[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw FormatException(
          'POI package metadata "' + key + '" is required',
        );
      }
      return value;
    }

    return _PoiRequiredMetadata(
      region: required('region'),
      license: required('license'),
      attribution: required('attribution'),
      source: required('source'),
    );
  }
}

class _PoiRequiredMetadata {
  const _PoiRequiredMetadata({
    required this.region,
    required this.license,
    required this.attribution,
    required this.source,
  });

  final String region;
  final String license;
  final String attribution;
  final String source;
}
