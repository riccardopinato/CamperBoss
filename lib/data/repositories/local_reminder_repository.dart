import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/local_json_collection.dart';
import '../models/app_reminder.dart';

abstract interface class ReminderRepository {
  Future<ReminderSettings> loadSettings();
  Future<void> saveSettings(ReminderSettings settings);
  Future<List<AppReminder>> listReminders();
  Future<void> replaceAllReminders(List<AppReminder> reminders);
  Future<void> replaceSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
    List<AppReminder> reminders,
  );
  Future<void> deleteSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
  );
}

class LocalReminderRepository implements ReminderRepository {
  LocalReminderRepository({
    AppDatabase? database,
    LocalJsonCollection? reminderCollection,
    LocalJsonCollection? settingsCollection,
  })  : _database = database ?? AppDatabase.instance,
        _reminderCollection =
            reminderCollection ?? LocalJsonCollection('camperboss.reminders'),
        _settingsCollection = settingsCollection ??
            LocalJsonCollection('camperboss.reminder_settings');

  final AppDatabase _database;
  final LocalJsonCollection _reminderCollection;
  final LocalJsonCollection _settingsCollection;

  @override
  Future<ReminderSettings> loadSettings() async {
    if (kIsWeb) {
      final rows = await _settingsCollection.listRows();
      if (rows.isEmpty) return const ReminderSettings();
      return ReminderSettings.fromMap(rows.first);
    }

    final db = await _database.database;
    final rows = await db.query(AppDatabase.reminderSettingsTable, limit: 1);
    if (rows.isEmpty) return const ReminderSettings();
    return ReminderSettings.fromMap(rows.first);
  }

  @override
  Future<void> saveSettings(ReminderSettings settings) async {
    if (kIsWeb) {
      await _settingsCollection.saveRow(settings.toMap());
      return;
    }

    final db = await _database.database;
    await db.insert(
      AppDatabase.reminderSettingsTable,
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AppReminder>> listReminders() async {
    if (kIsWeb) {
      final rows = await _reminderCollection.listRows();
      return rows.map(AppReminder.fromMap).toList()..sort(_sortReminders);
    }

    final db = await _database.database;
    final rows = await db.query(
      AppDatabase.remindersTable,
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(AppReminder.fromMap).toList();
  }

  @override
  Future<void> replaceAllReminders(List<AppReminder> reminders) async {
    if (kIsWeb) {
      final existing = await _reminderCollection.listRows();
      for (final row in existing) {
        await _reminderCollection.deleteRow(row['id'] as Object);
      }
      for (final reminder in reminders) {
        await _reminderCollection.saveRow(reminder.toMap());
      }
      return;
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(AppDatabase.remindersTable);
      for (final reminder in reminders) {
        await txn.insert(
          AppDatabase.remindersTable,
          reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> replaceSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
    List<AppReminder> reminders,
  ) async {
    if (kIsWeb) {
      final existing = await _reminderCollection.listRows();
      for (final row in existing) {
        if (row['source_type'] == sourceType.storageValue &&
            row['source_id'] == sourceId) {
          await _reminderCollection.deleteRow(row['id'] as Object);
        }
      }
      for (final reminder in reminders) {
        await _reminderCollection.saveRow(reminder.toMap());
      }
      return;
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        AppDatabase.remindersTable,
        where: 'source_type = ? AND source_id = ?',
        whereArgs: [sourceType.storageValue, sourceId],
      );
      for (final reminder in reminders) {
        await txn.insert(
          AppDatabase.remindersTable,
          reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> deleteSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
  ) async {
    if (kIsWeb) {
      final rows = await _reminderCollection.listRows();
      for (final row in rows) {
        if (row['source_type'] == sourceType.storageValue &&
            row['source_id'] == sourceId) {
          await _reminderCollection.deleteRow(row['id'] as Object);
        }
      }
      return;
    }

    final db = await _database.database;
    await db.delete(
      AppDatabase.remindersTable,
      where: 'source_type = ? AND source_id = ?',
      whereArgs: [sourceType.storageValue, sourceId],
    );
  }

  int _sortReminders(AppReminder a, AppReminder b) {
    return a.scheduledAt.compareTo(b.scheduledAt);
  }
}
