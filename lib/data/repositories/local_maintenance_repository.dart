import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
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
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.maintenance'),
        _storageService = storageService ?? createDocumentStorageService(),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DocumentStorageService _storageService;
  final DataRevisionStore _revisionStore;

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
      final values = record.toMap();
      final requestedId = record.id;
      late final int id;
      if (requestedId == null) {
        values.remove('id');
        id = await db.insert(AppDatabase.maintenanceRecordsTable, values);
      } else {
        final updateValues = Map<String, Object?>.from(values)..remove('id');
        final updated = await db.update(
          AppDatabase.maintenanceRecordsTable,
          updateValues,
          where: 'id = ?',
          whereArgs: [requestedId],
        );
        if (updated == 0) {
          await db.insert(
            AppDatabase.maintenanceRecordsTable,
            values,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        id = requestedId;
      }
      savedRecord = record.copyWith(
        id: id,
        updatedAt: record.updatedAt ?? DateTime.now(),
      );
    }

    _revisionStore.bump();

    final previousPaths = previous?.attachmentPaths ?? const <String>[];
    if (previousPaths.isNotEmpty) {
      try {
        await _deleteUnreferencedFiles(previousPaths);
      } catch (_) {
        // The row is already committed. Attachment garbage collection is
        // best-effort and must never make a successful save look failed.
      }
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

    _revisionStore.bump();

    if (record != null && record.attachmentPaths.isNotEmpty) {
      try {
        await _deleteUnreferencedFiles(record.attachmentPaths);
      } catch (_) {
        // Deletion is already committed; orphan cleanup can be retried later.
      }
    }
  }

  Future<void> _deleteUnreferencedFiles(Iterable<String> paths) async {
    final candidates = paths.where((path) => path.isNotEmpty).toSet();
    if (candidates.isEmpty) return;

    final remaining = await listRecords();
    final referenced = <String>{
      for (final record in remaining) ...record.attachmentPaths,
    };
    candidates.removeAll(referenced);
    if (candidates.isNotEmpty) {
      await _storageService.deleteFiles(candidates);
    }
  }

  int _sortRecords(MaintenanceRecord a, MaintenanceRecord b) {
    final date = b.date.compareTo(a.date);
    if (date != 0) return date;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
