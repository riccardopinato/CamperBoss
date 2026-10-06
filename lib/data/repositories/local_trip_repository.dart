import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/trip_plan.dart';

abstract interface class TripRepository {
  Future<List<TripPlan>> listTrips();
  Future<TripPlan> saveTrip(TripPlan trip);
  Future<void> deleteTrip(int id);
}

class LocalTripRepository implements TripRepository {
  LocalTripRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.trips'),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DataRevisionStore _revisionStore;

  @override
  Future<List<TripPlan>> listTrips() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(TripPlan.fromMap).toList()..sort(_sortTrips);
    }

    final db = await _database.database;
    final rows = await db.query(AppDatabase.tripsTable, orderBy: 'id DESC');
    return rows.map(TripPlan.fromMap).toList();
  }

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async {
    if (kIsWeb) {
      final values = trip.toMap();
      final saved = await _webCollection.saveRow(values);
      _revisionStore.bump();
      return TripPlan.fromMap(saved);
    }

    final db = await _database.database;
    final values = trip.toMap();
    final requestedId = trip.id;
    late final int id;
    if (requestedId == null) {
      values.remove('id');
      id = await db.insert(AppDatabase.tripsTable, values);
    } else {
      final updateValues = Map<String, Object?>.from(values)..remove('id');
      final updated = await db.update(
        AppDatabase.tripsTable,
        updateValues,
        where: 'id = ?',
        whereArgs: [requestedId],
      );
      if (updated == 0) {
        await db.insert(
          AppDatabase.tripsTable,
          values,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      id = requestedId;
    }

    _revisionStore.bump();
    return trip.copyWith(id: id);
  }

  Future<int> _updateTrip(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.tripsTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  @override
  Future<void> deleteTrip(int id) async {
    if (kIsWeb) {
      await _webCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(AppDatabase.tripsTable, where: 'id = ?', whereArgs: [id]);
    _revisionStore.bump();
  }

  int _sortTrips(TripPlan a, TripPlan b) {
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
