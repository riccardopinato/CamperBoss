import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/journal_entry.dart';

class LocalJournalRepository {
  LocalJournalRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<JournalEntry>> listEntries() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.journalTable,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    final db = await _database.database;
    final values = entry.toMap()..remove('id');

    final id = entry.id == null
        ? await db.insert(AppDatabase.journalTable, values)
        : await _updateEntry(db, entry.id!, values);

    return entry.copyWith(id: id);
  }

  Future<int> _updateEntry(
    Database db,
    int id,
    Map<String, Object?> values,
  ) async {
    await db.update(
      AppDatabase.journalTable,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> deleteEntry(int id) async {
    final db = await _database.database;
    await db.delete(AppDatabase.journalTable, where: 'id = ?', whereArgs: [id]);
  }
}
