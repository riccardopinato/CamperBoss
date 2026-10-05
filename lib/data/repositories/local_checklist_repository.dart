import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/checklist_item.dart';

abstract interface class ChecklistRepository {
  Future<List<CamperChecklistItem>> listItems();
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item);
  Future<void> deleteItem(int id);
}

class LocalChecklistRepository implements ChecklistRepository {
  LocalChecklistRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.checklist'),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DataRevisionStore _revisionStore;

  @override
  Future<List<CamperChecklistItem>> listItems() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(CamperChecklistItem.fromMap).toList()
        ..sort(_sortChecklistItems);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.checklistTable,
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(CamperChecklistItem.fromMap).toList();
  }

  @override
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async {
    if (kIsWeb) {
      final values = item.toMap();
      final saved = await _webCollection.saveRow(values);
      _revisionStore.bump();
      return CamperChecklistItem.fromMap(saved);
    }

    final db = await _database.database;
    final values = item.toMap()..remove('id');

    final id = item.id == null
        ? await db.insert(AppDatabase.checklistTable, values)
        : await _updateItem(db, item.id!, values);

    _revisionStore.bump();
    return item.copyWith(id: id);
  }

  Future<int> _updateItem(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.checklistTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  @override
  Future<void> deleteItem(int id) async {
    if (kIsWeb) {
      await _webCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.checklistTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _revisionStore.bump();
  }

  int _sortChecklistItems(CamperChecklistItem a, CamperChecklistItem b) {
    final position = a.position.compareTo(b.position);
    if (position != 0) return position;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }
}
