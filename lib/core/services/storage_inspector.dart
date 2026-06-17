import '../../data/models/download_models.dart';
import '../../data/repositories/installed_resource_repository.dart';

enum StoragePressure {
  normal,
  warning,
  critical,
  insufficient,
}

class StorageProjection {
  const StorageProjection({
    required this.availableBytes,
    required this.usedBytes,
    required this.selectedBytes,
    required this.projectedUsedBytes,
    required this.projectedRemainingBytes,
    required this.pressure,
    required this.usedByType,
  });

  final int availableBytes;
  final int usedBytes;
  final int selectedBytes;
  final int projectedUsedBytes;
  final int projectedRemainingBytes;
  final StoragePressure pressure;
  final Map<DownloadPackageType, int> usedByType;

  double get projectedUsageRatio {
    if (availableBytes <= 0) return 1;
    return projectedUsedBytes / availableBytes;
  }
}

abstract interface class StorageInspector {
  Future<int> getAvailableBytes();
  Future<int> getUsedBytesByCategory(DownloadPackageType type);
  Future<StorageProjection> projectInstallation(
    Iterable<DownloadablePackage> packages,
  );
}

class LocalStorageInspector implements StorageInspector {
  LocalStorageInspector({
    InstalledResourceRepository? repository,
    this.appStorageBudgetBytes = 5 * 1024 * 1024 * 1024,
  }) : _repository = repository ?? LocalInstalledResourceRepository();

  final InstalledResourceRepository _repository;
  final int appStorageBudgetBytes;

  @override
  Future<int> getAvailableBytes() async {
    final used = await _usedBytes();
    return (appStorageBudgetBytes - used).clamp(0, appStorageBudgetBytes);
  }

  @override
  Future<int> getUsedBytesByCategory(DownloadPackageType type) async {
    final resources = await _repository.listAll();
    return resources
        .where((resource) =>
            resource.type == type &&
            resource.status == InstalledResourceStatus.installed)
        .fold<int>(0, (sum, resource) => sum + resource.fileSizeBytes);
  }

  @override
  Future<StorageProjection> projectInstallation(
    Iterable<DownloadablePackage> packages,
  ) async {
    final resources = await _repository.listAll();
    final usedByType = <DownloadPackageType, int>{};
    var used = 0;
    for (final resource in resources) {
      if (resource.status != InstalledResourceStatus.installed) continue;
      used += resource.fileSizeBytes;
      usedByType.update(
        resource.type,
        (value) => value + resource.fileSizeBytes,
        ifAbsent: () => resource.fileSizeBytes,
      );
    }
    final selected = packages.fold<int>(
      0,
      (sum, package) => sum + package.fileSizeBytes,
    );
    final projectedUsed = used + selected;
    final remaining = appStorageBudgetBytes - projectedUsed;
    final ratio = appStorageBudgetBytes <= 0
        ? 1.0
        : projectedUsed / appStorageBudgetBytes;
    final pressure = remaining < 0
        ? StoragePressure.insufficient
        : ratio >= 0.9
            ? StoragePressure.critical
            : ratio >= 0.75
                ? StoragePressure.warning
                : StoragePressure.normal;

    return StorageProjection(
      availableBytes: appStorageBudgetBytes,
      usedBytes: used,
      selectedBytes: selected,
      projectedUsedBytes: projectedUsed,
      projectedRemainingBytes: remaining.clamp(0, appStorageBudgetBytes),
      pressure: pressure,
      usedByType: Map.unmodifiable(usedByType),
    );
  }

  Future<int> _usedBytes() async {
    final resources = await _repository.listAll();
    return resources
        .where((resource) => resource.status == InstalledResourceStatus.installed)
        .fold<int>(0, (sum, resource) => sum + resource.fileSizeBytes);
  }
}
