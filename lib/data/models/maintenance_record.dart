import 'dart:convert';

enum MaintenanceStatus {
  regular,
  dueSoon,
  overdue;

  String get label {
    return switch (this) {
      MaintenanceStatus.regular => 'Regular',
      MaintenanceStatus.dueSoon => 'Due soon',
      MaintenanceStatus.overdue => 'Overdue',
    };
  }
}

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.category,
    required this.title,
    required this.date,
    required this.mileage,
    this.id,
    this.cost,
    this.provider,
    this.notes,
    this.intervalMonths,
    this.intervalKilometers,
    this.nextDueDate,
    this.nextDueMileage,
    this.attachmentPaths = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String category;
  final String title;
  final DateTime date;
  final double mileage;
  final double? cost;
  final String? provider;
  final String? notes;
  final int? intervalMonths;
  final double? intervalKilometers;
  final DateTime? nextDueDate;
  final double? nextDueMileage;
  final List<String> attachmentPaths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceStatus status({
    DateTime? now,
    double? currentMileage,
  }) {
    final referenceDate = now ?? DateTime.now();
    final dueDate = nextDueDate;
    final dueMileage = nextDueMileage;
    final mileageNow = currentMileage;

    if (dueDate != null && !dueDate.isAfter(referenceDate)) {
      return MaintenanceStatus.overdue;
    }
    if (dueMileage != null && mileageNow != null && dueMileage <= mileageNow) {
      return MaintenanceStatus.overdue;
    }

    if (dueDate != null && dueDate.difference(referenceDate).inDays <= 30) {
      return MaintenanceStatus.dueSoon;
    }
    if (dueMileage != null &&
        mileageNow != null &&
        dueMileage - mileageNow <= 1000) {
      return MaintenanceStatus.dueSoon;
    }

    return MaintenanceStatus.regular;
  }

  MaintenanceRecord copyWith({
    int? id,
    String? category,
    String? title,
    DateTime? date,
    double? mileage,
    double? cost,
    String? provider,
    String? notes,
    int? intervalMonths,
    double? intervalKilometers,
    DateTime? nextDueDate,
    double? nextDueMileage,
    List<String>? attachmentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      cost: cost ?? this.cost,
      provider: provider ?? this.provider,
      notes: notes ?? this.notes,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      intervalKilometers: intervalKilometers ?? this.intervalKilometers,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      nextDueMileage: nextDueMileage ?? this.nextDueMileage,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'category': category,
      'title': title,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'cost': cost,
      'provider': provider,
      'notes': notes,
      'interval_months': intervalMonths,
      'interval_kilometers': intervalKilometers,
      'next_due_date': nextDueDate?.toIso8601String(),
      'next_due_mileage': nextDueMileage,
      'attachment_paths': jsonEncode(attachmentPaths),
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': (updatedAt ?? now).toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, Object?> map) {
    return MaintenanceRecord(
      id: map['id'] as int?,
      category: map['category'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      mileage: (map['mileage'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      provider: map['provider'] as String?,
      notes: map['notes'] as String?,
      intervalMonths: (map['interval_months'] as num?)?.toInt(),
      intervalKilometers: (map['interval_kilometers'] as num?)?.toDouble(),
      nextDueDate: DateTime.tryParse(map['next_due_date'] as String? ?? ''),
      nextDueMileage: (map['next_due_mileage'] as num?)?.toDouble(),
      attachmentPaths: _decodePaths(map['attachment_paths']),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<String> _decodePaths(Object? value) {
    if (value == null) return const [];
    if (value is List) return value.whereType<String>().toList();
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.whereType<String>().toList();
  }
}
