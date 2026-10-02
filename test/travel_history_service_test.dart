import 'package:camperboss/core/services/travel_history_service.dart';
import 'package:camperboss/core/services/travel_media_service.dart';
import 'package:camperboss/data/models/travel_history_models.dart';
import 'package:camperboss/data/repositories/local_travel_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared GPX is deleted only after the last referencing track', () async {
    final repository = _MemoryTravelHistoryRepository(
      tracks: [
        _track('a', '/private/shared.gpx'),
        _track('b', '/private/shared.gpx'),
      ],
    );
    final media = _FakeTravelMediaService();
    final service = TravelHistoryService(
      repository: repository,
      mediaService: media,
    );

    await service.deleteTrack(repository.tracks.first);
    expect(media.deletedPaths, isEmpty);

    await service.deleteTrack(repository.tracks.single);
    expect(media.deletedPaths, ['/private/shared.gpx']);
  });

  test('memory update removes orphaned photos but preserves shared files',
      () async {
    final repository = _MemoryTravelHistoryRepository(
      memories: [
        _memory(
          'a',
          const ['/private/shared.jpg', '/private/old.jpg'],
        ),
        _memory('b', const ['/private/shared.jpg']),
      ],
    );
    final media = _FakeTravelMediaService();
    final service = TravelHistoryService(
      repository: repository,
      mediaService: media,
    );

    await service.saveMemory(
      repository.memories.first.copyWith(
        localPhotoPaths: const ['/private/new.jpg'],
      ),
    );

    expect(media.deletedPaths, ['/private/old.jpg']);
    expect(media.deletedPaths, isNot(contains('/private/shared.jpg')));

    await service.deleteMemory(
      repository.memories.firstWhere((item) => item.id == 'b'),
    );
    expect(media.deletedPaths, contains('/private/shared.jpg'));
  });
}

GpxTrack _track(String id, String path) {
  return GpxTrack(
    id: id,
    name: id,
    points: const [GeoPoint(latitude: 45, longitude: 11)],
    distanceMeters: 10,
    localFilePath: path,
  );
}

TravelMemory _memory(String id, List<String> paths) {
  return TravelMemory(
    id: id,
    title: id,
    latitude: 45,
    longitude: 11,
    occurredAt: DateTime(2026, 1, 1),
    localPhotoPaths: paths,
  );
}

class _MemoryTravelHistoryRepository implements TravelHistoryRepository {
  _MemoryTravelHistoryRepository({
    List<GpxTrack> tracks = const [],
    List<TravelMemory> memories = const [],
  })  : tracks = [...tracks],
        memories = [...memories];

  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;

  @override
  Future<List<GpxTrack>> listTracks({int? tripId}) async {
    return [
      for (final item in tracks)
        if (tripId == null || item.tripId == tripId) item,
    ];
  }

  @override
  Future<GpxTrack> saveTrack(GpxTrack track) async {
    final index = tracks.indexWhere((item) => item.id == track.id);
    if (index == -1) {
      tracks.add(track);
    } else {
      tracks[index] = track;
    }
    return track;
  }

  @override
  Future<void> deleteTrack(String id) async {
    tracks.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<TravelMemory>> listMemories({int? tripId}) async {
    return [
      for (final item in memories)
        if (tripId == null || item.tripId == tripId) item,
    ];
  }

  @override
  Future<TravelMemory> saveMemory(TravelMemory memory) async {
    final index = memories.indexWhere((item) => item.id == memory.id);
    if (index == -1) {
      memories.add(memory);
    } else {
      memories[index] = memory;
    }
    return memory;
  }

  @override
  Future<void> deleteMemory(String id) async {
    memories.removeWhere((item) => item.id == id);
  }
}

class _FakeTravelMediaService implements TravelMediaService {
  final List<String> deletedPaths = [];

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    deletedPaths.addAll(
      paths.whereType<String>().where((path) => path.isNotEmpty),
    );
  }

  @override
  Future<ImportedGpxFile?> importGpxFile() async => null;

  @override
  Future<PhotoLocationCandidate?> importPhoto() async => null;

  @override
  Future<List<int>?> readPrivateFile(String path) async => null;

  @override
  Future<String> writeBinaryFile(String fileName, List<int> bytes) async {
    return '/tmp/$fileName';
  }

  @override
  Future<String> writeTextFile(String fileName, String content) async {
    return '/tmp/$fileName';
  }
}
