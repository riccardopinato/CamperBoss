import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/checklist_item.dart';

abstract interface class ChecklistRepository {
  Future<List<CamperChecklistItem>> listItems();
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item);
  Future<void> deleteItem(int id);
}

class LocalChecklistRepository implements ChecklistRepository {
  LocalChecklistRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<CamperChecklistItem>> listItems() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.checklistTable,
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(CamperChecklistItem.fromMap).toList();
  }

  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async {
    final db = await _database.database;
    final values = item.toMap()..remove('id');

    final id = item.id == null
        ? await db.insert(AppDatabase.checklistTable, values)
        : await _updateItem(db, item.id!, values);

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

  Future<void> deleteItem(int id) async {
    final db = await _database.database;
    await db.delete(
      AppDatabase.checklistTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
