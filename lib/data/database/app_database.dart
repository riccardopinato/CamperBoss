import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const databaseName = 'camperboss.db';
  static const databaseVersion = 7;

  static const checklistTable = 'checklist_items';
  static const tripsTable = 'trip_plans';
  static const journalTable = 'journal_entries';
  static const vehicleProfilesTable = 'vehicle_profiles';
  static const vehicleDocumentsTable = 'vehicle_documents';
  static const maintenanceRecordsTable = 'maintenance_records';

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
  list_name TEXT NOT NULL DEFAULT 'Camper',
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
  destination TEXT,
  start_date TEXT,
  end_date TEXT,
  notes TEXT,
  stages TEXT NOT NULL DEFAULT '[]',
  overnight_stop TEXT,
  estimated_cost REAL,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $journalTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  created_at TEXT NOT NULL,
  place TEXT,
  kilometers REAL,
  cost REAL,
  latitude REAL,
  longitude REAL,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $vehicleProfilesTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vehicle_type TEXT NOT NULL,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  plate TEXT,
  length REAL NOT NULL,
  width REAL NOT NULL,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  max_mass REAL NOT NULL,
  seats INTEGER NOT NULL,
  fuel_type TEXT NOT NULL,
  mileage REAL NOT NULL,
  fuel_capacity REAL,
  water_capacity REAL,
  gas_capacity REAL,
  electric_range REAL,
  notes TEXT,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $vehicleDocumentsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  page_paths TEXT NOT NULL DEFAULT '[]',
  pdf_path TEXT,
  source TEXT NOT NULL,
  issue_date TEXT,
  expiry_date TEXT,
  notes TEXT,
  ocr_text TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $maintenanceRecordsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  date TEXT NOT NULL,
  mileage REAL NOT NULL,
  cost REAL,
  provider TEXT,
  notes TEXT,
  interval_months INTEGER,
  interval_kilometers REAL,
  next_due_date TEXT,
  next_due_mileage REAL,
  attachment_paths TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> _migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $tripsTable ADD COLUMN stages TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        'ALTER TABLE $tripsTable ADD COLUMN overnight_stop TEXT',
      );
      await db.execute(
        'ALTER TABLE $tripsTable ADD COLUMN estimated_cost REAL',
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $journalTable ADD COLUMN place TEXT');
      await db.execute('ALTER TABLE $journalTable ADD COLUMN kilometers REAL');
      await db.execute('ALTER TABLE $journalTable ADD COLUMN cost REAL');
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $checklistTable ADD COLUMN list_name TEXT NOT NULL DEFAULT 'Camper'",
      );
      await db.execute('ALTER TABLE $tripsTable ADD COLUMN destination TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS $vehicleProfilesTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vehicle_type TEXT NOT NULL,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  plate TEXT,
  length REAL NOT NULL,
  width REAL NOT NULL,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  max_mass REAL NOT NULL,
  seats INTEGER NOT NULL,
  fuel_type TEXT NOT NULL,
  mileage REAL NOT NULL,
  fuel_capacity REAL,
  water_capacity REAL,
  gas_capacity REAL,
  electric_range REAL,
  notes TEXT,
  updated_at TEXT NOT NULL
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS $vehicleDocumentsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  page_paths TEXT NOT NULL DEFAULT '[]',
  pdf_path TEXT,
  source TEXT NOT NULL,
  issue_date TEXT,
  expiry_date TEXT,
  notes TEXT,
  ocr_text TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    }
    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS $maintenanceRecordsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  date TEXT NOT NULL,
  mileage REAL NOT NULL,
  cost REAL,
  provider TEXT,
  notes TEXT,
  interval_months INTEGER,
  interval_kilometers REAL,
  next_due_date TEXT,
  next_due_mileage REAL,
  attachment_paths TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    }
  }
}
