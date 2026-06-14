import 'dart:convert';

class TripPlan {
  const TripPlan({
    required this.title,
    required this.summary,
    required this.progress,
    this.id,
    this.startDate,
    this.endDate,
    this.stages = const [],
    this.overnightStop,
    this.estimatedCost,
    this.notes,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String summary;
  final double progress;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> stages;
  final String? overnightStop;
  final double? estimatedCost;
  final String? notes;
  final DateTime? updatedAt;

  TripPlan copyWith({
    int? id,
    String? title,
    String? summary,
    double? progress,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stages,
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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stages: stages ?? this.stages,
      overnightStop: overnightStop ?? this.overnightStop,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'progress': progress,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'stages': jsonEncode(stages),
      'overnight_stop': overnightStop,
      'estimated_cost': estimatedCost,
      'notes': notes,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory TripPlan.fromMap(Map<String, Object?> map) {
    return TripPlan(
      id: map['id'] as int?,
      title: map['title'] as String,
      summary: map['summary'] as String,
      progress: (map['progress'] as num).toDouble(),
      startDate: DateTime.tryParse(map['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(map['end_date'] as String? ?? ''),
      stages: _decodeStages(map['stages'] as String?),
      overnightStop: map['overnight_stop'] as String?,
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<String> _decodeStages(String? value) {
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.whereType<String>().toList();
  }
}
