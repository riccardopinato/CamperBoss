class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.summary,
    this.id,
    this.createdAt,
    this.place,
    this.kilometers,
    this.cost,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String summary;
  final DateTime? createdAt;
  final String? place;
  final double? kilometers;
  final double? cost;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  JournalEntry copyWith({
    int? id,
    String? title,
    String? summary,
    DateTime? createdAt,
    String? place,
    double? kilometers,
    double? cost,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      place: place ?? this.place,
      kilometers: kilometers ?? this.kilometers,
      cost: cost ?? this.cost,
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
      'place': place,
      'kilometers': kilometers,
      'cost': cost,
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
      place: map['place'] as String?,
      kilometers: (map['kilometers'] as num?)?.toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}
