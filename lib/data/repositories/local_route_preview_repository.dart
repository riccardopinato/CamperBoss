import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/route_preview.dart';

abstract interface class RoutePreviewRepository {
  Future<List<RouteResult>> listRoutes();
  Future<RouteResult?> loadRouteForTrip(int tripId);
  Future<RouteResult> saveRoute(RouteResult route);
  Future<void> deleteRouteForTrip(int tripId);
}

class LocalRoutePreviewRepository implements RoutePreviewRepository {
  LocalRoutePreviewRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.routePreviews');

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;

  @override
  Future<List<RouteResult>> listRoutes() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(RouteResult.fromMap).toList(growable: false)
        ..sort((a, b) => b.calculatedAt.compareTo(a.calculatedAt));
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.routePreviewsTable,
      orderBy: 'calculated_at DESC',
    );
    return rows.map(RouteResult.fromMap).toList(growable: false);
  }

  @override
  Future<RouteResult?> loadRouteForTrip(int tripId) async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      final matches = rows.where((row) => row['trip_id'] == tripId).toList();
      if (matches.isEmpty) return null;
      matches.sort(_sortRoutes);
      return RouteResult.fromMap(matches.first);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.routePreviewsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'calculated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RouteResult.fromMap(rows.first);
  }

  @override
  Future<RouteResult> saveRoute(RouteResult route) async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      for (final row in rows.where((row) => row['trip_id'] == route.tripId)) {
        await _webCollection.deleteRow(row['id']);
      }
      await _webCollection.saveRow(route.toMap());
      return route;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.routePreviewsTable,
      where: 'trip_id = ?',
      whereArgs: [route.tripId],
    );
    await db.insert(AppDatabase.routePreviewsTable, route.toMap());
    return route;
  }

  @override
  Future<void> deleteRouteForTrip(int tripId) async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      for (final row in rows.where((row) => row['trip_id'] == tripId)) {
        await _webCollection.deleteRow(row['id']);
      }
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.routePreviewsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  int _sortRoutes(Map<String, Object?> a, Map<String, Object?> b) {
    final aDate = DateTime.tryParse(a['calculated_at'] as String? ?? '');
    final bDate = DateTime.tryParse(b['calculated_at'] as String? ?? '');
    return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
  }
}
