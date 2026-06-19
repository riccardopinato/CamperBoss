import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/travel_history_models.dart';

abstract interface class TravelHistoryRepository {
  Future<List<GpxTrack>> listTracks({int? tripId});
  Future<GpxTrack> saveTrack(GpxTrack track);
  Future<void> deleteTrack(String id);

  Future<List<TravelMemory>> listMemories({int? tripId});
  Future<TravelMemory> saveMemory(TravelMemory memory);
  Future<void> deleteMemory(String id);
}

class LocalTravelHistoryRepository implements TravelHistoryRepository {
  LocalTravelHistoryRepository({
    AppDatabase? database,
    LocalJsonCollection? tracksCollection,
    LocalJsonCollection? memoriesCollection,
  })  : _database = database ?? AppDatabase.instance,
        _tracksCollection =
            tracksCollection ?? LocalJsonCollection('camperboss.gpx_tracks'),
        _memoriesCollection =
            memoriesCollection ?? LocalJsonCollection('camperboss.memories');

  final AppDatabase _database;
  final LocalJsonCollection _tracksCollection;
  final LocalJsonCollection _memoriesCollection;

  @override
  Future<List<GpxTrack>> listTracks({int? tripId}) async {
    if (kIsWeb) {
      final rows = await _tracksCollection.listRows();
      final tracks = rows.map(GpxTrack.fromMap).toList(growable: false);
      return _filterTracks(tracks, tripId);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.gpxTracksTable,
      where: tripId == null ? null : 'trip_id = ?',
      whereArgs: tripId == null ? null : [tripId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(GpxTrack.fromMap).toList(growable: false);
  }

  @override
  Future<GpxTrack> saveTrack(GpxTrack track) async {
    if (kIsWeb) {
      final saved = await _tracksCollection.saveRow(track.toMap());
      return GpxTrack.fromMap(saved);
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.gpxTracksTable,
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return track;
  }

  @override
  Future<void> deleteTrack(String id) async {
    if (kIsWeb) {
      await _tracksCollection.deleteRow(id);
      return;
    }

    final db = await _database.database;
    await db
        .delete(AppDatabase.gpxTracksTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<TravelMemory>> listMemories({int? tripId}) async {
    if (kIsWeb) {
      final rows = await _memoriesCollection.listRows();
      final memories = rows.map(TravelMemory.fromMap).toList(growable: false);
      return _filterMemories(memories, tripId);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.travelMemoriesTable,
      where: tripId == null ? null : 'trip_id = ?',
      whereArgs: tripId == null ? null : [tripId],
      orderBy: 'occurred_at DESC',
    );
    return rows.map(TravelMemory.fromMap).toList(growable: false);
  }

  @override
  Future<TravelMemory> saveMemory(TravelMemory memory) async {
    if (kIsWeb) {
      final saved = await _memoriesCollection.saveRow(memory.toMap());
      return TravelMemory.fromMap(saved);
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.travelMemoriesTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return memory;
  }

  @override
  Future<void> deleteMemory(String id) async {
    if (kIsWeb) {
      await _memoriesCollection.deleteRow(id);
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.travelMemoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  List<GpxTrack> _filterTracks(List<GpxTrack> tracks, int? tripId) {
    final filtered = tripId == null
        ? tracks
        : tracks.where((track) => track.tripId == tripId).toList();
    filtered.sort((a, b) {
      final aDate =
          a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  List<TravelMemory> _filterMemories(List<TravelMemory> memories, int? tripId) {
    final filtered = tripId == null
        ? memories
        : memories.where((memory) => memory.tripId == tripId).toList();
    filtered.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return filtered;
  }
}
