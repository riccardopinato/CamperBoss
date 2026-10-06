import 'package:archive/archive.dart';

import '../../data/models/journal_entry.dart';
import '../../data/models/travel_history_models.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_journal_repository.dart';
import '../../data/repositories/local_travel_history_repository.dart';
import 'gpx_service.dart';
import 'travel_history_statistics_service.dart';
import 'travel_media_service.dart';

class TravelHistoryBundle {
  const TravelHistoryBundle({
    required this.tracks,
    required this.memories,
    required this.stats,
  });

  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;
  final TravelHistoryStats stats;
}

class TravelHistoryService {
  TravelHistoryService({
    TravelHistoryRepository? repository,
    JournalRepository? journalRepository,
    FinanceRepository? financeRepository,
    GpxService? gpxService,
    TravelMediaService? mediaService,
    TravelHistoryStatisticsService? statisticsService,
  })  : _repository = repository ?? LocalTravelHistoryRepository(),
        _journalRepository = journalRepository ?? LocalJournalRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository(),
        _gpxService = gpxService ?? const GpxService(),
        _mediaService = mediaService ?? createTravelMediaService(),
        _statisticsService =
            statisticsService ?? const TravelHistoryStatisticsService();

  final TravelHistoryRepository _repository;
  final JournalRepository _journalRepository;
  final FinanceRepository _financeRepository;
  final GpxService _gpxService;
  final TravelMediaService _mediaService;
  final TravelHistoryStatisticsService _statisticsService;

  Future<TravelHistoryBundle> load({int? tripId}) async {
    final tracks = await _repository.listTracks(tripId: tripId);
    final memories = await _repository.listMemories(tripId: tripId);
    final journal = await _journalRepository.listEntries();
    final expenses = await _financeRepository.listExpenses();
    final fuel = await _financeRepository.listFuelEntries();
    final bookings = await _financeRepository.listBookings();

    return TravelHistoryBundle(
      tracks: tracks,
      memories: memories,
      stats: _statisticsService.build(
        tracks: tracks,
        memories: memories,
        journalEntries: _filterJournal(journal, tripId),
        expenses: expenses
            .where((item) => tripId == null || item.tripId == tripId)
            .toList(),
        fuelEntries: fuel
            .where((item) => tripId == null || item.tripId == tripId)
            .toList(),
        bookings: bookings
            .where((item) => tripId == null || item.tripId == tripId)
            .toList(),
      ),
    );
  }

  Future<TravelHistoryBundle> importGpx({int? tripId}) async {
    final imported = await _mediaService.importGpxFile();
    if (imported == null) return load(tripId: tripId);

    final parsed = await _gpxService.parse(
      imported.content,
      tripId: tripId,
      fallbackName: imported.fileName,
    );
    for (final track in parsed.tracks) {
      await saveTrack(track.copyWith(localFilePath: imported.localPath));
    }
    for (final memory in parsed.memories) {
      await _repository.saveMemory(memory);
    }
    return load(tripId: tripId);
  }

  Future<String> exportTrack(
    GpxTrack track, {
    List<TravelMemory> memories = const [],
  }) {
    final content = _gpxService.exportTrack(track, memories: memories);
    final safeName =
        '${track.name.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "_")}.gpx';
    return _mediaService.writeTextFile(safeName, content);
  }

  Future<String> exportSelectedPhotos(List<TravelMemory> memories) async {
    final archive = Archive();
    for (final memory in memories) {
      for (final path in memory.localPhotoPaths) {
        final bytes = await _mediaService.readPrivateFile(path);
        if (bytes == null) continue;
        archive.addFile(
          ArchiveFile(
            _fileName(path),
            bytes.length,
            bytes,
          ),
        );
      }
    }
    final bytes = ZipEncoder().encode(archive);
    return _mediaService.writeBinaryFile('travel_memories_photos.zip', bytes);
  }

  Future<PhotoLocationCandidate?> importPhoto() => _mediaService.importPhoto();

  Future<TravelMemory> saveMemory(TravelMemory memory) async {
    final previous = await _memoryById(memory.id);
    final saved = await _repository.saveMemory(memory);
    if (previous != null && previous.localPhotoPaths.isNotEmpty) {
      try {
        await _deleteUnreferencedMemoryFiles(previous.localPhotoPaths);
      } catch (_) {
        // Save is committed; media garbage collection is best-effort.
      }
    }
    return saved;
  }

  Future<GpxTrack> saveTrack(GpxTrack track) async {
    final previous = await _trackById(track.id);
    final saved = await _repository.saveTrack(track);
    if (previous?.localFilePath != null) {
      try {
        await _deleteUnreferencedTrackFiles([previous!.localFilePath]);
      } catch (_) {
        // Save is committed; media garbage collection is best-effort.
      }
    }
    return saved;
  }

  Future<void> deleteMemory(
    TravelMemory memory, {
    bool deleteMedia = true,
  }) async {
    await _repository.deleteMemory(memory.id);
    if (deleteMedia) {
      try {
        await cleanupUnreferencedMemoryFiles(memory.localPhotoPaths);
      } catch (_) {
        // Deletion is committed; cleanup must not break rollback/recovery.
      }
    }
  }

  Future<void> deleteTrack(
    GpxTrack track, {
    bool deleteMedia = true,
  }) async {
    await _repository.deleteTrack(track.id);
    if (deleteMedia) {
      try {
        await cleanupUnreferencedTrackFiles([track.localFilePath]);
      } catch (_) {
        // Deletion is committed; cleanup must not break rollback/recovery.
      }
    }
  }

  Future<void> cleanupUnreferencedMemoryFiles(Iterable<String?> paths) {
    return _deleteUnreferencedMemoryFiles(paths);
  }

  Future<void> cleanupUnreferencedTrackFiles(Iterable<String?> paths) {
    return _deleteUnreferencedTrackFiles(paths);
  }

  Future<TravelMemory?> _memoryById(String id) async {
    final memories = await _repository.listMemories();
    for (final memory in memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  Future<GpxTrack?> _trackById(String id) async {
    final tracks = await _repository.listTracks();
    for (final track in tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  Future<void> _deleteUnreferencedMemoryFiles(
    Iterable<String?> paths,
  ) async {
    final candidates = paths
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();
    if (candidates.isEmpty) return;

    final remaining = await _repository.listMemories();
    final referenced = <String>{
      for (final memory in remaining) ...memory.localPhotoPaths,
    };
    candidates.removeAll(referenced);
    if (candidates.isNotEmpty) {
      await _mediaService.deleteFiles(candidates);
    }
  }

  Future<void> _deleteUnreferencedTrackFiles(
    Iterable<String?> paths,
  ) async {
    final candidates = paths
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();
    if (candidates.isEmpty) return;

    final remaining = await _repository.listTracks();
    final referenced = <String>{
      for (final track in remaining)
        if (track.localFilePath != null && track.localFilePath!.isNotEmpty)
          track.localFilePath!,
    };
    candidates.removeAll(referenced);
    if (candidates.isNotEmpty) {
      await _mediaService.deleteFiles(candidates);
    }
  }

  List<JournalEntry> _filterJournal(List<JournalEntry> entries, int? tripId) {
    // JournalEntry does not currently carry a tripId. Including every entry
    // with a place in a trip-specific summary produced false statistics.
    // Until an explicit relation exists, only the all-trips view may use it.
    return tripId == null ? entries : const <JournalEntry>[];
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }
}
