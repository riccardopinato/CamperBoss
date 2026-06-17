import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const databaseName = 'camperboss.db';
  static const databaseVersion = 11;

  static const checklistTable = 'checklist_items';
  static const tripsTable = 'trip_plans';
  static const journalTable = 'journal_entries';
  static const vehicleProfilesTable = 'vehicle_profiles';
  static const vehicleDocumentsTable = 'vehicle_documents';
  static const maintenanceRecordsTable = 'maintenance_records';
  static const remindersTable = 'app_reminders';
  static const reminderSettingsTable = 'reminder_settings';
  static const routePreviewsTable = 'route_previews';
  static const downloadRecordsTable = 'download_records';

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
  vehicle_id INTEGER,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  local_file_path TEXT NOT NULL,
  thumbnail_path TEXT,
  page_paths TEXT NOT NULL DEFAULT '[]',
  pdf_path TEXT,
  mime_type TEXT NOT NULL,
  page_count INTEGER NOT NULL DEFAULT 1,
  file_size INTEGER,
  source TEXT NOT NULL,
  issue_date TEXT,
  expiry_date TEXT,
  notes TEXT,
  ocr_text TEXT,
  extracted_text TEXT,
  ocr_language TEXT,
  ocr_status TEXT NOT NULL DEFAULT 'notRequested',
  processing_error TEXT,
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

    await _createReminderTables(db);
    await _createRoutePreviewTable(db);
    await _createDownloadRecordsTable(db);
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
  vehicle_id INTEGER,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  local_file_path TEXT NOT NULL,
  thumbnail_path TEXT,
  page_paths TEXT NOT NULL DEFAULT '[]',
  pdf_path TEXT,
  mime_type TEXT NOT NULL,
  page_count INTEGER NOT NULL DEFAULT 1,
  file_size INTEGER,
  source TEXT NOT NULL,
  issue_date TEXT,
  expiry_date TEXT,
  notes TEXT,
  ocr_text TEXT,
  extracted_text TEXT,
  ocr_language TEXT,
  ocr_status TEXT NOT NULL DEFAULT 'notRequested',
  processing_error TEXT,
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
    if (oldVersion < 8) {
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'vehicle_id',
        'INTEGER',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'title',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'local_file_path',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'thumbnail_path',
        'TEXT',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'mime_type',
        "TEXT NOT NULL DEFAULT 'application/octet-stream'",
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'page_count',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'file_size',
        'INTEGER',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'extracted_text',
        'TEXT',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'ocr_language',
        'TEXT',
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'ocr_status',
        "TEXT NOT NULL DEFAULT 'notRequested'",
      );
      await _addColumnIfMissing(
        db,
        vehicleDocumentsTable,
        'processing_error',
        'TEXT',
      );
      await db.execute('''
UPDATE $vehicleDocumentsTable
SET title = CASE WHEN title = '' THEN name ELSE title END,
    local_file_path = CASE
      WHEN local_file_path = '' AND pdf_path IS NOT NULL THEN pdf_path
      ELSE local_file_path
    END,
    extracted_text = CASE
      WHEN extracted_text IS NULL THEN ocr_text
      ELSE extracted_text
    END
''');
    }
    if (oldVersion < 9) {
      await _createReminderTables(db);
    }
    if (oldVersion < 10) {
      await _createRoutePreviewTable(db);
    }
    if (oldVersion < 11) {
      await _createDownloadRecordsTable(db);
    }
  }

  Future<void> _createReminderTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS $remindersTable (
  id TEXT PRIMARY KEY,
  source_type TEXT NOT NULL,
  source_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  scheduled_at TEXT NOT NULL,
  notification_id INTEGER NOT NULL,
  payload TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS $reminderSettingsTable (
  id TEXT PRIMARY KEY,
  enabled INTEGER NOT NULL DEFAULT 1,
  advance_days TEXT NOT NULL DEFAULT '[30,7,1,0]',
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> _createRoutePreviewTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS $routePreviewsTable (
  trip_id INTEGER PRIMARY KEY,
  waypoint_fingerprint TEXT NOT NULL,
  geometry TEXT NOT NULL,
  distance_meters REAL NOT NULL,
  duration_seconds REAL NOT NULL,
  legs TEXT NOT NULL DEFAULT '[]',
  provider TEXT NOT NULL,
  calculated_at TEXT NOT NULL
)
''');
  }

  Future<void> _createDownloadRecordsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS $downloadRecordsTable (
  package_id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  version TEXT NOT NULL,
  file_name TEXT NOT NULL,
  local_path TEXT NOT NULL,
  status TEXT NOT NULL,
  downloaded_bytes INTEGER NOT NULL DEFAULT 0,
  total_bytes INTEGER NOT NULL DEFAULT 0,
  expected_sha256 TEXT,
  installed_sha256 TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT,
  last_error TEXT,
  progress REAL NOT NULL DEFAULT 0,
  speed_bytes_per_second INTEGER,
  download_group TEXT NOT NULL DEFAULT 'offline'
)
''');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
