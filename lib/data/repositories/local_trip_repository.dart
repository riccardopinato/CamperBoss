import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/trip_plan.dart';

class LocalTripRepository {
  LocalTripRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<TripPlan>> listTrips() async {
    final db = await _database.database;
    final rows = await db.query(AppDatabase.tripsTable, orderBy: 'id DESC');
    return rows.map(TripPlan.fromMap).toList();
  }

  Future<TripPlan> saveTrip(TripPlan trip) async {
    final db = await _database.database;
    final values = trip.toMap()..remove('id');

    final id = trip.id == null
        ? await db.insert(AppDatabase.tripsTable, values)
        : await _updateTrip(db, trip.id!, values);

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

  Future<void> deleteTrip(int id) async {
    final db = await _database.database;
    await db.delete(AppDatabase.tripsTable, where: 'id = ?', whereArgs: [id]);
  }
}
