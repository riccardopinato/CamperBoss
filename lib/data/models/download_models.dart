import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

enum DownloadPackageType {
  map,
  poiDatabase,
  guide,
  manual,
  languagePack,
  backup,
  other,
}

enum InstalledResourceStatus {
  installing,
  installed,
  updateAvailable,
  missing,
  corrupted,
  failed,
}

enum DownloadStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  canceled,
  verifying,
  corrupted,
}

String normalizeOfflineDestinationDirectory(String value) {
  final raw = value.trim().replaceAll('\\', '/');
  if (raw.isEmpty || p.posix.isAbsolute(raw)) {
    throw const FormatException('Package destination directory is invalid');
  }

  final normalized = p.posix.normalize(raw);
  final isInsideOfflineRoot =
      normalized == 'offline' || normalized.startsWith('offline/');
  if (normalized == '.' ||
      normalized == '..' ||
      normalized.startsWith('../') ||
      !isInsideOfflineRoot) {
    throw const FormatException(
      'Package destination must stay inside the offline root',
    );
  }
  return normalized;
}

class DownloadablePackage {
  const DownloadablePackage({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.version,
    required this.url,
    required this.fileName,
    required this.fileSizeBytes,
    required this.expectedSha256,
    required this.requiresWifiByDefault,
    required this.destinationDirectory,
    this.metadata = const {},
    this.priority = 5,
    this.group = 'offline',
  });

  final String id;
  final DownloadPackageType type;
  final String title;
  final String description;
  final String version;
  final String url;
  final String fileName;
  final int fileSizeBytes;
  final String expectedSha256;
  final bool requiresWifiByDefault;
  final String destinationDirectory;
  final Map<String, Object?> metadata;
  final int priority;
  final String group;

  bool get hasValidUrl => Uri.tryParse(url)?.hasAbsolutePath == true;

  bool get hasSecureUrl => Uri.tryParse(url)?.scheme == 'https';

  String get deterministicTaskId {
    final source = '$id|$version|$url';
    return sha256.convert(utf8.encode(source)).toString().substring(0, 24);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'version': version,
      'url': url,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'sha256': expectedSha256,
      'requiresWifiByDefault': requiresWifiByDefault,
      'destinationDirectory': destinationDirectory,
      'metadata': metadata,
      'priority': priority,
      'group': group,
    };
  }

  factory DownloadablePackage.fromMap(Map<String, Object?> map) {
    return DownloadablePackage(
      id: map['id'] as String,
      type: _typeFromName(map['type'] as String?),
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      version: map['version'] as String,
      url: map['url'] as String,
      fileName: map['fileName'] as String,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      expectedSha256: map['sha256'] as String? ?? '',
      requiresWifiByDefault: map['requiresWifiByDefault'] as bool? ?? true,
      destinationDirectory: map['destinationDirectory'] as String? ?? 'offline',
      metadata: Map<String, Object?>.from(
        map['metadata'] as Map? ?? const {},
      ),
      priority: (map['priority'] as num?)?.toInt() ?? 5,
      group: map['group'] as String? ?? 'offline',
    );
  }
}

class DownloadManifest {
  const DownloadManifest({
    required this.schemaVersion,
    required this.updatedAt,
    required this.packages,
    this.fromCache = false,
  });

  final int schemaVersion;
  final DateTime updatedAt;
  final List<DownloadablePackage> packages;
  final bool fromCache;

  factory DownloadManifest.fromJson(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final schemaVersion = decoded['schemaVersion'] as int?;
    final updatedAtRaw = decoded['updatedAt'] as String?;
    final packages = decoded['packages'] as List<dynamic>?;
    if (schemaVersion != 1 || updatedAtRaw == null || packages == null) {
      throw const FormatException('Invalid download manifest');
    }
    final parsed = DownloadManifest(
      schemaVersion: schemaVersion!,
      updatedAt: DateTime.parse(updatedAtRaw),
      packages: packages
          .map((item) => DownloadablePackage.fromMap(
                Map<String, Object?>.from(item as Map),
              ))
          .toList(growable: false),
    );
    parsed.validate();
    return parsed;
  }

