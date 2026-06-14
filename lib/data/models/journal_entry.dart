class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.summary,
    this.id,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String summary;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  JournalEntry copyWith({
    int? id,
    String? title,
    String? summary,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    return JournalEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      summary: map['summary'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}
