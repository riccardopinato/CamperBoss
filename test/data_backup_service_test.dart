import 'dart:io';

import 'package:archive/archive.dart';
import 'package:camperboss/core/services/data_backup_service.dart';
import 'package:camperboss/core/services/data_integrity_service.dart';
import 'package:camperboss/core/services/user_state_backup_service.dart';
import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/core/services/document_storage_service.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:camperboss/data/models/app_reminder.dart';
import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/models/maintenance_record.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/travel_history_models.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_checklist_repository.dart';
import 'package:camperboss/data/repositories/local_finance_repository.dart';
import 'package:camperboss/data/repositories/local_journal_repository.dart';
import 'package:camperboss/data/repositories/local_maintenance_repository.dart';
import 'package:camperboss/data/repositories/local_route_preview_repository.dart';
import 'package:camperboss/data/repositories/local_reminder_repository.dart';
import 'package:camperboss/data/repositories/local_travel_history_repository.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates inspectable zip backup with manifest hashes and files',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_backup_test');
    addTearDown(() => temp.delete(recursive: true));
    final attachment = File('${temp.path}/invoice.pdf')
      ..writeAsStringSync('invoice');
    final missing = '${temp.path}/missing.pdf';
    final service = _service(
      documents: [
        VehicleDocument(
          id: 7,
          category: 'invoice',
          title: 'Invoice',
          localFilePath: attachment.path,
          mimeType: 'application/pdf',
          ocrStatus: DocumentOcrStatus.notRequested,
        ),
      ],
      maintenance: [
        MaintenanceRecord(
          id: 3,
          category: 'Oil',
          title: 'Oil service',
          date: DateTime(2026, 6, 1),
          mileage: 20000,
          attachmentPaths: [missing],
        ),
      ],
      tracks: [
        GpxTrack(
          id: 'track-1',
          tripId: 1,
          name: 'Track',
          points: [GeoPoint(latitude: 45, longitude: 10)],
          distanceMeters: 10,
        ),
      ],
      memories: [
        TravelMemory(
          id: 'memory-1',
          tripId: 1,
          title: 'Memory',
          latitude: 45,
          longitude: 10,
          occurredAt: DateTime(2026, 6, 17),
        ),
      ],
    );

    final result = await service.createBackup(
      BackupOptions(
        outputDirectory: temp,
        createdAt: DateTime(2026, 6, 17),
      ),
    );
    final inspection = await service.inspectBackup(result.path);

    expect(File(result.path).existsSync(), isTrue);
    expect(result.manifest.format, DataBackupService.format);
    expect(result.fileCount, 1);
    expect(result.missingFiles, [missing]);
    expect(inspection.isValid, isTrue);
    expect(inspection.recordCounts['data/documents.json'], 1);
    expect(inspection.recordCounts['data/gpx_tracks.json'], 1);
    expect(inspection.recordCounts['data/travel_memories.json'], 1);
    expect(inspection.fileCount, 1);
  });

  test('rejects corrupted backup archives', () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_corrupt_test');
    addTearDown(() => temp.delete(recursive: true));
    final corrupt = File('${temp.path}/broken.zip')
      ..writeAsStringSync('no zip');

    final inspection = await _service().inspectBackup(corrupt.path);

    expect(inspection.isValid, isFalse);
    expect(inspection.errors, isNotEmpty);
  });

  test('detects unsupported schema version', () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_schema_test');
    addTearDown(() => temp.delete(recursive: true));
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          '{"format":"camperboss-backup","schemaVersion":99,"appVersion":"x","createdAt":"2026-06-17T00:00:00.000","files":[]}',
        ),
      );
    final file = File('${temp.path}/schema.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    final inspection = await _service().inspectBackup(file.path);

    expect(inspection.isValid, isFalse);
    expect(inspection.errors, contains('Unsupported schema version'));
  });

  test('restore replaceAll replaces local records and creates safety backup',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_restore_test');
    addTearDown(() => temp.delete(recursive: true));
    final source = _memoryState(
      trips: [
        const TripPlan(
            id: 42, title: 'Restored', summary: 'Backup', progress: 1),
      ],
    );
    final sourceService = _serviceFrom(source);
    final backup = await sourceService.createBackup(
      BackupOptions(outputDirectory: temp),
    );
    final target = _memoryState(
      trips: [
        const TripPlan(id: 1, title: 'Local', summary: 'Old', progress: 0),
      ],
    );

    final result = await _serviceFrom(target).restoreBackup(
      backup.path,
      RestoreStrategy.replaceAll,
    );

    expect(target.trips.map((item) => item.title), ['Restored']);
    expect(result.restoredRecords, greaterThan(0));
    expect(File(result.automaticBackupPath).existsSync(), isTrue);
  });

  test('restore materializes archived files instead of keeping stale source paths',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_restore_files_test');
    final privateDir = Directory('${temp.path}/private')..createSync();
    addTearDown(() => temp.delete(recursive: true));

    final sourceFile = File('${temp.path}/invoice.pdf')
      ..writeAsStringSync('invoice-from-backup');
    final source = _memoryState(
      documents: [
        VehicleDocument(
          id: 9,
          category: 'invoice',
          title: 'Portable invoice',
          localFilePath: sourceFile.path,
          mimeType: 'application/pdf',
          ocrStatus: DocumentOcrStatus.notRequested,
        ),
      ],
    );
    final backup = await _serviceFrom(source).createBackup(
      BackupOptions(outputDirectory: temp),
    );
    sourceFile.deleteSync();

    final target = _memoryState();
    final storage = _TestFileStorageService(privateDir);
    await _serviceFrom(
      target,
      fileStorageService: storage,
    ).restoreBackup(backup.path, RestoreStrategy.replaceAll);

    expect(target.documents, hasLength(1));
    final restoredPath = target.documents.single.localFilePath;
    expect(restoredPath, isNot(sourceFile.path));
    expect(File(restoredPath).existsSync(), isTrue);
    expect(File(restoredPath).readAsStringSync(), 'invoice-from-backup');
  });

  test('failed replace restore rebuilds deleted files from the safety backup',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_restore_rollback_test');
    final privateDir = Directory('${temp.path}/private')..createSync();
    addTearDown(() => temp.delete(recursive: true));

    final incoming = _memoryState(
      trips: [
        const TripPlan(
          id: 99,
          title: 'Force restore failure',
          summary: 'Incoming',
          progress: 0,
        ),
      ],
    );
    final incomingBackup = await _serviceFrom(incoming).createBackup(
      BackupOptions(outputDirectory: temp),
    );

    final oldFile = File('${privateDir.path}/old_invoice.pdf')
      ..writeAsStringSync('old-private-file');
    final target = _memoryState(
      documents: [
        VehicleDocument(
          id: 7,
          category: 'invoice',
          title: 'Old invoice',
          localFilePath: oldFile.path,
          mimeType: 'application/pdf',
          ocrStatus: DocumentOcrStatus.notRequested,
        ),
      ],
    );
    final storage = _TestFileStorageService(privateDir);
    final service = _serviceFrom(
      target,
      fileStorageService: storage,
      tripRepository: _FailOnceTripRepository(target),
      documentRepository:
          _DeletingMemoryDocumentRepository(target, storage),
    );

    await expectLater(
      service.restoreBackup(
        incomingBackup.path,
        RestoreStrategy.replaceAll,
      ),
      throwsStateError,
    );

    expect(oldFile.existsSync(), isFalse);
    expect(target.trips, isEmpty);
    expect(target.documents, hasLength(1));
    final rolledBackPath = target.documents.single.localFilePath;
    expect(rolledBackPath, isNot(oldFile.path));
    expect(File(rolledBackPath).existsSync(), isTrue);
    expect(File(rolledBackPath).readAsStringSync(), 'old-private-file');
  });

  test('replaceAll purges stale derived route previews before integrity audit',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_route_restore_test');
    addTearDown(() => temp.delete(recursive: true));

    final source = _memoryState(
      trips: const [
        TripPlan(id: 42, title: 'Restored', summary: 'Backup', progress: 1),
      ],
    );
    final backup = await _serviceFrom(source).createBackup(
      BackupOptions(outputDirectory: temp),
    );

    final target = _memoryState(
      trips: const [
        TripPlan(id: 1, title: 'Old', summary: 'Local', progress: 0),
      ],
    );
    final routes = _MemoryRouteRepository([
      RouteResult(
        tripId: 1,
        waypointFingerprint: 'old-trip',
        geometry: const [],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        legs: const [],
        provider: 'test',
        calculatedAt: DateTime.utc(2026, 1, 1),
      ),
      RouteResult(
        tripId: 999,
        waypointFingerprint: 'orphan',
        geometry: const [],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        legs: const [],
        provider: 'test',
        calculatedAt: DateTime.utc(2026, 1, 2),
      ),
    ]);

    await _serviceFrom(target, routeRepository: routes).restoreBackup(
      backup.path,
      RestoreStrategy.replaceAll,
    );

    expect(await routes.listRoutes(), isEmpty);
    expect(target.trips.single.id, 42);
  });

  test('restore aborts before mutation when safety backup is incomplete',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_safety_guard_test');
    addTearDown(() => temp.delete(recursive: true));

    final incoming = _memoryState(
      trips: const [
        TripPlan(id: 2, title: 'Incoming', summary: 'Backup', progress: 0),
      ],
    );
    final backup = await _serviceFrom(incoming).createBackup(
      BackupOptions(outputDirectory: temp),
    );

    final missingPath = '${temp.path}/missing-private.pdf';
    final target = _memoryState(
      trips: const [
        TripPlan(id: 1, title: 'Keep me', summary: 'Local', progress: 0),
      ],
      documents: [
        VehicleDocument(
          id: 1,
          category: 'insurance',
          title: 'Missing attachment',
          localFilePath: missingPath,
          mimeType: 'application/pdf',
          ocrStatus: DocumentOcrStatus.notRequested,
        ),
      ],
    );

    await expectLater(
      _serviceFrom(target).restoreBackup(
        backup.path,
        RestoreStrategy.replaceAll,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Safety backup is incomplete'),
        ),
      ),
    );

    expect(target.trips.single.title, 'Keep me');
    expect(target.documents.single.localFilePath, missingPath);
  });

  test('merge keeps newer local conflicts and restores new records', () async {
    final temp = await Directory.systemTemp.createTemp('camperboss_merge_test');
    addTearDown(() => temp.delete(recursive: true));
    final source = _memoryState(
      trips: [
        TripPlan(
          id: 1,
          title: 'Older backup',
          summary: 'Backup',
          progress: 0.5,
          updatedAt: DateTime(2026, 1, 1),
        ),
        const TripPlan(
            id: 2, title: 'New trip', summary: 'Backup', progress: 1),
      ],
    );
    final backup = await _serviceFrom(source).createBackup(
      BackupOptions(outputDirectory: temp),
    );
    final target = _memoryState(
      trips: [
        TripPlan(
          id: 1,
          title: 'Newer local',
          summary: 'Local',
          progress: 0.8,
          updatedAt: DateTime(2026, 2, 1),
        ),
      ],
    );

    final result = await _serviceFrom(target).restoreBackup(
      backup.path,
      RestoreStrategy.merge,
    );

    expect(target.trips.map((item) => item.title), ['Newer local', 'New trip']);
    expect(result.skippedRecords, 1);
    expect(result.conflicts, 1);
  });

  test('exports CSV and PDF files', () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_export_test');
    addTearDown(() => temp.delete(recursive: true));
    final service = _service(
      profile: _profile,
      trips: [
        const TripPlan(id: 5, title: 'Trip', summary: 'Summary', progress: 0.5),
      ],
      maintenance: [
        MaintenanceRecord(
          id: 2,
          category: 'Oil',
          title: 'Oil',
          date: DateTime(2026, 1, 1),
          mileage: 10000,
          cost: 120,
        ),
      ],
      expenses: [
        Expense(
          id: 'expense-1',
          scope: ExpenseScope.trip,
          tripId: 5,
          category: ExpenseCategory.food,
          amountMinor: 1200,
          currencyCode: 'EUR',
          occurredAt: DateTime(2026, 1, 2),
        ),
      ],
      fuel: [
        FuelEntry(
          id: 'fuel-1',
          vehicleId: 1,
          tripId: 5,
          date: DateTime(2026, 1, 3),
          odometerKm: 12000,
          volumeMilliLitres: 30000,
          totalCostMinor: 5400,
          currencyCode: 'EUR',
          fullTank: true,
        ),
      ],
    );

    final csv = await service.exportCsv(outputDirectory: temp);
    final vehiclePdf = await service.exportVehiclePdf(outputDirectory: temp);
    final tripPdf = await service.exportTripPdf(5, outputDirectory: temp);

    expect(csv['fuel']!.readAsStringSync(), contains('odometer_km'));
    expect(csv['expenses']!.readAsStringSync(), contains('amount_minor'));
    expect(vehiclePdf.lengthSync(), greaterThan(0));
    expect(tripPdf.lengthSync(), greaterThan(0));
  });

  test('backs up and inspects 1k trips within broad CI regression budget',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('camperboss_backup_stress_test');
    addTearDown(() => temp.delete(recursive: true));

    final trips = List.generate(
      1000,
      (index) => TripPlan(
        id: index + 1,
        title: 'Stress trip $index',
        summary: 'Local-first backup stress row $index',
        progress: (index % 100) / 100,
        destination: 'Destination ${index % 25}',
        notes: 'Notes ' * 8,
        stages: [
          'Stage A $index',
          'Stage B $index',
        ],
        updatedAt: DateTime(2026, 1, 1).add(Duration(minutes: index)),
      ),
      growable: false,
    );
    final service = _service(trips: trips);

    final create = Stopwatch()..start();
    final backup = await service.createBackup(
      BackupOptions(outputDirectory: temp),
    );
    create.stop();

    final inspect = Stopwatch()..start();
    final inspection = await service.inspectBackup(backup.path);
    inspect.stop();

    expect(inspection.isValid, isTrue);
    expect(inspection.recordCounts['data/trips.json'], 1000);
    expect(File(backup.path).lengthSync(), greaterThan(0));
    expect(create.elapsed, lessThan(const Duration(seconds: 15)));
    expect(inspect.elapsed, lessThan(const Duration(seconds: 10)));
  });
}

