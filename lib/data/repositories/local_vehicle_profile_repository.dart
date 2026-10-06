import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/vehicle_profile.dart';

abstract interface class VehicleProfileRepository {
  Future<VehicleProfile?> loadProfile();
  Future<VehicleProfile> saveProfile(VehicleProfile profile);
  Future<void> deleteProfile();
}

abstract interface class VehicleProfileStore {
  Future<VehicleProfile?> loadProfile();
  Future<VehicleProfile> saveProfile(VehicleProfile profile);
  Future<void> deleteProfile();
}

class LocalVehicleProfileRepository implements VehicleProfileRepository {
  LocalVehicleProfileRepository({
    VehicleProfileStore? store,
    DataRevisionStore? revisionStore,
  })  : _store = store ??
            (kIsWeb ? _JsonVehicleProfileStore() : _SqlVehicleProfileStore()),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final VehicleProfileStore _store;
  final DataRevisionStore _revisionStore;

  @override
  Future<VehicleProfile?> loadProfile() => _store.loadProfile();

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile profile) {
    final errors = profile.validationErrors();
    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Invalid vehicle profile fields: ${errors.join(', ')}',
      );
    }
    return _store.saveProfile(profile).then((saved) {
      _revisionStore.bump();
      return saved;
    });
  }

  @override
  Future<void> deleteProfile() async {
    await _store.deleteProfile();
    _revisionStore.bump();
  }
}

class _JsonVehicleProfileStore implements VehicleProfileStore {
  _JsonVehicleProfileStore()
      : _collection = LocalJsonCollection('camperboss.vehicle_profile');

  final LocalJsonCollection _collection;

  @override
  Future<VehicleProfile?> loadProfile() async {
    final rows = await _collection.listRows();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
    return VehicleProfile.fromMap(rows.first);
  }

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile profile) async {
    final existing = await loadProfile();
    final values = profile.copyWith(id: profile.id ?? existing?.id).toMap();
    final saved = await _collection.saveRow(values);
    return VehicleProfile.fromMap(saved);
  }

  @override
  Future<void> deleteProfile() async {
    final existing = await loadProfile();
    final id = existing?.id;
    if (id == null) return;
    await _collection.deleteRow(id);
  }
}

class _SqlVehicleProfileStore implements VehicleProfileStore {
  _SqlVehicleProfileStore() : _database = AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<VehicleProfile?> loadProfile() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.vehicleProfilesTable,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VehicleProfile.fromMap(rows.first);
  }

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile profile) async {
    final db = await _database.database;
    final existing = await loadProfile();
    final values = profile.copyWith(id: profile.id ?? existing?.id).toMap()
      ..remove('id');

    final savedId = profile.id ?? existing?.id;
    late final int id;
    if (savedId == null) {
      id = await db.insert(AppDatabase.vehicleProfilesTable, values);
    } else {
      final updated = await db.update(
        AppDatabase.vehicleProfilesTable,
        values,
        where: 'id = ?',
        whereArgs: [savedId],
      );
      if (updated == 0) {
        await db.insert(
          AppDatabase.vehicleProfilesTable,
          <String, Object?>{'id': savedId, ...values},
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      id = savedId;
    }
    return profile.copyWith(
      id: id,
      updatedAt: profile.updatedAt ?? DateTime.now(),
    );
  }

  Future<int> _updateProfile(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.vehicleProfilesTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  @override
  Future<void> deleteProfile() async {
    final db = await _database.database;
    final existing = await loadProfile();
    final id = existing?.id;
    if (id == null) return;
    await db.delete(
      AppDatabase.vehicleProfilesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
