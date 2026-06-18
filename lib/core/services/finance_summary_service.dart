import '../../data/models/finance_models.dart';
import '../../data/models/route_preview.dart';
import '../../data/models/trip_plan.dart';

class FuelStats {
  const FuelStats({
    required this.totalCostMinor,
    required this.totalVolumeMilliLitres,
    this.averageConsumptionLitersPer100Km,
    this.costPerKmMinor,
    this.monthlyCostMinor = 0,
    this.yearlyCostMinor = 0,
  });

  final int totalCostMinor;
  final int totalVolumeMilliLitres;
  final double? averageConsumptionLitersPer100Km;
  final int? costPerKmMinor;
  final int monthlyCostMinor;
  final int yearlyCostMinor;
}

class FinanceSummaryService {
  const FinanceSummaryService();

  FuelStats buildFuelStats(
    List<FuelEntry> entries, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final totalCost = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.totalCostMinor,
    );
    final totalVolume = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.volumeMilliLitres,
    );
    var totalDistanceKm = 0;
    var fullTankVolumeLiters = 0.0;
    FuelEntry? previousFullTank;
    for (final entry in sorted) {
      if (!entry.fullTank) continue;
      if (previousFullTank != null &&
          entry.odometerKm > previousFullTank.odometerKm) {
        totalDistanceKm += entry.odometerKm - previousFullTank.odometerKm;
        fullTankVolumeLiters += entry.liters;
      }
      previousFullTank = entry;
    }

    final monthCost = entries
        .where((entry) =>
            entry.date.year == reference.year &&
            entry.date.month == reference.month)
        .fold<int>(0, (sum, entry) => sum + entry.totalCostMinor);
    final yearCost = entries
        .where((entry) => entry.date.year == reference.year)
        .fold<int>(0, (sum, entry) => sum + entry.totalCostMinor);

    return FuelStats(
      totalCostMinor: totalCost,
      totalVolumeMilliLitres: totalVolume,
      averageConsumptionLitersPer100Km: totalDistanceKm <= 0
          ? null
          : (fullTankVolumeLiters / totalDistanceKm) * 100,
      costPerKmMinor:
          totalDistanceKm <= 0 ? null : (totalCost / totalDistanceKm).round(),
      monthlyCostMinor: monthCost,
      yearlyCostMinor: yearCost,
    );
  }

  BudgetSummary buildTripBudgetSummary({
    required TripPlan trip,
    required List<Expense> expenses,
    required List<FuelEntry> fuelEntries,
    required List<TripBooking> bookings,
    TripBudget? budget,
    RouteResult? route,
  }) {
    final byCategory = <ExpenseCategory, int>{};
    var spent = 0;

    for (final expense in expenses.where((item) => item.tripId == trip.id)) {
      spent += expense.amountMinor;
      byCategory.update(
        expense.category,
        (value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }

    final tripFuel = fuelEntries.where((entry) => entry.tripId == trip.id);
    final fuelCost = tripFuel.fold<int>(
      0,
      (sum, entry) => sum + entry.totalCostMinor,
    );
    spent += fuelCost;
    if (fuelCost > 0) {
      byCategory.update(
        ExpenseCategory.fuel,
        (value) => value + fuelCost,
        ifAbsent: () => fuelCost,
      );
    }

    for (final booking in bookings.where((item) =>
        item.tripId == trip.id &&
        item.status != BookingStatus.canceled &&
        item.costMinor != null)) {
      final cost = booking.costMinor!;
      spent += cost;
      final category = _bookingToExpenseCategory(booking.type);
      byCategory.update(
        category,
        (value) => value + cost,
        ifAbsent: () => cost,
      );
    }

    final planned = budget?.plannedAmountMinor ?? 0;
    final days = _tripDays(trip);
    final routeKm = route == null ? null : route.totalDistanceMeters / 1000;

    return BudgetSummary(
      plannedMinor: planned,
      spentMinor: spent,
      remainingMinor: planned - spent,
      byCategory: byCategory,
      costPerDayMinor: days == null || days <= 0 ? null : (spent / days).round(),
      costPerKmMinor:
          routeKm == null || routeKm <= 0 ? null : (spent / routeKm).round(),
    );
  }

  int? _tripDays(TripPlan trip) {
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null || end == null) return null;
    final difference = end.difference(start).inDays + 1;
    return difference <= 0 ? null : difference;
  }

  ExpenseCategory _bookingToExpenseCategory(BookingType type) {
    return switch (type) {
      BookingType.campsite || BookingType.camperArea => ExpenseCategory.camping,
      BookingType.ferry => ExpenseCategory.ferry,
      BookingType.activity => ExpenseCategory.activity,
      BookingType.restaurant => ExpenseCategory.food,
      BookingType.transport => ExpenseCategory.other,
      BookingType.insurance => ExpenseCategory.insurance,
      BookingType.vignette => ExpenseCategory.vignette,
      BookingType.other => ExpenseCategory.other,
    };
  }
}
