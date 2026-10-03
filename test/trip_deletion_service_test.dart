import 'package:camperboss/core/services/trip_deletion_service.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/repositories/local_finance_repository.dart';
import 'package:camperboss/data/repositories/local_route_preview_repository.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Trips implements TripRepository {
  final trips = <TripPlan>[
    const TripPlan(id: 7, title: 'Trip', summary: '', progress: 0),
  ];

  @override
  Future<void> deleteTrip(int id) async {
    trips.removeWhere((trip) => trip.id == id);
  }

  @override
  Future<List<TripPlan>> listTrips() async => [...trips];

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async {
    final index = trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      trips.add(trip);
    } else {
      trips[index] = trip;
    }
    return trip;
  }
}

class _Routes implements RoutePreviewRepository {
  bool deleted = false;
  bool failDelete = false;

  @override
  Future<void> deleteRouteForTrip(int tripId) async {
    deleted = true;
    if (failDelete) throw StateError('forced route delete failure');
  }

  @override
  Future<RouteResult?> loadRouteForTrip(int tripId) async => null;

  @override
  Future<RouteResult> saveRoute(RouteResult route) async => route;
}

class _Finance implements FinanceRepository {
  final expenses = <Expense>[
    Expense(
      id: 'linked',
      scope: ExpenseScope.trip,
      tripId: 7,
      category: ExpenseCategory.food,
      amountMinor: 100,
      currencyCode: 'EUR',
      occurredAt: DateTime(2026, 9, 1),
    ),
    Expense(
      id: 'other',
      scope: ExpenseScope.trip,
      tripId: 8,
      category: ExpenseCategory.food,
      amountMinor: 200,
      currencyCode: 'EUR',
      occurredAt: DateTime(2026, 9, 1),
    ),
  ];
  final fuel = <FuelEntry>[];
  final bookings = <TripBooking>[];
  final deletedBudgets = <int>[];
  TripBudget? budget =
      const TripBudget(tripId: 7, plannedAmountMinor: 1000, currencyCode: 'EUR');

  @override
  Future<void> deleteBooking(String id) async =>
      bookings.removeWhere((item) => item.id == id);

  @override
  Future<void> deleteExpense(String id) async =>
      expenses.removeWhere((item) => item.id == id);

  @override
  Future<void> deleteFuelEntry(String id) async =>
      fuel.removeWhere((item) => item.id == id);

  @override
  Future<void> deleteTripBudget(int tripId) async {
    deletedBudgets.add(tripId);
    if (budget?.tripId == tripId) budget = null;
  }

  @override
  Future<List<TripBooking>> listBookings() async => [...bookings];

  @override
  Future<List<Expense>> listExpenses() async => [...expenses];

  @override
  Future<List<FuelEntry>> listFuelEntries() async => [...fuel];

  @override
  Future<TripBudget?> loadTripBudget(int tripId) async =>
      budget?.tripId == tripId ? budget : null;

  @override
  Future<TripBooking> saveBooking(TripBooking booking) async {
    final index = bookings.indexWhere((item) => item.id == booking.id);
    if (index == -1) {
      bookings.add(booking);
    } else {
      bookings[index] = booking;
    }
    return booking;
  }

  @override
  Future<Expense> saveExpense(Expense expense) async {
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      expenses.add(expense);
    } else {
      expenses[index] = expense;
    }
    return expense;
  }

  @override
  Future<FuelEntry> saveFuelEntry(FuelEntry entry) async {
    final index = fuel.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      fuel.add(entry);
    } else {
      fuel[index] = entry;
    }
    return entry;
  }

  @override
  Future<void> saveTripBudget(TripBudget budget) async {
    this.budget = budget;
    deletedBudgets.remove(budget.tripId);
  }
}

void main() {
  test('trip deletion cascades through linked finance and route data', () async {
    final trips = _Trips();
    final routes = _Routes();
    final finance = _Finance();
    final service = TripDeletionService(
      tripRepository: trips,
      routePreviewRepository: routes,
      financeRepository: finance,
    );

    await service.deleteTrip(7);

    expect(trips.trips, isEmpty);
    expect(routes.deleted, isTrue);
    expect(finance.expenses.map((item) => item.id), ['other']);
    expect(finance.deletedBudgets, [7]);
    expect(finance.budget, isNull);
  });

  test('trip deletion restores already-deleted records when cascade fails',
      () async {
    final trips = _Trips();
    final routes = _Routes()..failDelete = true;
    final finance = _Finance();
    final service = TripDeletionService(
      tripRepository: trips,
      routePreviewRepository: routes,
      financeRepository: finance,
    );

    await expectLater(service.deleteTrip(7), throwsStateError);

    expect(trips.trips.map((item) => item.id), contains(7));
    expect(finance.expenses.map((item) => item.id), contains('linked'));
    expect(finance.deletedBudgets, isNot(contains(7)));
    expect(finance.budget?.tripId, 7);
  });
}
