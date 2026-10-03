import 'dart:math' as math;

import '../../data/models/download_models.dart';
import '../../data/repositories/installed_resource_repository.dart';
import 'device_storage_models.dart';
import 'device_storage_service.dart';
import 'managed_media_inspector.dart';
import 'maplibre_offline_region_manager.dart';

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
    this.deviceTotalBytes,
    this.deviceFreeBytes,
    this.policyBudgetBytes = 0,
    this.packageBytes = 0,
    this.mapLibreBytes = 0,
    this.userMediaBytes = 0,
    this.safetyMarginBytes = 0,
    this.deviceCapacityKnown = false,
    this.mediaAccountingKnown = false,
    this.canInstall = true,
  });

  /// Effective headroom. When native capacity is known this is real free
  /// volume bytes; otherwise it is the remaining app-policy budget.
  final int availableBytes;

  /// Bytes managed by CamperBoss across installed packages, MapLibre regions
  /// and user-owned media that can be inspected on the current platform.
  final int usedBytes;
  final int selectedBytes;
  final int projectedUsedBytes;
  final int projectedRemainingBytes;
  final StoragePressure pressure;
  final Map<DownloadPackageType, int> usedByType;

  final int? deviceTotalBytes;
  final int? deviceFreeBytes;
  final int policyBudgetBytes;
  final int packageBytes;
  final int mapLibreBytes;
  final int userMediaBytes;
  final int safetyMarginBytes;
  final bool deviceCapacityKnown;
  final bool mediaAccountingKnown;
  final bool canInstall;

  double get projectedUsageRatio {
    if (policyBudgetBytes > 0) {
      return projectedUsedBytes / policyBudgetBytes;
    }
    final total = deviceTotalBytes;
    final free = deviceFreeBytes;
    if (deviceCapacityKnown && total != null && free != null && total > 0) {
      final projectedFree =
          math.max(0, free - selectedBytes - safetyMarginBytes);
      return (total - projectedFree) / total;
    }
    return 0;
  }
}

class InsufficientStorageException implements Exception {
  const InsufficientStorageException({
    required this.requiredBytes,
    required this.availableBytes,
  });

  final int requiredBytes;
  final int availableBytes;

