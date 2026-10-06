import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../database/managed_media_reference_index.dart';
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
    ManagedMediaReferenceIndex? mediaReferenceIndex,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.vehicle_docs'),
        _storageService = storageService ?? createDocumentStorageService(),
        _revisionStore = revisionStore ?? DataRevisionStore(),
        _mediaReferenceIndex = mediaReferenceIndex ??
            ManagedMediaReferenceIndex(
              database: database ?? AppDatabase.instance,
            );

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DocumentStorageService _storageService;
  final DataRevisionStore _revisionStore;
  final ManagedMediaReferenceIndex _mediaReferenceIndex;

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
      final values = document.toMap();
      final requestedId = document.id;
      late final int id;
      if (requestedId == null) {
        values.remove('id');
        id = await db.insert(AppDatabase.vehicleDocumentsTable, values);
      } else {
        final updateValues = Map<String, Object?>.from(values)..remove('id');
        final updated = await db.update(
          AppDatabase.vehicleDocumentsTable,
          updateValues,
          where: 'id = ?',
          whereArgs: [requestedId],
        );
        if (updated == 0) {
          await db.insert(
            AppDatabase.vehicleDocumentsTable,
            values,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        id = requestedId;
      }
      savedDocument = document.copyWith(
        id: id,
        updatedAt: document.updatedAt ?? DateTime.now(),
      );
    }

    _revisionStore.bump();
    if (previous != null) {
      try {
        await _deleteUnreferencedFiles(previous.filePaths);
      } catch (_) {
        // Persistence already committed. Orphan cleanup is best-effort and
        // must not turn a successful save into an application-level failure.
      }
    }
    return savedDocument;
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
    try {
      await _deleteUnreferencedFiles(document.filePaths);
    } catch (_) {
      // The row deletion is already committed. Media cleanup may be retried.
    }
  }

  Future<void> _deleteUnreferencedFiles(Iterable<String> paths) async {
    final candidates = paths.where((path) => path.isNotEmpty).toSet();
    if (candidates.isEmpty) return;

    final referenced = await _mediaReferenceIndex.listReferencedPaths();
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
