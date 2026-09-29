import 'package:camperboss/core/services/travel_history_statistics_service.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/models/travel_history_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds statistics from tracks memories and finance data', () {
    const service = TravelHistoryStatisticsService();

    final stats = service.build(
      tracks: [
        GpxTrack(
          id: 'track-1',
          tripId: 5,
          name: 'Trip',
          points: [
            GeoPoint(
              latitude: 45.0,
              longitude: 10.0,
              recordedAt: DateTime(2026, 6, 1, 10),
            ),
            GeoPoint(
              latitude: 45.1,
              longitude: 10.1,
              recordedAt: DateTime(2026, 6, 1, 12),
            ),
          ],
          distanceMeters: 100000,
          duration: Duration(hours: 2),
          elevationGainMeters: 450,
        ),
      ],
      memories: [
        TravelMemory(
          id: 'memory-1',
          tripId: 5,
          title: 'Stop',
          latitude: 45.2,
          longitude: 10.2,
          occurredAt: DateTime(2026, 6, 2, 8),
        ),
      ],
      journalEntries: [
        JournalEntry(
          id: 1,
          title: 'Day note',
          summary: 'Summary',
          createdAt: DateTime(2026, 6, 3, 9),
          place: 'Verona',
        ),
      ],
      expenses: [
        Expense(
          id: 'expense-1',
          scope: ExpenseScope.trip,
          tripId: 5,
          category: ExpenseCategory.food,
          amountMinor: 1200,
          currencyCode: 'EUR',
          occurredAt: DateTime(2026, 6, 2),
        ),
      ],
      fuelEntries: [
        FuelEntry(
          id: 'fuel-1',
          vehicleId: 1,
          tripId: 5,
          date: DateTime(2026, 6, 2),
          odometerKm: 1000,
          volumeMilliLitres: 10000,
          totalCostMinor: 1800,
          currencyCode: 'EUR',
          fullTank: true,
        ),
      ],
      bookings: [
        TripBooking(
          id: 'booking-1',
          tripId: 5,
          type: BookingType.campsite,
          status: BookingStatus.confirmed,
          title: 'Stay',
          costMinor: 3000,
          currencyCode: 'EUR',
        ),
      ],
    );

    expect(stats.distanceMeters, 100000);
    expect(stats.trackDays, 3);
    expect(stats.placeCount, 2);
    expect(stats.totalCostMinor, 6000);
    expect(stats.totalFuelLiters, 10);
    expect(stats.averageSpeedKmh, 50);
    expect(stats.consumptionLitersPer100Km, 10);
    expect(stats.elevationGainMeters, 450);
  });

  test('does not add incompatible currencies together', () {
    const service = TravelHistoryStatisticsService();

    final stats = service.build(
      tracks: const [],
      memories: const [],
      journalEntries: const [],
      expenses: [
        Expense(
          id: 'eur',
          scope: ExpenseScope.trip,
          tripId: 1,
          category: ExpenseCategory.food,
          amountMinor: 1200,
          currencyCode: 'EUR',
          occurredAt: DateTime(2026, 9, 1),
        ),
        Expense(
          id: 'chf',
          scope: ExpenseScope.trip,
          tripId: 1,
          category: ExpenseCategory.toll,
          amountMinor: 900,
          currencyCode: 'CHF',
          occurredAt: DateTime(2026, 9, 1),
        ),
      ],
      fuelEntries: const [],
      bookings: const [],
    );

    expect(stats.hasMixedCurrencies, isTrue);
    expect(stats.totalCostMinor, 0);
    expect(stats.costByCurrency['EUR'], 1200);
    expect(stats.costByCurrency['CHF'], 900);
  });
}
