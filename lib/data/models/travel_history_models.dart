import 'dart:convert';

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime? recordedAt;

  Map<String, Object?> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }

  factory GeoPoint.fromMap(Map<String, Object?> map) {
    return GeoPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),
      recordedAt: DateTime.tryParse(map['recordedAt'] as String? ?? ''),
    );
  }
}

class GpxTrack {
  const GpxTrack({
    required this.id,
    required this.name,
    required this.points,
    required this.distanceMeters,
    this.tripId,
    this.duration,
    this.elevationGainMeters,
    this.localFilePath,
    this.originalPointCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int? tripId;
  final String name;
  final List<GeoPoint> points;
  final double distanceMeters;
  final Duration? duration;
  final double? elevationGainMeters;
  final String? localFilePath;
  final int? originalPointCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GpxTrack copyWith({
    String? id,
    int? tripId,
    String? name,
    List<GeoPoint>? points,
    double? distanceMeters,
    Duration? duration,
    double? elevationGainMeters,
    String? localFilePath,
    int? originalPointCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GpxTrack(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      duration: duration ?? this.duration,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      localFilePath: localFilePath ?? this.localFilePath,
      originalPointCount: originalPointCount ?? this.originalPointCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'points': jsonEncode(points.map((point) => point.toMap()).toList()),
      'distance_meters': distanceMeters,
      'duration_seconds': duration?.inSeconds,
      'elevation_gain_meters': elevationGainMeters,
      'local_file_path': localFilePath,
      'original_point_count': originalPointCount,
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': (updatedAt ?? now).toIso8601String(),
    };
  }

  factory GpxTrack.fromMap(Map<String, Object?> map) {
    return GpxTrack(
      id: map['id'] as String,
      tripId: (map['trip_id'] as num?)?.toInt(),
      name: map['name'] as String,
      points: _decodePoints(map['points']),
      distanceMeters: (map['distance_meters'] as num?)?.toDouble() ?? 0,
      duration: (map['duration_seconds'] as num?) == null
          ? null
          : Duration(seconds: (map['duration_seconds'] as num).round()),
      elevationGainMeters: (map['elevation_gain_meters'] as num?)?.toDouble(),
      localFilePath: map['local_file_path'] as String?,
      originalPointCount: (map['original_point_count'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<GeoPoint> _decodePoints(Object? value) {
    if (value == null) return const [];
    final decoded = value is String ? jsonDecode(value) : value;
    if (decoded is! List) return const [];
    return decoded
        .map((item) => GeoPoint.fromMap(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }
}

class TravelMemory {
  const TravelMemory({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.occurredAt,
    this.tripId,
    this.description,
    this.localPhotoPaths = const [],
    this.poiId,
    this.tags = const {},
    this.favorite = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int? tripId;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime occurredAt;
  final List<String> localPhotoPaths;
  final String? poiId;
  final Set<String> tags;
  final bool favorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TravelMemory copyWith({
    String? id,
    int? tripId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? occurredAt,
    List<String>? localPhotoPaths,
    String? poiId,
    Set<String>? tags,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TravelMemory(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      occurredAt: occurredAt ?? this.occurredAt,
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
      poiId: poiId ?? this.poiId,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'occurred_at': occurredAt.toIso8601String(),
      'local_photo_paths': jsonEncode(localPhotoPaths),
      'poi_id': poiId,
      'tags': jsonEncode(tags.toList()..sort()),
      'favorite': favorite ? 1 : 0,
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': (updatedAt ?? now).toIso8601String(),
    };
  }

  factory TravelMemory.fromMap(Map<String, Object?> map) {
    return TravelMemory(
      id: map['id'] as String,
      tripId: (map['trip_id'] as num?)?.toInt(),
      title: map['title'] as String,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      localPhotoPaths: _decodeStrings(map['local_photo_paths']),
      poiId: map['poi_id'] as String?,
      tags: _decodeStrings(map['tags']).toSet(),
      favorite: (map['favorite'] as num?)?.toInt() == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<String> _decodeStrings(Object? value) {
    if (value == null) return const [];
    final decoded = value is String ? jsonDecode(value) : value;
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList(growable: false);
  }
}

class TravelHistoryStats {
  const TravelHistoryStats({
    required this.distanceMeters,
    required this.trackDays,
    required this.placeCount,
    required this.totalCostMinor,
    required this.totalFuelLiters,
    this.costByCurrency = const {},
    this.duration,
    this.elevationGainMeters,
    this.averageSpeedKmh,
    this.consumptionLitersPer100Km,
  });

  final double distanceMeters;
  final int trackDays;
  final int placeCount;
  /// Backward-compatible total. It is populated only when all linked costs
  /// share one currency; mixed currencies are never added together.
  final int totalCostMinor;
  final double totalFuelLiters;
  final Map<String, int> costByCurrency;

  bool get hasMixedCurrencies => costByCurrency.length > 1;

  final Duration? duration;
  final double? elevationGainMeters;
  final double? averageSpeedKmh;
  final double? consumptionLitersPer100Km;
}

class PhotoLocationCandidate {
  const PhotoLocationCandidate({
    required this.path,
    this.previewBytes,
    this.latitude,
    this.longitude,
    this.recordedAt,
  });

  final String path;
  final List<int>? previewBytes;
  final double? latitude;
  final double? longitude;
  final DateTime? recordedAt;

  bool get hasCoordinates => latitude != null && longitude != null;
}