  @override
  String toString() {
    return 'Insufficient storage: required ' +
        requiredBytes.toString() +
        ' bytes, available ' +
        availableBytes.toString() +
        ' bytes';
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
    DeviceStorageService? deviceStorageService,
    ManagedMediaInspector? mediaInspector,
    MapLibreOfflineRegionManager? mapManager,
    this.appStorageBudgetBytes = 5 * 1024 * 1024 * 1024,
    this.minimumSafetyMarginBytes = 100 * 1024 * 1024,
  })  : _repository = repository ?? LocalInstalledResourceRepository(),
        _deviceStorageService =
            deviceStorageService ?? createDeviceStorageService(),
        _mediaInspector = mediaInspector ?? createManagedMediaInspector(),
        _mapManager =
            mapManager ?? const NativeMapLibreOfflineRegionManager();

  final InstalledResourceRepository _repository;
  final DeviceStorageService _deviceStorageService;
  final ManagedMediaInspector _mediaInspector;
  final MapLibreOfflineRegionManager _mapManager;

  /// Product policy ceiling for managed CamperBoss content. It is deliberately
  /// separate from real device free space.
  final int appStorageBudgetBytes;
  final int minimumSafetyMarginBytes;

  @override
  Future<int> getAvailableBytes() async {
    final projection = await projectInstallation(const []);
    return projection.availableBytes;
  }

  @override
  Future<int> getUsedBytesByCategory(DownloadPackageType type) async {
    final resources = await _repository.listAll();
    var bytes = resources
        .where((resource) =>
            resource.type == type &&
            resource.status == InstalledResourceStatus.installed)
        .fold<int>(0, (sum, resource) => sum + resource.fileSizeBytes);

    if (type == DownloadPackageType.map && _mapManager.isSupported) {
      try {
        final regions = await _mapManager.listRegions();
        bytes += regions
            .where((region) => region.isComplete)
            .fold<int>(0, (sum, region) => sum + region.downloadedBytes);
      } catch (_) {
        // The caller still receives the managed package bytes. Native map
        // accounting is reported as unavailable in the full projection.
      }
    }
    return bytes;
  }

  @override
  Future<StorageProjection> projectInstallation(
    Iterable<DownloadablePackage> packages,
  ) async {
    final resources = await _repository.listAll();
    final usedByType = <DownloadPackageType, int>{};
    var packageBytes = 0;
    for (final resource in resources) {
      if (resource.status != InstalledResourceStatus.installed) continue;
      packageBytes += resource.fileSizeBytes;
      usedByType.update(
        resource.type,
        (value) => value + resource.fileSizeBytes,
        ifAbsent: () => resource.fileSizeBytes,
      );
    }

    var mapLibreBytes = 0;
    if (_mapManager.isSupported) {
      try {
        final regions = await _mapManager.listRegions();
        mapLibreBytes = regions
            .where((region) => region.isComplete)
            .fold<int>(0, (sum, region) => sum + region.downloadedBytes);
      } catch (_) {
        mapLibreBytes = 0;
      }
    }
    if (mapLibreBytes > 0) {
      usedByType.update(
        DownloadPackageType.map,
        (value) => value + mapLibreBytes,
        ifAbsent: () => mapLibreBytes,
      );
    }

    final media = await _mediaInspector.snapshot();
    final device = await _safeDeviceSnapshot();

    final selected = packages.fold<int>(
      0,
      (sum, package) => sum + math.max(0, package.fileSizeBytes),
    );
    final userMediaBytes = media.bytes;
    final used = packageBytes + mapLibreBytes + userMediaBytes;
    final projectedUsed = used + selected;

    final policyKnown = appStorageBudgetBytes > 0;
    final policyRemaining = policyKnown
        ? math.max(0, appStorageBudgetBytes - projectedUsed)
        : 0x7fffffffffffffff;
    final policyAllows =
        !policyKnown || projectedUsed <= appStorageBudgetBytes;

    final safetyMargin = selected <= 0
        ? 0
        : math.max(
            minimumSafetyMarginBytes,
            (selected * 0.10).ceil(),
          );
    final requiredDeviceBytes = selected + safetyMargin;

    final deviceKnown = device.isAvailable;
    final deviceFree = device.freeBytes;
    final deviceAllows = !deviceKnown ||
        (deviceFree != null && deviceFree >= requiredDeviceBytes);

    final effectiveAvailable = deviceKnown
        ? deviceFree!
        : (policyKnown
            ? math.max(0, appStorageBudgetBytes - used)
            : 0);

    final projectedDeviceRemaining = deviceKnown
        ? math.max(0, deviceFree! - requiredDeviceBytes)
        : policyRemaining;
    final effectiveRemaining = policyKnown
        ? math.min(projectedDeviceRemaining, policyRemaining)
        : projectedDeviceRemaining;

    final policyRatio = policyKnown && appStorageBudgetBytes > 0
        ? projectedUsed / appStorageBudgetBytes
        : 0.0;
    final freeRatio = deviceKnown &&
            device.totalBytes != null &&
            device.totalBytes! > 0 &&
            deviceFree != null
        ? deviceFree / device.totalBytes!
        : 1.0;

    final pressure = !policyAllows || !deviceAllows
        ? StoragePressure.insufficient
        : freeRatio <= 0.05 || policyRatio >= 0.90
            ? StoragePressure.critical
            : freeRatio <= 0.10 || policyRatio >= 0.75
                ? StoragePressure.warning
                : StoragePressure.normal;

    return StorageProjection(
      availableBytes: effectiveAvailable,
      usedBytes: used,
      selectedBytes: selected,
      projectedUsedBytes: projectedUsed,
      projectedRemainingBytes: effectiveRemaining,
      pressure: pressure,
      usedByType: Map.unmodifiable(usedByType),
      deviceTotalBytes: device.totalBytes,
      deviceFreeBytes: device.freeBytes,
      policyBudgetBytes: appStorageBudgetBytes,
      packageBytes: packageBytes,
      mapLibreBytes: mapLibreBytes,
      userMediaBytes: userMediaBytes,
      safetyMarginBytes: safetyMargin,
      deviceCapacityKnown: deviceKnown,
      mediaAccountingKnown: media.isAvailable,
      canInstall: policyAllows && deviceAllows,
    );
  }

  Future<DeviceStorageSnapshot> _safeDeviceSnapshot() async {
    try {
      return await _deviceStorageService.snapshot();
    } catch (_) {
      return const DeviceStorageSnapshot(source: 'error');
    }
  }
}