DataBackupService _service({
  VehicleProfile? profile,
  List<TripPlan> trips = const [],
  List<CamperChecklistItem> checklist = const [],
  List<JournalEntry> journal = const [],
  List<MaintenanceRecord> maintenance = const [],
  List<VehicleDocument> documents = const [],
  List<Expense> expenses = const [],
  List<FuelEntry> fuel = const [],
  List<TripBudget> budgets = const [],
  List<TripBooking> bookings = const [],
  List<GpxTrack> tracks = const [],
  List<TravelMemory> memories = const [],
}) {
  return _serviceFrom(
    _memoryState(
      profile: profile,
      trips: trips,
      checklist: checklist,
      journal: journal,
      maintenance: maintenance,
      documents: documents,
      expenses: expenses,
      fuel: fuel,
      budgets: budgets,
      bookings: bookings,
      tracks: tracks,
      memories: memories,
    ),
  );
}

DataBackupService _serviceFrom(
  _MemoryState state, {
  DocumentStorageService? fileStorageService,
  TripRepository? tripRepository,
  VehicleDocumentRepository? documentRepository,
  RoutePreviewRepository? routeRepository,
}) {
  final profile = _MemoryProfileRepository(state);
  final trips = tripRepository ?? _MemoryTripRepository(state);
  final checklist = _MemoryChecklistRepository(state);
  final journal = _MemoryJournalRepository(state);
  final maintenance = _MemoryMaintenanceRepository(state);
  final documents = documentRepository ?? _MemoryDocumentRepository(state);
  final finance = _MemoryFinanceRepository(state);
  final history = _MemoryTravelHistoryRepository(state);
  final reminders = _MemoryReminderRepository();
  final routes = routeRepository ?? _MemoryRouteRepository();

  return DataBackupService(
    profileRepository: profile,
    tripRepository: trips,
    checklistRepository: checklist,
    journalRepository: journal,
    maintenanceRepository: maintenance,
    documentRepository: documents,
    financeRepository: finance,
    travelHistoryRepository: history,
    reminderRepository: reminders,
    routeRepository: routes,
    userStateBackupService:
        UserStateBackupService(store: MemoryKeyValueStore()),
    integrityService: DataIntegrityService(
      tripRepository: trips,
      financeRepository: finance,
      journalRepository: journal,
      documentRepository: documents,
      maintenanceRepository: maintenance,
      travelHistoryRepository: history,
      reminderRepository: reminders,
      routeRepository: routes,
    ),
    fileStorageService: fileStorageService,
  );
}

