import 'dart:convert';

class TripStage {
  const TripStage({
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String name;
  final double? latitude;
  final double? longitude;

  bool get isGeocoded {
    final lat = latitude;
    final lon = longitude;
    return lat != null &&
        lon != null &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  String get legacyLabel {
    if (!isGeocoded) return name;
    return '$name | ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory TripStage.fromMap(Map<String, Object?> map) {
    return TripStage(
      name: (map['name'] as String? ?? '').trim(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  factory TripStage.fromLegacy(String value) {
    final trimmed = value.trim();
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(trimmed);
    if (match == null) return TripStage(name: trimmed);

    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);
    final name = trimmed
        .replaceFirst(match.group(0)!, '')
        .replaceAll(RegExp(r'[\|\-\(\)]'), ' ')
        .trim();

    return TripStage(
      name: name.isEmpty ? 'Stop' : name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class TripPlan {
  const TripPlan({
    required this.title,
    required this.summary,
    required this.progress,
    this.id,
    this.destination,
    this.startDate,
    this.endDate,
    this.stages = const [],
    this.stageDetails = const [],
    this.overnightStop,
    this.estimatedCost,
    this.notes,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String summary;
  final double progress;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Backward-compatible labels used by existing screens/tests/imports.
  final List<String> stages;

  /// Canonical structured stops introduced in Step 16D.
  final List<TripStage> stageDetails;

  final String? overnightStop;
  final double? estimatedCost;
  final String? notes;
  final DateTime? updatedAt;

  List<TripStage> get resolvedStages {
    if (stageDetails.isNotEmpty) return stageDetails;
    return stages
        .map(TripStage.fromLegacy)
        .where((stage) => stage.name.isNotEmpty)
        .toList(growable: false);
  }

  TripPlan copyWith({
    int? id,
    String? title,
    String? summary,
    double? progress,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stages,
    List<TripStage>? stageDetails,
    String? overnightStop,
    double? estimatedCost,
    String? notes,
    DateTime? updatedAt,
  }) {
    return TripPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      progress: progress ?? this.progress,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stages: stages ?? this.stages,
      stageDetails: stageDetails ?? this.stageDetails,
      overnightStop: overnightStop ?? this.overnightStop,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final canonicalStages = resolvedStages;
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'progress': progress,
      'destination': destination,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'stages': jsonEncode(
        canonicalStages.map((stage) => stage.toMap()).toList(),
      ),
      'overnight_stop': overnightStop,
      'estimated_cost': estimatedCost,
      'notes': notes,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory TripPlan.fromMap(Map<String, Object?> map) {
    final details = _decodeStageDetails(map['stages'] as String?);
    return TripPlan(
      id: map['id'] as int?,
      title: map['title'] as String,
      summary: map['summary'] as String,
      progress: (map['progress'] as num).toDouble(),
      destination: map['destination'] as String?,
      startDate: DateTime.tryParse(map['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(map['end_date'] as String? ?? ''),
      stages: details.map((stage) => stage.legacyLabel).toList(growable: false),
      stageDetails: details,
      overnightStop: map['overnight_stop'] as String?,
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<TripStage> _decodeStageDetails(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is String)
            TripStage.fromLegacy(item)
          else if (item is Map)
            TripStage.fromMap(Map<String, Object?>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }
}
