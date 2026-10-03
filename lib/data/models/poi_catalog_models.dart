import 'download_models.dart';

class PoiPackageState {
  const PoiPackageState({
    required this.packageId,
    required this.version,
    required this.title,
    required this.region,
    required this.itemCount,
    required this.fileSizeBytes,
    required this.license,
    required this.attribution,
    required this.source,
    required this.installedAt,
  });

  final String packageId;
  final String version;
  final String title;
  final String region;
  final int itemCount;
  final int fileSizeBytes;
  final String license;
  final String attribution;
  final String source;
  final DateTime installedAt;

  Map<String, Object?> toMap() => {
        'id': packageId,
        'package_id': packageId,
        'version': version,
        'title': title,
        'region': region,
        'item_count': itemCount,
        'file_size_bytes': fileSizeBytes,
        'license': license,
        'attribution': attribution,
        'source': source,
        'installed_at': installedAt.toUtc().toIso8601String(),
      };

  factory PoiPackageState.fromMap(Map<String, Object?> map) {
    return PoiPackageState(
      packageId: map['package_id'] as String,
      version: map['version'] as String,
      title: map['title'] as String? ?? map['package_id'] as String,
      region: map['region'] as String? ?? '',
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      license: map['license'] as String? ?? '',
      attribution: map['attribution'] as String? ?? '',
      source: map['source'] as String? ?? '',
      installedAt: DateTime.parse(map['installed_at'] as String),
    );
  }
}

class PoiCatalogEntry {
  const PoiCatalogEntry({
    required this.package,
    required this.region,
    required this.license,
    required this.attribution,
    required this.source,
    this.installed,
  });

  final DownloadablePackage package;
  final String region;
  final String license;
  final String attribution;
  final String source;
  final PoiPackageState? installed;

  bool get isInstalled => installed?.version == package.version;
  bool get hasUpdate =>
      installed != null && installed!.version != package.version;
}

class PoiCatalogSnapshot {
  const PoiCatalogSnapshot({
    required this.remoteConfigured,
    required this.fromCache,
    required this.entries,
    required this.installed,
    this.message,
  });

  final bool remoteConfigured;
  final bool fromCache;
  final List<PoiCatalogEntry> entries;
  final List<PoiPackageState> installed;
  final String? message;

  bool get hasAvailablePackages => entries.isNotEmpty;
}
