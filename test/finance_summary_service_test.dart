import 'package:camperboss/core/services/finance_summary_service.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FinanceSummaryService();

  test('buildFuelStats uses only full tanks for consumption and cost per km',
      () {
    final stats = service.buildFuelStats(
      [
        FuelEntry(
          id: 'f1',
          vehicleId: 1,
          date: DateTime(2026, 6, 1),
          odometerKm: 10000,
          volumeMilliLitres: 50000,
          totalCostMinor: 9000,
          currencyCode: 'EUR',
          fullTank: true,
        ),
        FuelEntry(
          id: 'f2',
          vehicleId: 1,
          date: DateTime(2026, 6, 5),
          odometerKm: 10300,
          volumeMilliLitres: 20000,
          totalCostMinor: 3600,
          currencyCode: 'EUR',
          fullTank: false,
        ),
        FuelEntry(
          id: 'f3',
          vehicleId: 1,
          date: DateTime(2026, 6, 10),
          odometerKm: 10600,
          volumeMilliLitres: 48000,
          totalCostMinor: 8640,
          currencyCode: 'EUR',
          fullTank: true,
        ),
      ],
      now: DateTime(2026, 6, 15),
    );

    expect(stats.totalCostMinor, 21240);
    expect(stats.totalVolumeMilliLitres, 118000);
    expect(stats.averageConsumptionLitersPer100Km, closeTo(8.0, 0.01));
    expect(stats.costPerKmMinor, 35);
    expect(stats.monthlyCostMinor, 21240);
    expect(stats.yearlyCostMinor, 21240);
  });

  test('buildTripBudgetSummary combines expenses fuel and active bookings', () {
    final summary = service.buildTripBudgetSummary(
      trip: TripPlan(
        id: 7,
        title: 'Summer coast',
        summary: 'Two nights',
        progress: 0.6,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
      ),
      expenses: [
        Expense(
          id: 'e1',
          scope: ExpenseScope.trip,
          tripId: 7,
          category: ExpenseCategory.food,
          amountMinor: 3200,
          currencyCode: 'EUR',
          occurredAt: DateTime(2026, 8, 1),
        ),
      ],
      fuelEntries: [
        FuelEntry(
          id: 'f1',
          vehicleId: 1,
          tripId: 7,
          date: DateTime(2026, 8, 2),
          odometerKm: 1000,
          volumeMilliLitres: 30000,
          totalCostMinor: 5400,
          currencyCode: 'EUR',
          fullTank: true,
        ),
      ],
      bookings: [
        TripBooking(
          id: 'b1',
          tripId: 7,
          type: BookingType.campsite,
          status: BookingStatus.confirmed,
          title: 'Camping',
          currencyCode: 'EUR',
          costMinor: 9000,
        ),
        TripBooking(
          id: 'b2',
          tripId: 7,
          type: BookingType.activity,
          status: BookingStatus.canceled,
          title: 'Canceled',
          currencyCode: 'EUR',
          costMinor: 5000,
        ),
      ],
      budget: const TripBudget(
        tripId: 7,
        plannedAmountMinor: 25000,
        currencyCode: 'EUR',
      ),
      route: RouteResult(
        tripId: 7,
        waypointFingerprint: 'fp',
        geometry: [],
        totalDistanceMeters: 100000,
        totalDurationSeconds: 3600,
        legs: [],
        provider: 'test',
        calculatedAt: DateTime(2026, 8, 1),
      ),
    );

    expect(summary.plannedMinor, 25000);
    expect(summary.spentMinor, 17600);
    expect(summary.remainingMinor, 7400);
    expect(summary.byCategory[ExpenseCategory.food], 3200);
    expect(summary.byCategory[ExpenseCategory.fuel], 5400);
    expect(summary.byCategory[ExpenseCategory.camping], 9000);
    expect(summary.costPerDayMinor, 5867);
    expect(summary.costPerKmMinor, 176);
  });
}