class _TestFileStorageService implements DocumentStorageService {
  _TestFileStorageService(this.directory);

  final Directory directory;
  int _counter = 0;

  @override
  Future<String> copyIntoPrivateDocuments(String pathOrUri) async {
    final source = File(pathOrUri);
    final name = source.uri.pathSegments.last;
    final target = File(
      '${directory.path}/restored_${_counter++}_$name',
    );
    await source.copy(target.path);
    return target.path;
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    for (final path in paths) {
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

_MemoryState _memoryState({
  VehicleProfile? profile,
  List<TripPlan> trips = const [],
  List<CamperChecklistItem> checklist = const [],
  List<JournalEntry> journal = const [],
  List<MaintenanceRecord> maintenance = const [],
  List<VehicleDocument> documents = const [],
  List<Expense> expenses = const [],
  List<FuelEntry> fuel = const [],
  List<TripBudget> budgets = const [],
  List<TripBooking> bookings = const [],
  List<GpxTrack> tracks = const [],
  List<TravelMemory> memories = const [],
}) {
  return _MemoryState(
    profile: profile,
    trips: [...trips],
    checklist: [...checklist],
    journal: [...journal],
    maintenance: [...maintenance],
    documents: [...documents],
    expenses: [...expenses],
    fuel: [...fuel],
    budgets: [...budgets],
    bookings: [...bookings],
    tracks: [...tracks],
    memories: [...memories],
  );
}

class _MemoryState {
  _MemoryState({
    this.profile,
    required this.trips,
    required this.checklist,
    required this.journal,
    required this.maintenance,
    required this.documents,
    required this.expenses,
    required this.fuel,
    required this.budgets,
    required this.bookings,
    required this.tracks,
    required this.memories,
  });

  VehicleProfile? profile;
  final List<TripPlan> trips;
  final List<CamperChecklistItem> checklist;
  final List<JournalEntry> journal;
  final List<MaintenanceRecord> maintenance;
  final List<VehicleDocument> documents;
  final List<Expense> expenses;
  final List<FuelEntry> fuel;
  final List<TripBudget> budgets;
  final List<TripBooking> bookings;
  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;
}

class _MemoryProfileRepository implements VehicleProfileRepository {
  _MemoryProfileRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteProfile() async => state.profile = null;

  @override
  Future<VehicleProfile?> loadProfile() async => state.profile;

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile profile) async {
    state.profile = profile;
    return profile;
  }
}

class _MemoryTripRepository implements TripRepository {
  _MemoryTripRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteTrip(int id) async {
    state.trips.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<TripPlan>> listTrips() async => [...state.trips];

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async {
    final index = state.trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      state.trips.add(trip);
    } else {
      state.trips[index] = trip;
    }
    return trip;
  }
}

class _FailOnceTripRepository extends _MemoryTripRepository {
  _FailOnceTripRepository(super.state);

  bool _shouldFail = true;

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('forced restore failure');
    }
    return super.saveTrip(trip);
  }
}

