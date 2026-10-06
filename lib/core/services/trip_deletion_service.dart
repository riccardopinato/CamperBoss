import '../../data/models/finance_models.dart';
import '../../data/models/route_preview.dart';
import '../../data/models/travel_history_models.dart';
import '../../data/models/trip_plan.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_route_preview_repository.dart';
import '../../data/repositories/local_trip_repository.dart';
import 'travel_history_service.dart';

class TripDeletionService {
  TripDeletionService({
    required TripRepository tripRepository,
    required RoutePreviewRepository routePreviewRepository,
    FinanceRepository? financeRepository,
    TravelHistoryService? historyService,
  })  : _tripRepository = tripRepository,
        _routePreviewRepository = routePreviewRepository,
        _financeRepository = financeRepository,
        _historyService = historyService;

  final TripRepository _tripRepository;
  final RoutePreviewRepository _routePreviewRepository;
  final FinanceRepository? _financeRepository;
  final TravelHistoryService? _historyService;

  Future<void> deleteTrip(int tripId) async {
    final snapshot = await _capture(tripId);
    if (snapshot.trip == null) return;

    try {
      await _deleteRecords(snapshot);
    } catch (error, stackTrace) {
      try {
        await _rollback(snapshot);
      } catch (rollbackError) {
        throw StateError(
          'Trip deletion failed and rollback failed. '
          'Original: $error. Rollback: $rollbackError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    // Media deletion happens only after the logical cascade has committed.
    // A cleanup failure may leave an orphan file but cannot destroy data
    // required to roll the cascade back.
    final history = _historyService;
    if (history != null) {
      try {
        await history.cleanupUnreferencedTrackFiles(
          snapshot.tracks.map((item) => item.localFilePath),
        );
        await history.cleanupUnreferencedMemoryFiles(
          snapshot.memories.expand((item) => item.localPhotoPaths),
        );
      } catch (_) {
        // Storage reconciliation can retry orphan cleanup later.
      }
    }
  }

  Future<_TripDeletionSnapshot> _capture(int tripId) async {
    final trips = await _tripRepository.listTrips();
    TripPlan? trip;
    for (final candidate in trips) {
      if (candidate.id == tripId) {
        trip = candidate;
        break;
      }
    }

    final route = await _routePreviewRepository.loadRouteForTrip(tripId);
    final finance = _financeRepository;
    final expenses = finance == null
        ? const <Expense>[]
        : (await finance.listExpenses())
            .where((item) => item.tripId == tripId)
            .toList(growable: false);
    final fuel = finance == null
        ? const <FuelEntry>[]
        : (await finance.listFuelEntries())
            .where((item) => item.tripId == tripId)
            .toList(growable: false);
    final bookings = finance == null
        ? const <TripBooking>[]
        : (await finance.listBookings())
            .where((item) => item.tripId == tripId)
            .toList(growable: false);
    final budget = finance == null ? null : await finance.loadTripBudget(tripId);

    final history = _historyService;
    final bundle = history == null ? null : await history.load(tripId: tripId);

    return _TripDeletionSnapshot(
      trip: trip,
      route: route,
      expenses: expenses,
      fuel: fuel,
      bookings: bookings,
      budget: budget,
      tracks: bundle?.tracks ?? const <GpxTrack>[],
      memories: bundle?.memories ?? const <TravelMemory>[],
    );
  }

  Future<void> _deleteRecords(_TripDeletionSnapshot snapshot) async {
    final trip = snapshot.trip;
    if (trip?.id == null) return;
    final tripId = trip!.id!;

    final finance = _financeRepository;
    if (finance != null) {
      for (final item in snapshot.bookings) {
        await finance.deleteBooking(item.id);
      }
      for (final item in snapshot.fuel) {
        await finance.deleteFuelEntry(item.id);
      }
      for (final item in snapshot.expenses) {
        await finance.deleteExpense(item.id);
      }
      await finance.deleteTripBudget(tripId);
    }

    final history = _historyService;
    if (history != null) {
      for (final track in snapshot.tracks) {
        await history.deleteTrack(track, deleteMedia: false);
      }
      for (final memory in snapshot.memories) {
        await history.deleteMemory(memory, deleteMedia: false);
      }
    }

    await _routePreviewRepository.deleteRouteForTrip(tripId);
    await _tripRepository.deleteTrip(tripId);
  }

  Future<void> _rollback(_TripDeletionSnapshot snapshot) async {
    final trip = snapshot.trip;
    if (trip == null) return;

    await _tripRepository.saveTrip(trip);

    final finance = _financeRepository;
    if (finance != null) {
      if (snapshot.budget != null) {
        await finance.saveTripBudget(snapshot.budget!);
      }
      for (final item in snapshot.expenses) {
        await finance.saveExpense(item);
      }
      for (final item in snapshot.fuel) {
        await finance.saveFuelEntry(item);
      }
      for (final item in snapshot.bookings) {
        await finance.saveBooking(item);
      }
    }

    final history = _historyService;
    if (history != null) {
      for (final track in snapshot.tracks) {
        await history.saveTrack(track);
      }
      for (final memory in snapshot.memories) {
        await history.saveMemory(memory);
      }
    }

    if (snapshot.route != null) {
      await _routePreviewRepository.saveRoute(snapshot.route!);
    }
  }
}

class _TripDeletionSnapshot {
  const _TripDeletionSnapshot({
    required this.trip,
    required this.route,
    required this.expenses,
    required this.fuel,
    required this.bookings,
    required this.budget,
    required this.tracks,
    required this.memories,
  });

  final TripPlan? trip;
  final RouteResult? route;
  final List<Expense> expenses;
  final List<FuelEntry> fuel;
  final List<TripBooking> bookings;
  final TripBudget? budget;
  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;
}
