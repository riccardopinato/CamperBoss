import 'dart:convert';

enum ReminderSourceType {
  document,
  maintenance,
  booking,
  custom;

  String get storageValue => name;

  static ReminderSourceType fromStorage(String value) {
    return ReminderSourceType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => ReminderSourceType.custom,
    );
  }
}

class ReminderPayload {
  const ReminderPayload({
    required this.sourceType,
    required this.sourceId,
  });

  final ReminderSourceType sourceType;
  final String sourceId;

  String encode() {
    return jsonEncode({
      'type': sourceType.storageValue,
      'id': sourceId,
    });
  }

  static ReminderPayload? tryParse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final type = decoded['type'] as String?;
      final id = decoded['id'] as String?;
      if (type == null || id == null || id.isEmpty) return null;
      return ReminderPayload(
        sourceType: ReminderSourceType.fromStorage(type),
        sourceId: id,
      );
    } catch (_) {
      return null;
    }
  }
}

class AppReminder {
  AppReminder({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    int? notificationId,
    String? payload,
    this.enabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : notificationId = notificationId ?? stableNotificationId(id),
        payload = payload ??
            ReminderPayload(
              sourceType: sourceType,
              sourceId: sourceId,
            ).encode(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final ReminderSourceType sourceType;
  final String sourceId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final int notificationId;
  final String payload;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppReminder copyWith({
    String? id,
    ReminderSourceType? sourceType,
    String? sourceId,
    String? title,
    String? body,
    DateTime? scheduledAt,
    int? notificationId,
    String? payload,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppReminder(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      payload: payload ?? this.payload,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'source_type': sourceType.storageValue,
      'source_id': sourceId,
      'title': title,
      'body': body,
      'scheduled_at': scheduledAt.toIso8601String(),
      'notification_id': notificationId,
      'payload': payload,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppReminder.fromMap(Map<String, Object?> map) {
    final id = map['id'] as String;
    return AppReminder(
      id: id,
      sourceType: ReminderSourceType.fromStorage(map['source_type'] as String),
      sourceId: map['source_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      notificationId:
          (map['notification_id'] as num?)?.toInt() ?? stableNotificationId(id),
      payload: map['payload'] as String?,
      enabled: (map['enabled'] as num?)?.toInt() != 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.advanceDays = const [30, 7, 1, 0],
  });

  final bool enabled;
  final List<int> advanceDays;

  ReminderSettings copyWith({
    bool? enabled,
    List<int>? advanceDays,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      advanceDays: advanceDays ?? this.advanceDays,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 'default',
      'enabled': enabled ? 1 : 0,
      'advance_days': jsonEncode(advanceDays),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ReminderSettings.fromMap(Map<String, Object?> map) {
    return ReminderSettings(
      enabled: (map['enabled'] as num?)?.toInt() != 0,
      advanceDays: _decodeDays(map['advance_days']),
    );
  }

  static List<int> _decodeDays(Object? value) {
    if (value is List) return value.whereType<int>().toList();
    if (value is! String || value.isEmpty) return const [30, 7, 1, 0];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.map((item) => (item as num).toInt()).toList();
  }
}

int stableNotificationId(String value) {
  const prime = 16777619;
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * prime) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
