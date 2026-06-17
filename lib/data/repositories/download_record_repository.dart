import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/download_models.dart';

abstract interface class DownloadRecordRepository {
  Future<List<DownloadRecord>> listRecords();
  Future<DownloadRecord?> getRecord(String packageId);
  Future<DownloadRecord?> getRecordByTaskId(String taskId);
  Future<void> saveRecord(DownloadRecord record);
  Future<void> deleteRecord(String packageId);
}

class LocalDownloadRecordRepository implements DownloadRecordRepository {
  LocalDownloadRecordRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.downloads');

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;

  @override
  Future<List<DownloadRecord>> listRecords() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(DownloadRecord.fromMap).toList()..sort(_sortRecords);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.downloadRecordsTable,
      orderBy: 'updated_at DESC',
    );
    return rows.map(DownloadRecord.fromMap).toList();
  }

  @override
  Future<DownloadRecord?> getRecord(String packageId) async {
    final records = await listRecords();
    for (final record in records) {
      if (record.packageId == packageId) return record;
    }
    return null;
  }

  @override
  Future<DownloadRecord?> getRecordByTaskId(String taskId) async {
    final records = await listRecords();
    for (final record in records) {
      if (record.taskId == taskId) return record;
    }
    return null;
  }

  @override
  Future<void> saveRecord(DownloadRecord record) async {
    if (kIsWeb) {
      await _webCollection.saveRow({
        ...record.toMap(),
        'id': record.packageId,
      });
      return;
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.downloadRecordsTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteRecord(String packageId) async {
    if (kIsWeb) {
      await _webCollection.deleteRow(packageId);
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.downloadRecordsTable,
      where: 'package_id = ?',
      whereArgs: [packageId],
    );
  }

  int _sortRecords(DownloadRecord a, DownloadRecord b) {
    return b.updatedAt.compareTo(a.updatedAt);
  }
}
