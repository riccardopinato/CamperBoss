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
    VehicleDocument? previous;
    final existingId = document.id;
    if (existingId != null) {
      final existing = await listDocuments();
      for (final candidate in existing) {
        if (candidate.id == existingId) {
          previous = candidate;
          break;
        }
      }
    }

    late final VehicleDocument savedDocument;
    if (kIsWeb) {
      final saved = await _webCollection.saveRow(document.toMap());
      savedDocument = VehicleDocument.fromMap(saved);
    } else {
      final db = await _database.database;
      final values = document.toMap()..remove('id');
      final id = document.id == null
          ? await db.insert(AppDatabase.vehicleDocumentsTable, values)
          : await _updateDocument(db, document.id!, values);
      savedDocument =
          document.copyWith(id: id, updatedAt: DateTime.now());
    }

    _revisionStore.bump();
    if (previous != null) {
      await _deleteUnreferencedFiles(previous.filePaths);
    }
    return savedDocument;
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
    } else {
      final db = await _database.database;
      await db.delete(
        AppDatabase.vehicleDocumentsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _revisionStore.bump();
    await _deleteUnreferencedFiles(document.filePaths);
  }

  Future<void> _deleteUnreferencedFiles(Iterable<String> paths) async {
    final candidates = paths.where((path) => path.isNotEmpty).toSet();
    if (candidates.isEmpty) return;

    final remaining = await listDocuments();
    final referenced = <String>{
      for (final document in remaining) ...document.filePaths,
    };
    candidates.removeAll(referenced);
    if (candidates.isNotEmpty) {
      await _storageService.deleteFiles(candidates);
    }
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
