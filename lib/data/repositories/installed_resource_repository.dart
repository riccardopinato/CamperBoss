import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/download_models.dart';

abstract interface class InstalledResourceRepository {
  Stream<List<InstalledResource>> watchAll();
  Future<List<InstalledResource>> listAll();
  Future<InstalledResource?> findByPackageId(String packageId);
  Future<void> upsert(InstalledResource resource);
  Future<void> delete(String packageId);
  Future<ReconciliationReport> reconcile();
}

class LocalInstalledResourceRepository implements InstalledResourceRepository {
  LocalInstalledResourceRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.installed');

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;

  @override
  Stream<List<InstalledResource>> watchAll() async* {
    yield await listAll();
  }

  @override
  Future<List<InstalledResource>> listAll() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(InstalledResource.fromMap).toList()..sort(_sortResources);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.installedResourcesTable,
      orderBy: 'package_id ASC',
    );
    return rows.map(InstalledResource.fromMap).toList();
  }

  @override
  Future<InstalledResource?> findByPackageId(String packageId) async {
    final resources = await listAll();
    for (final resource in resources) {
      if (resource.packageId == packageId) return resource;
    }
    return null;
  }

  @override
  Future<void> upsert(InstalledResource resource) async {
    if (kIsWeb) {
      await _webCollection.saveRow({
        ...resource.toMap(),
        'id': resource.packageId,
      });
      return;
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.installedResourcesTable,
      resource.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String packageId) async {
    if (kIsWeb) {
      await _webCollection.deleteRow(packageId);
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.installedResourcesTable,
      where: 'package_id = ?',
      whereArgs: [packageId],
    );
  }

  @override
  Future<ReconciliationReport> reconcile() async {
    var missingFiles = 0;
    var updatedRecords = 0;
    final resources = await listAll();
    for (final resource in resources) {
      if (kIsWeb || resource.localPath.isEmpty) continue;
      final file = File(resource.localPath);
      if (!await file.exists()) {
        missingFiles++;
        updatedRecords++;
        await upsert(
          resource.copyWith(
            status: InstalledResourceStatus.missing,
            lastVerifiedAt: DateTime.now(),
            lastError: 'Installed file is missing',
          ),
        );
      }
    }
    return ReconciliationReport(
      missingFiles: missingFiles,
      updatedRecords: updatedRecords,
    );
  }

  int _sortResources(InstalledResource a, InstalledResource b) {
    return a.packageId.compareTo(b.packageId);
  }
}