class _DeletingMemoryDocumentRepository
    extends _MemoryDocumentRepository {
  _DeletingMemoryDocumentRepository(super.state, this.storage);

  final DocumentStorageService storage;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {
    await super.deleteDocument(document);
    await storage.deleteFiles(document.filePaths);
  }
}

class _MemoryChecklistRepository implements ChecklistRepository {
  _MemoryChecklistRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteItem(int id) async {
    state.checklist.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CamperChecklistItem>> listItems() async => [...state.checklist];

  @override
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async {
    final index = state.checklist.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      state.checklist.add(item);
    } else {
      state.checklist[index] = item;
    }
    return item;
  }
}

class _MemoryJournalRepository implements JournalRepository {
  _MemoryJournalRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteEntry(int id) async {
    state.journal.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<JournalEntry>> listEntries() async => [...state.journal];

  @override
  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    final index = state.journal.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      state.journal.add(entry);
    } else {
      state.journal[index] = entry;
    }
    return entry;
  }
}

class _MemoryMaintenanceRepository implements MaintenanceRepository {
  _MemoryMaintenanceRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteRecord(int id) async {
    state.maintenance.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<MaintenanceRecord>> listRecords() async => [...state.maintenance];

  @override
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record) async {
    final index = state.maintenance.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      state.maintenance.add(record);
    } else {
      state.maintenance[index] = record;
    }
    return record;
  }
}

