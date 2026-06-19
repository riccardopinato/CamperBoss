import '../../data/models/finance_models.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/travel_history_models.dart';

class TravelHistoryStatisticsService {
  const TravelHistoryStatisticsService();

  TravelHistoryStats build({
    required List<GpxTrack> tracks,
    required List<TravelMemory> memories,
    required List<JournalEntry> journalEntries,
    required List<Expense> expenses,
    required List<FuelEntry> fuelEntries,
    required List<TripBooking> bookings,
  }) {
    final distanceMeters =
        tracks.fold<double>(0, (sum, track) => sum + track.distanceMeters);
    final duration =
        tracks.where((track) => track.duration != null).fold<Duration>(
              Duration.zero,
              (sum, track) => sum + track.duration!,
            );
    final elevationGainMeters = tracks.fold<double>(
        0, (sum, track) => sum + (track.elevationGainMeters ?? 0));
    final days = {
      for (final track in tracks)
        for (final point in track.points)
          if (point.recordedAt != null)
            DateTime(
              point.recordedAt!.year,
              point.recordedAt!.month,
              point.recordedAt!.day,
            ),
      for (final memory in memories)
        DateTime(memory.occurredAt.year, memory.occurredAt.month,
            memory.occurredAt.day),
      for (final entry in journalEntries)
        if (entry.createdAt != null)
          DateTime(entry.createdAt!.year, entry.createdAt!.month,
              entry.createdAt!.day),
    };

    final totalCostMinor = expenses.fold<int>(
          0,
          (sum, item) => sum + item.amountMinor,
        ) +
        fuelEntries.fold<int>(
          0,
          (sum, item) => sum + item.totalCostMinor,
        ) +
        bookings.fold<int>(
          0,
          (sum, item) => sum + (item.costMinor ?? 0),
        );
    final totalFuelLiters = fuelEntries.fold<double>(
      0,
      (sum, item) => sum + item.liters,
    );

    final averageSpeedKmh = duration.inSeconds > 0
        ? (distanceMeters / 1000) / (duration.inSeconds / 3600)
        : null;
    final consumptionLitersPer100Km = distanceMeters > 0
        ? (totalFuelLiters / (distanceMeters / 1000)) * 100
        : null;

    final placeCount = {
      for (final memory in memories) '${memory.latitude},${memory.longitude}',
      for (final entry in journalEntries)
        if (entry.place != null && entry.place!.isNotEmpty) entry.place!,
    }.length;

    return TravelHistoryStats(
      distanceMeters: distanceMeters,
      trackDays: days.length,
      placeCount: placeCount,
      totalCostMinor: totalCostMinor,
      totalFuelLiters: totalFuelLiters,
      duration: duration == Duration.zero ? null : duration,
      elevationGainMeters:
          elevationGainMeters == 0 ? null : elevationGainMeters,
      averageSpeedKmh: averageSpeedKmh,
      consumptionLitersPer100Km: consumptionLitersPer100Km,
    );
  }
}