  DownloadManifest copyWith({bool? fromCache}) {
    return DownloadManifest(
      schemaVersion: schemaVersion,
      updatedAt: updatedAt,
      packages: packages,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  String toJson() {
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'packages': packages.map((package) => package.toMap()).toList(),
    });
  }

  void validate({
    Set<String> allowedHosts = const {},
    bool requireHttps = true,
  }) {
    if (schemaVersion != 1) {
      throw const FormatException('Unsupported manifest schema');
    }
    final ids = <String>{};
    final destinationPaths = <String>{};
    for (final package in packages) {
      if (package.id.trim().isEmpty || !ids.add(package.id)) {
        throw const FormatException('Package IDs must be unique and non-empty');
      }
      if (package.version.trim().isEmpty) {
        throw const FormatException('Package version is required');
      }
      if (package.fileName.trim().isEmpty ||
          package.fileName.contains('/') ||
          package.fileName.contains('\\') ||
          package.fileName.contains('..')) {
        throw const FormatException('Package file name is invalid');
      }
      final destinationDirectory =
          normalizeOfflineDestinationDirectory(package.destinationDirectory);
      final destinationPath =
          p.posix.join(destinationDirectory, package.fileName);
      if (!destinationPaths.add(destinationPath)) {
        throw const FormatException(
          'Package destination paths must be unique',
        );
      }
      if (package.fileSizeBytes < 0) {
        throw const FormatException('Package size cannot be negative');
      }
      if (package.expectedSha256.isNotEmpty &&
          !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(package.expectedSha256)) {
        throw const FormatException('Package SHA-256 is invalid');
      }
      final uri = Uri.tryParse(package.url);
      if (uri == null || !uri.hasAbsolutePath || uri.host.isEmpty) {
        throw const FormatException('Package URL is invalid');
      }
      if (requireHttps && uri.scheme != 'https') {
        throw const FormatException('Package URL must use HTTPS');
      }
      if (allowedHosts.isNotEmpty && !allowedHosts.contains(uri.host)) {
        throw const FormatException('Package URL host is not allowed');
      }
    }
  }
}

String buildDownloadTaskId(DownloadablePackage package) {
  return package.deterministicTaskId;
}

class InstalledResource {
  const InstalledResource({
    required this.packageId,
    required this.type,
    required this.version,
    required this.localPath,
    required this.fileSizeBytes,
    required this.status,
    this.installedSha256,
    this.installedAt,
    this.lastVerifiedAt,
    this.lastError,
  });

  final String packageId;
  final DownloadPackageType type;
  final String version;
  final String localPath;
  final int fileSizeBytes;
  final InstalledResourceStatus status;
  final String? installedSha256;
  final DateTime? installedAt;
  final DateTime? lastVerifiedAt;
  final String? lastError;

  InstalledResource copyWith({
    InstalledResourceStatus? status,
    String? localPath,
    int? fileSizeBytes,
    String? installedSha256,
    DateTime? installedAt,
    DateTime? lastVerifiedAt,
    String? lastError,
  }) {
    return InstalledResource(
      packageId: packageId,
      type: type,
      version: version,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      installedSha256: installedSha256 ?? this.installedSha256,
      installedAt: installedAt ?? this.installedAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      lastError: lastError,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'package_id': packageId,
      'type': type.name,
      'version': version,
      'local_path': localPath,
      'file_size_bytes': fileSizeBytes,
      'installed_sha256': installedSha256,
      'status': status.name,
      'installed_at': installedAt?.toIso8601String(),
      'last_verified_at': lastVerifiedAt?.toIso8601String(),
      'last_error': lastError,
    };
  }

