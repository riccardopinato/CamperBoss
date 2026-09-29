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
    final finance = _financeRepository;
    if (finance != null) {
      final expenses = await finance.listExpenses();
      for (final item in expenses.where((item) => item.tripId == tripId)) {
        await finance.deleteExpense(item.id);
      }

      final fuel = await finance.listFuelEntries();
      for (final item in fuel.where((item) => item.tripId == tripId)) {
        await finance.deleteFuelEntry(item.id);
      }

      final bookings = await finance.listBookings();
      for (final item in bookings.where((item) => item.tripId == tripId)) {
        await finance.deleteBooking(item.id);
      }

      await finance.deleteTripBudget(tripId);
    }

    final history = _historyService;
    if (history != null) {
      final bundle = await history.load(tripId: tripId);
      for (final track in bundle.tracks) {
        await history.deleteTrack(track);
      }
      for (final memory in bundle.memories) {
        await history.deleteMemory(memory);
      }
    }

    await _routePreviewRepository.deleteRouteForTrip(tripId);
    await _tripRepository.deleteTrip(tripId);
  }
}
