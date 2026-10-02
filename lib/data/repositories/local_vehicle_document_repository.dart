import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/vehicle_document.dart';
import '../../core/services/document_storage_service.dart';

abstract interface class VehicleDocumentRepository {
  Future<List<VehicleDocument>> listDocuments();
  Future<VehicleDocument> saveDocument(VehicleDocument document);
  Future<void> deleteDocument(VehicleDocument document);
}

class LocalVehicleDocumentRepository implements VehicleDocumentRepository {
  LocalVehicleDocumentRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
    DocumentStorageService? storageService,
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.vehicle_docs'),
        _storageService = storageService ?? createDocumentStorageService(),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DocumentStorageService _storageService;
  final DataRevisionStore _revisionStore;

  @override
  Future<List<VehicleDocument>> listDocuments() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(VehicleDocument.fromMap).toList()..sort(_sortDocuments);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.vehicleDocumentsTable,
      orderBy: 'expiry_date IS NULL, expiry_date ASC, updated_at DESC',
    );
    return rows.map(VehicleDocument.fromMap).toList();
  }

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async {
    if (kIsWeb) {
      final saved = await _webCollection.saveRow(document.toMap());
      _revisionStore.bump();
      return VehicleDocument.fromMap(saved);
    }

    final db = await _database.database;
    final values = document.toMap()..remove('id');
    final id = document.id == null
        ? await db.insert(AppDatabase.vehicleDocumentsTable, values)
        : await _updateDocument(db, document.id!, values);
    _revisionStore.bump();
    return document.copyWith(id: id, updatedAt: DateTime.now());
  }

  Future<int> _updateDocument(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.vehicleDocumentsTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  @override
  Future<void> deleteDocument(VehicleDocument document) async {
    final id = document.id;
    if (id == null) return;

    if (kIsWeb) {
      await _webCollection.deleteRow(id);
      _revisionStore.bump();
      await _storageService.deleteFiles(document.filePaths);
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.vehicleDocumentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _revisionStore.bump();
    await _storageService.deleteFiles(document.filePaths);
  }

  int _sortDocuments(VehicleDocument a, VehicleDocument b) {
    final aExpiry = a.expiryDate;
    final bExpiry = b.expiryDate;
    if (aExpiry != null && bExpiry != null) return aExpiry.compareTo(bExpiry);
    if (aExpiry != null) return -1;
    if (bExpiry != null) return 1;
    return (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
