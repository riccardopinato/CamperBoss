import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const databaseName = 'camperboss.db';
  static const databaseVersion = 1;

  static const checklistTable = 'checklist_items';
  static const tripsTable = 'trip_plans';
  static const journalTable = 'journal_entries';

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, databaseName);

    return _database = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _createSchema,
      onUpgrade: _migrateSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
CREATE TABLE $checklistTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  subtitle TEXT,
  category TEXT NOT NULL DEFAULT 'General',
  checked INTEGER NOT NULL DEFAULT 0,
  position INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $tripsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  progress REAL NOT NULL DEFAULT 0,
  start_date TEXT,
  end_date TEXT,
  notes TEXT,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $journalTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  created_at TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> _migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _createSchema(db, newVersion);
    }
  }
}
