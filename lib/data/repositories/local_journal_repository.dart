import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/data_revision_store.dart';
import '../database/local_json_collection.dart';
import '../models/journal_entry.dart';

abstract interface class JournalRepository {
  Future<List<JournalEntry>> listEntries();
  Future<JournalEntry> saveEntry(JournalEntry entry);
  Future<void> deleteEntry(int id);
}

class LocalJournalRepository implements JournalRepository {
  LocalJournalRepository({
    AppDatabase? database,
    LocalJsonCollection? webCollection,
    DataRevisionStore? revisionStore,
  })  : _database = database ?? AppDatabase.instance,
        _webCollection =
            webCollection ?? LocalJsonCollection('camperboss.journal'),
        _revisionStore = revisionStore ?? DataRevisionStore();

  final AppDatabase _database;
  final LocalJsonCollection _webCollection;
  final DataRevisionStore _revisionStore;

  @override
  Future<List<JournalEntry>> listEntries() async {
    if (kIsWeb) {
      final rows = await _webCollection.listRows();
      return rows.map(JournalEntry.fromMap).toList()..sort(_sortEntries);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.journalTable,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  @override
  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    if (kIsWeb) {
      final values = entry.toMap();
      final saved = await _webCollection.saveRow(values);
      _revisionStore.bump();
      return JournalEntry.fromMap(saved);
    }

    final db = await _database.database;
    final values = entry.toMap()..remove('id');

    final id = entry.id == null
        ? await db.insert(AppDatabase.journalTable, values)
        : await _updateEntry(db, entry.id!, values);

    _revisionStore.bump();
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

  @override
  Future<void> deleteEntry(int id) async {
    if (kIsWeb) {
      await _webCollection.deleteRow(id);
      _revisionStore.bump();
      return;
    }

    final db = await _database.database;
    await db.delete(AppDatabase.journalTable, where: 'id = ?', whereArgs: [id]);
    _revisionStore.bump();
  }

  int _sortEntries(JournalEntry a, JournalEntry b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final date = bDate.compareTo(aDate);
    if (date != 0) return date;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
