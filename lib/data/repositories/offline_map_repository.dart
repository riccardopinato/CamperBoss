import '../database/local_key_value_store.dart';
import '../models/download_models.dart';
import '../models/offline_map_models.dart';
import 'installed_resource_repository.dart';

abstract interface class OfflineMapRepository {
  Stream<List<InstalledMapRegion>> watchInstalledRegions();
  Future<List<InstalledMapRegion>> listInstalledRegions();
  Future<void> activateRegion(String packageId);
  Future<void> deactivateRegion(String packageId);
  Future<void> deleteRegion(String packageId);
  Future<MapSourceConfiguration?> resolveActiveSource();
}

class LocalOfflineMapRepository implements OfflineMapRepository {
  LocalOfflineMapRepository({
    InstalledResourceRepository? installedRepository,
    LocalKeyValueStore? store,
    bool Function(InstalledResource resource)? canOpenSource,
  })  : _installedRepository =
            installedRepository ?? LocalInstalledResourceRepository(),
        _store = store ?? createLocalKeyValueStore(),
        _canOpenSource = canOpenSource ?? _defaultCanOpenSource;

  static const _activeRegionKey = 'camperboss.offline_maps.active_region';

  final InstalledResourceRepository _installedRepository;
  final LocalKeyValueStore _store;
  final bool Function(InstalledResource resource) _canOpenSource;

  @override
  Stream<List<InstalledMapRegion>> watchInstalledRegions() async* {
    yield await listInstalledRegions();
  }

  @override
  Future<List<InstalledMapRegion>> listInstalledRegions() async {
    final activePackageId = await _store.read(_activeRegionKey);
    final resources = await _installedRepository.listAll();
    return resources
        .where((resource) => resource.type == DownloadPackageType.map)
        .map(
          (resource) => InstalledMapRegion(
            packageId: resource.packageId,
            title: _titleFor(resource.packageId),
            version: resource.version,
            localPath: resource.localPath,
            sizeBytes: resource.fileSizeBytes,
            status: resource.status,
            active: resource.packageId == activePackageId,
            lastVerifiedAt: resource.lastVerifiedAt,
            lastError: resource.lastError,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> activateRegion(String packageId) async {
    final resource = await _installedRepository.findByPackageId(packageId);
    if (resource == null ||
        resource.type != DownloadPackageType.map ||
        resource.status != InstalledResourceStatus.installed ||
        !_canOpenSource(resource)) {
      throw StateError('Offline map region is not installed');
    }
    await _store.write(_activeRegionKey, packageId);
  }

  @override
  Future<void> deactivateRegion(String packageId) async {
    final active = await _store.read(_activeRegionKey);
    if (active == packageId) {
      await _store.remove(_activeRegionKey);
    }
  }

  @override
  Future<void> deleteRegion(String packageId) async {
    await deactivateRegion(packageId);
    await _installedRepository.delete(packageId);
  }

  @override
  Future<MapSourceConfiguration?> resolveActiveSource() async {
    final activePackageId = await _store.read(_activeRegionKey);
    if (activePackageId == null || activePackageId.isEmpty) return null;
    final resource = await _installedRepository.findByPackageId(activePackageId);
    if (resource == null ||
        resource.type != DownloadPackageType.map ||
        resource.status != InstalledResourceStatus.installed ||
        !_canOpenSource(resource)) {
      return null;
    }

    return MapSourceConfiguration(
      packageId: resource.packageId,
      type: MapSourceType.pmtiles,
      localPath: resource.localPath,
      attribution: 'Offline PMTiles package ${resource.version}',
    );
  }

  String _titleFor(String packageId) {
    return switch (packageId) {
      'italy_north_2026-06' || 'italy-north-2026-06' => 'Nord Italia',
      'italy_centre_2026-06' || 'italy-centre-2026-06' => 'Centro Italia',
      'italy_south_2026-06' || 'italy-south-2026-06' => 'Sud Italia',
      'alps_2026-06' || 'alps-2026-06' => 'Alpi',
      _ => packageId,
    };
  }

  static bool _defaultCanOpenSource(InstalledResource resource) {
    return resource.localPath.isNotEmpty &&
        resource.localPath.toLowerCase().endsWith('.pmtiles');
  }
}