  factory InstalledResource.fromMap(Map<String, Object?> map) {
    return InstalledResource(
      packageId: map['package_id'] as String,
      type: _typeFromName(map['type'] as String?),
      version: map['version'] as String? ?? '',
      localPath: map['local_path'] as String? ?? '',
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      installedSha256: map['installed_sha256'] as String?,
      status: _installedStatusFromName(map['status'] as String?),
      installedAt: DateTime.tryParse(map['installed_at'] as String? ?? ''),
      lastVerifiedAt:
          DateTime.tryParse(map['last_verified_at'] as String? ?? ''),
      lastError: map['last_error'] as String?,
    );
  }
}

class ReconciliationReport {
  const ReconciliationReport({
    this.missingFiles = 0,
    this.corruptedFiles = 0,
    this.orphanRecords = 0,
    this.updatedRecords = 0,
  });

  final int missingFiles;
  final int corruptedFiles;
  final int orphanRecords;
  final int updatedRecords;

  bool get hasIssues =>
      missingFiles > 0 || corruptedFiles > 0 || orphanRecords > 0;
}

class DownloadRecord {
  const DownloadRecord({
    required this.packageId,
    required this.taskId,
    required this.type,
    required this.title,
    required this.version,
    required this.fileName,
    required this.localPath,
    required this.status,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.expectedSha256,
    required this.installedSha256,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.lastError,
    this.progress = 0,
    this.speedBytesPerSecond,
    this.group = 'offline',
  });

  final String packageId;
  final String taskId;
  final DownloadPackageType type;
  final String title;
  final String version;
  final String fileName;
  final String localPath;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final String expectedSha256;
  final String installedSha256;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? lastError;
  final double progress;
  final int? speedBytesPerSecond;
  final String group;

  DownloadRecord copyWith({
    String? taskId,
    String? localPath,
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    String? installedSha256,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? lastError,
    double? progress,
    int? speedBytesPerSecond,
  }) {
    return DownloadRecord(
      packageId: packageId,
      taskId: taskId ?? this.taskId,
      type: type,
      title: title,
      version: version,
      fileName: fileName,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      expectedSha256: expectedSha256,
      installedSha256: installedSha256 ?? this.installedSha256,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      lastError: lastError,
      progress: progress ?? this.progress,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      group: group,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'package_id': packageId,
      'task_id': taskId,
      'type': type.name,
      'title': title,
      'version': version,
      'file_name': fileName,
      'local_path': localPath,
      'status': status.name,
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'expected_sha256': expectedSha256,
      'installed_sha256': installedSha256,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_error': lastError,
      'progress': progress,
      'speed_bytes_per_second': speedBytesPerSecond,
      'download_group': group,
    };
  }

  factory DownloadRecord.fromMap(Map<String, Object?> map) {
    return DownloadRecord(
      packageId: map['package_id'] as String,
      taskId: map['task_id'] as String,
      type: _typeFromName(map['type'] as String?),
      title: map['title'] as String? ?? map['package_id'] as String,
      version: map['version'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      localPath: map['local_path'] as String? ?? '',
      status: _statusFromName(map['status'] as String?),
      downloadedBytes: (map['downloaded_bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['total_bytes'] as num?)?.toInt() ?? 0,
      expectedSha256: map['expected_sha256'] as String? ?? '',
      installedSha256: map['installed_sha256'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
      lastError: map['last_error'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      speedBytesPerSecond: (map['speed_bytes_per_second'] as num?)?.toInt(),
      group: map['download_group'] as String? ?? 'offline',
    );
  }
}

DownloadPackageType _typeFromName(String? name) {
  return DownloadPackageType.values.firstWhere(
    (value) => value.name == name,
    orElse: () => DownloadPackageType.other,
  );
}

DownloadStatus _statusFromName(String? name) {
  return DownloadStatus.values.firstWhere(
    (value) => value.name == name,
    orElse: () => DownloadStatus.failed,
  );
}

InstalledResourceStatus _installedStatusFromName(String? name) {
  return InstalledResourceStatus.values.firstWhere(
    (value) => value.name == name,
    orElse: () => InstalledResourceStatus.failed,
  );
}
