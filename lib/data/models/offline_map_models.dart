import 'download_models.dart';

class InstalledMapRegion {
  const InstalledMapRegion({
    required this.packageId,
    required this.title,
    required this.version,
    required this.localPath,
    required this.sizeBytes,
    required this.status,
    required this.active,
    this.lastVerifiedAt,
    this.lastError,
  });

  final String packageId;
  final String title;
  final String version;
  final String localPath;
  final int sizeBytes;
  final InstalledResourceStatus status;
  final bool active;
  final DateTime? lastVerifiedAt;
  final String? lastError;

  bool get availableOffline =>
      active &&
      status == InstalledResourceStatus.installed &&
      localPath.isNotEmpty;
}

class MapSourceConfiguration {
  const MapSourceConfiguration({
    required this.packageId,
    required this.type,
    required this.localPath,
    required this.attribution,
  });

  final String packageId;
  final MapSourceType type;
  final String localPath;
  final String attribution;
}

enum MapSourceType {
  pmtiles,
}
