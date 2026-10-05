import 'dart:convert';

import 'package:intl/intl.dart';

enum ExpenseScope {
  vehicle,
  trip,
  maintenance,
}

enum ExpenseCategory {
  fuel,
  adBlue,
  toll,
  vignette,
  camping,
  parking,
  food,
  maintenance,
  ferry,
  activity,
  insurance,
  other,
}

enum BookingType {
  campsite,
  camperArea,
  ferry,
  activity,
  restaurant,
  transport,
  insurance,
  vignette,
  other,
}

enum BookingStatus {
  confirmed,
  canceled,
  completed,
}

class Expense {
  const Expense({
    required this.id,
    required this.scope,
    required this.category,
    required this.amountMinor,
    required this.currencyCode,
    required this.occurredAt,
    this.vehicleId,
    this.tripId,
    this.title,
    this.notes,
    this.documentId,
  });

  final String id;
  final ExpenseScope scope;
  final int? vehicleId;
  final int? tripId;
  final ExpenseCategory category;
  final int amountMinor;
  final String currencyCode;
  final DateTime occurredAt;
  final String? title;
  final String? notes;
  final int? documentId;

  Expense copyWith({
    String? id,
    ExpenseScope? scope,
    int? vehicleId,
    int? tripId,
    ExpenseCategory? category,
    int? amountMinor,
    String? currencyCode,
    DateTime? occurredAt,
    String? title,
    String? notes,
    int? documentId,
  }) {
    return Expense(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      vehicleId: vehicleId ?? this.vehicleId,
      tripId: tripId ?? this.tripId,
      category: category ?? this.category,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      occurredAt: occurredAt ?? this.occurredAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'scope': scope.name,
      'vehicle_id': vehicleId,
      'trip_id': tripId,
      'category': category.name,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'occurred_at': occurredAt.toIso8601String(),
      'title': title,
      'notes': notes,
      'document_id': documentId,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as String,
      scope: ExpenseScope.values.firstWhere(
        (value) => value.name == map['scope'],
        orElse: () => ExpenseScope.trip,
      ),
      vehicleId: (map['vehicle_id'] as num?)?.toInt(),
      tripId: (map['trip_id'] as num?)?.toInt(),
      category: ExpenseCategory.values.firstWhere(
        (value) => value.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amountMinor: (map['amount_minor'] as num).toInt(),
      currencyCode: map['currency_code'] as String? ?? 'EUR',
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      title: map['title'] as String?,
      notes: map['notes'] as String?,
      documentId: (map['document_id'] as num?)?.toInt(),
    );
  }
}

class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.volumeMilliLitres,
    required this.totalCostMinor,
    required this.currencyCode,
    required this.fullTank,
    this.tripId,
    this.station,
    this.latitude,
    this.longitude,
    this.notes,
    this.documentId,
  });

  final String id;
  final int vehicleId;
  final int? tripId;
  final DateTime date;
  final int odometerKm;
  final int volumeMilliLitres;
  final int totalCostMinor;
  final String currencyCode;
  final bool fullTank;
  final String? station;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final int? documentId;

  double get liters => volumeMilliLitres / 1000.0;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'trip_id': tripId,
      'date': date.toIso8601String(),
      'odometer_km': odometerKm,
      'volume_ml': volumeMilliLitres,
      'total_cost_minor': totalCostMinor,
      'currency_code': currencyCode,
      'full_tank': fullTank ? 1 : 0,
      'station': station,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'document_id': documentId,
    };
  }

  factory FuelEntry.fromMap(Map<String, Object?> map) {
    return FuelEntry(
      id: map['id'] as String,
      vehicleId: (map['vehicle_id'] as num).toInt(),
      tripId: (map['trip_id'] as num?)?.toInt(),
      date: DateTime.parse(map['date'] as String),
      odometerKm: (map['odometer_km'] as num).toInt(),
      volumeMilliLitres: (map['volume_ml'] as num).toInt(),
      totalCostMinor: (map['total_cost_minor'] as num).toInt(),
      currencyCode: map['currency_code'] as String? ?? 'EUR',
      fullTank: (map['full_tank'] as num?)?.toInt() == 1,
      station: map['station'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      documentId: (map['document_id'] as num?)?.toInt(),
    );
  }
}

class TripBudget {
  const TripBudget({
    required this.tripId,
    required this.plannedAmountMinor,
    required this.currencyCode,
  });

  final int tripId;
  final int plannedAmountMinor;
  final String currencyCode;

  Map<String, Object?> toMap() {
    return {
      'trip_id': tripId,
      'planned_amount_minor': plannedAmountMinor,
      'currency_code': currencyCode,
    };
  }

  factory TripBudget.fromMap(Map<String, Object?> map) {
    return TripBudget(
      tripId: (map['trip_id'] as num).toInt(),
      plannedAmountMinor: (map['planned_amount_minor'] as num).toInt(),
      currencyCode: map['currency_code'] as String? ?? 'EUR',
    );
  }
}

class BudgetSummary {
  const BudgetSummary({
    required this.plannedMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.byCategory,
    this.costPerDayMinor,
    this.costPerKmMinor,
  });

  final int plannedMinor;
  final int spentMinor;
  final int remainingMinor;
  final Map<ExpenseCategory, int> byCategory;
  final int? costPerDayMinor;
  final int? costPerKmMinor;
}

class TripBooking {
  const TripBooking({
    required this.id,
    required this.tripId,
    required this.type,
    required this.status,
    required this.title,
    required this.currencyCode,
    this.startsAt,
    this.endsAt,
    this.address,
    this.bookingCode,
    this.costMinor,
    this.contact,
    this.notes,
    this.documentId,
    this.poiId,
  });

  final String id;
  final int tripId;
  final BookingType type;
  final BookingStatus status;
  final String title;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? address;
  final String? bookingCode;
  final int? costMinor;
  final String currencyCode;
  final String? contact;
  final String? notes;
  final int? documentId;
  final String? poiId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'type': type.name,
      'status': status.name,
      'title': title,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'address': address,
      'booking_code': bookingCode,
      'cost_minor': costMinor,
      'currency_code': currencyCode,
      'contact': contact,
      'notes': notes,
      'document_id': documentId,
      'poi_id': poiId,
    };
  }

  factory TripBooking.fromMap(Map<String, Object?> map) {
    return TripBooking(
      id: map['id'] as String,
      tripId: (map['trip_id'] as num).toInt(),
      type: BookingType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => BookingType.other,
      ),
      status: BookingStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      title: map['title'] as String,
      startsAt: DateTime.tryParse(map['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(map['ends_at'] as String? ?? ''),
      address: map['address'] as String?,
      bookingCode: map['booking_code'] as String?,
      costMinor: (map['cost_minor'] as num?)?.toInt(),
      currencyCode: map['currency_code'] as String? ?? 'EUR',
      contact: map['contact'] as String?,
      notes: map['notes'] as String?,
      documentId: (map['document_id'] as num?)?.toInt(),
      poiId: map['poi_id'] as String?,
    );
  }
}

int parseAmountMinor(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return 0;
  final value = double.parse(normalized);
  return (value * 100).round();
}

String formatAmountMinor(int amountMinor, {String currencyCode = 'EUR'}) {
  final amount = amountMinor / 100;
  return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
}

String encodeIntList(List<int> values) => jsonEncode(values);
