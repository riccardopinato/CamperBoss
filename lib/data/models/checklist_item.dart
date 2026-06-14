class CamperChecklistItem {
  const CamperChecklistItem({
    required this.title,
    required this.checked,
    this.id,
    this.subtitle,
    this.category = 'General',
    this.position = 0,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final bool checked;
  final String? subtitle;
  final String category;
  final int position;
  final DateTime? updatedAt;

  CamperChecklistItem copyWith({
    int? id,
    String? title,
    bool? checked,
    String? subtitle,
    String? category,
    int? position,
    DateTime? updatedAt,
  }) {
    return CamperChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      checked: checked ?? this.checked,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'checked': checked ? 1 : 0,
      'position': position,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory CamperChecklistItem.fromMap(Map<String, Object?> map) {
    return CamperChecklistItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      category: (map['category'] as String?) ?? 'General',
      checked: (map['checked'] as int? ?? 0) == 1,
      position: map['position'] as int? ?? 0,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}
