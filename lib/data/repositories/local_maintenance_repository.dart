import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/maintenance_record.dart';
import '../../core/services/document_storage_service.dart';

abstract interface class MaintenanceRepository {
  Future<List<MaintenanceRecord>> listRecords();
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record);
  Future<void> deleteRecord(int id);
}

class LocalMaintenanceRepository implements MaintenanceRepository {
  LocalMaintenanceRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
    DocumentStorageService? storageService,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.maintenance'),
        _storageService = storageService ?? createDocumentStorageService();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DocumentStorageService _storageService;

  @override
  Future<List<MaintenanceRecord>> listRecords() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(MaintenanceRecord.fromMap).toList()..sort(_sortRecords);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.maintenanceRecordsTable,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(MaintenanceRecord.fromMap).toList();
  }

  @override
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record) async {
    MaintenanceRecord? previous;
    if (record.id != null) {
      final records = await listRecords();
      for (final candidate in records) {
        if (candidate.id == record.id) {
          previous = candidate;
          break;
        }
      }
    }

    late final MaintenanceRecord savedRecord;
    if (kIsWeb) {
      final saved = await _webCollection.saveRow(record.toMap());
      savedRecord = MaintenanceRecord.fromMap(saved);
    } else {
      final db = await _database.database;
      final values = record.toMap()..remove('id');
      final id = record.id == null
          ? await db.insert(AppDatabase.maintenanceRecordsTable, values)
          : await _updateRecord(db, record.id!, values);
      savedRecord = record.copyWith(id: id, updatedAt: DateTime.now());
    }

    final previousPaths = previous?.attachmentPaths ?? const <String>[];
    if (previousPaths.isNotEmpty) {
      final retained = savedRecord.attachmentPaths.toSet();
      await _storageService.deleteFiles(
        previousPaths.where((path) => !retained.contains(path)),
      );
    }

    return savedRecord;
  }

  Future<int> _updateRecord(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.maintenanceRecordsTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  @override
  Future<void> deleteRecord(int id) async {
    final records = await listRecords();
    MaintenanceRecord? record;
    for (final candidate in records) {
      if (candidate.id == id) {
        record = candidate;
        break;
      }
    }

    if (kIsWeb) {
      await _webCollection.deleteRow(id);
    } else {
      final db = await _database.database;
      await db.delete(
        AppDatabase.maintenanceRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    if (record != null && record.attachmentPaths.isNotEmpty) {
      await _storageService.deleteFiles(record.attachmentPaths);
    }
  }

  int _sortRecords(MaintenanceRecord a, MaintenanceRecord b) {
    final date = b.date.compareTo(a.date);
    if (date != 0) return date;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