class _MemoryDocumentRepository implements VehicleDocumentRepository {
  _MemoryDocumentRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {
    state.documents.removeWhere((item) => item.id == document.id);
  }

  @override
  Future<List<VehicleDocument>> listDocuments() async => [...state.documents];

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async {
    final index = state.documents.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      state.documents.add(document);
    } else {
      state.documents[index] = document;
    }
    return document;
  }
}

class _MemoryFinanceRepository implements FinanceRepository {
  _MemoryFinanceRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteBooking(String id) async {
    state.bookings.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteExpense(String id) async {
    state.expenses.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteFuelEntry(String id) async {
    state.fuel.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteTripBudget(int tripId) async {
    state.budgets.removeWhere((item) => item.tripId == tripId);
  }

  @override
  Future<List<TripBooking>> listBookings() async => [...state.bookings];

  @override
  Future<List<Expense>> listExpenses() async => [...state.expenses];

  @override
  Future<List<FuelEntry>> listFuelEntries() async => [...state.fuel];

  @override
  Future<TripBudget?> loadTripBudget(int tripId) async {
    final matches = state.budgets.where((item) => item.tripId == tripId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<TripBooking> saveBooking(TripBooking booking) async {
    final index = state.bookings.indexWhere((item) => item.id == booking.id);
    if (index == -1) {
      state.bookings.add(booking);
    } else {
      state.bookings[index] = booking;
    }
    return booking;
  }

  @override
  Future<Expense> saveExpense(Expense expense) async {
    final index = state.expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      state.expenses.add(expense);
    } else {
      state.expenses[index] = expense;
    }
    return expense;
  }

  @override
  Future<FuelEntry> saveFuelEntry(FuelEntry entry) async {
    final index = state.fuel.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      state.fuel.add(entry);
    } else {
      state.fuel[index] = entry;
    }
    return entry;
  }

  @override
  Future<void> saveTripBudget(TripBudget budget) async {
    final index =
        state.budgets.indexWhere((item) => item.tripId == budget.tripId);
    if (index == -1) {
      state.budgets.add(budget);
    } else {
      state.budgets[index] = budget;
    }
  }
}

class _MemoryTravelHistoryRepository implements TravelHistoryRepository {
  _MemoryTravelHistoryRepository(this.state);

  final _MemoryState state;

  @override
  Future<void> deleteMemory(String id) async {
    state.memories.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteTrack(String id) async {
    state.tracks.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<TravelMemory>> listMemories({int? tripId}) async {
    return [
      for (final memory in state.memories)
        if (tripId == null || memory.tripId == tripId) memory,
    ];
  }

  @override
  Future<List<GpxTrack>> listTracks({int? tripId}) async {
    return [
      for (final track in state.tracks)
        if (tripId == null || track.tripId == tripId) track,
    ];
  }

  @override
  Future<TravelMemory> saveMemory(TravelMemory memory) async {
    final index = state.memories.indexWhere((item) => item.id == memory.id);
    if (index == -1) {
      state.memories.add(memory);
    } else {
      state.memories[index] = memory;
    }
    return memory;
  }

  @override
  Future<GpxTrack> saveTrack(GpxTrack track) async {
    final index = state.tracks.indexWhere((item) => item.id == track.id);
    if (index == -1) {
      state.tracks.add(track);
    } else {
      state.tracks[index] = track;
    }
    return track;
  }
}



class _MemoryRouteRepository implements RoutePreviewRepository {
  _MemoryRouteRepository([List<RouteResult> routes = const []])
      : routes = [...routes];

  final List<RouteResult> routes;

  @override
  Future<List<RouteResult>> listRoutes() async => [...routes];

  @override
  Future<void> deleteRouteForTrip(int tripId) async {
    routes.removeWhere((route) => route.tripId == tripId);
  }

  @override
  Future<RouteResult?> loadRouteForTrip(int tripId) async {
    for (final route in routes) {
      if (route.tripId == tripId) return route;
    }
    return null;
  }

  @override
  Future<RouteResult> saveRoute(RouteResult route) async {
    await deleteRouteForTrip(route.tripId);
    routes.add(route);
    return route;
  }
}

class _MemoryReminderRepository implements ReminderRepository {
  ReminderSettings settings = const ReminderSettings();
  final List<AppReminder> reminders = [];

  @override
  Future<void> deleteSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
  ) async {
    reminders.removeWhere(
      (item) => item.sourceType == sourceType && item.sourceId == sourceId,
    );
  }

  @override
  Future<List<AppReminder>> listReminders() async => [...reminders];

  @override
  Future<ReminderSettings> loadSettings() async => settings;

  @override
  Future<void> replaceAllReminders(List<AppReminder> next) async {
    reminders
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> replaceSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
    List<AppReminder> next,
  ) async {
    await deleteSourceReminders(sourceType, sourceId);
    reminders.addAll(next);
  }

  @override
  Future<void> saveSettings(ReminderSettings settings) async {
    this.settings = settings;
  }
}

const _profile = VehicleProfile(
  id: 1,
  vehicleType: 'Motorhome',
  brand: 'Fiat',
  model: 'Ducato',
  year: 2023,
  length: 7,
  width: 2.3,
  height: 3,
  weight: 3100,
  maxMass: 3500,
  seats: 4,
  fuelType: 'Diesel',
  mileage: 12000,
);
