import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'document_storage_service.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/maintenance_record.dart';
import '../../data/models/travel_history_models.dart';
import '../../data/models/trip_plan.dart';
import '../../data/models/vehicle_document.dart';
import '../../data/models/vehicle_profile.dart';
import '../../data/repositories/local_checklist_repository.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_journal_repository.dart';
import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_travel_history_repository.dart';
import '../../data/repositories/local_trip_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import '../../data/repositories/local_vehicle_profile_repository.dart';

enum RestoreStrategy {
  replaceAll,
  merge,
}

class BackupOptions {
  const BackupOptions({
    this.outputDirectory,
    this.includeFiles = true,
    this.createdAt,
  });

  final Directory? outputDirectory;
  final bool includeFiles;
  final DateTime? createdAt;
}

class BackupResult {
  const BackupResult({
    required this.path,
    required this.manifest,
    required this.recordCount,
    required this.fileCount,
    required this.missingFiles,
  });

  final String path;
  final BackupManifest manifest;
  final int recordCount;
  final int fileCount;
  final List<String> missingFiles;
}

class BackupInspection {
  const BackupInspection({
    required this.isValid,
    required this.manifest,
    required this.recordCounts,
    required this.fileCount,
    required this.missingFiles,
    required this.errors,
  });

  final bool isValid;
  final BackupManifest? manifest;
  final Map<String, int> recordCounts;
  final int fileCount;
  final List<String> missingFiles;
  final List<String> errors;
}

class RestoreResult {
  const RestoreResult({
    required this.strategy,
    required this.restoredRecords,
    required this.skippedRecords,
    required this.conflicts,
    required this.automaticBackupPath,
  });

  final RestoreStrategy strategy;
  final int restoredRecords;
  final int skippedRecords;
  final int conflicts;
  final String automaticBackupPath;
}

class BackupManifest {
  const BackupManifest({
    required this.format,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.files,
  });

  final String format;
  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final List<BackupManifestFile> files;

  Map<String, Object?> toMap() {
    return {
      'format': format,
      'schemaVersion': schemaVersion,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'files': files.map((file) => file.toMap()).toList(),
    };
  }

  factory BackupManifest.fromMap(Map<String, Object?> map) {
    return BackupManifest(
      format: map['format'] as String? ?? '',
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 0,
      appVersion: map['appVersion'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      files: (map['files'] as List<dynamic>? ?? const [])
          .map((file) => BackupManifestFile.fromMap(
                Map<String, Object?>.from(file as Map),
              ))
          .toList(growable: false),
    );
  }
}

class BackupManifestFile {
  const BackupManifestFile({
    required this.path,
    required this.sha256,
    required this.size,
    this.sourcePath,
  });

  final String path;
  final String sha256;
  final int size;
  final String? sourcePath;

  Map<String, Object?> toMap() {
    return {
      'path': path,
      'sha256': sha256,
      'size': size,
      if (sourcePath != null) 'sourcePath': sourcePath,
    };
  }

  factory BackupManifestFile.fromMap(Map<String, Object?> map) {
    return BackupManifestFile(
      path: map['path'] as String,
      sha256: map['sha256'] as String,
      size: (map['size'] as num?)?.toInt() ?? 0,
      sourcePath: map['sourcePath'] as String?,
    );
  }
}

abstract interface class BackupCipher {
  Future<File> encrypt(File source, String password);
  Future<File> decrypt(File source, String password);
}

abstract interface class BackupService {
  Future<BackupResult> createBackup(BackupOptions options);
  Future<BackupInspection> inspectBackup(String path);
  Future<RestoreResult> restoreBackup(String path, RestoreStrategy strategy);
}

class DataBackupService implements BackupService {
  DataBackupService({
    VehicleProfileRepository? profileRepository,
    TripRepository? tripRepository,
    ChecklistRepository? checklistRepository,
    JournalRepository? journalRepository,
    MaintenanceRepository? maintenanceRepository,
    VehicleDocumentRepository? documentRepository,
    FinanceRepository? financeRepository,
    TravelHistoryRepository? travelHistoryRepository,
    DocumentStorageService? fileStorageService,
    String appVersion = '0.1.0',
  })  : _profileRepository =
            profileRepository ?? LocalVehicleProfileRepository(),
        _tripRepository = tripRepository ?? LocalTripRepository(),
        _checklistRepository =
            checklistRepository ?? LocalChecklistRepository(),
        _journalRepository = journalRepository ?? LocalJournalRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository(),
        _travelHistoryRepository =
            travelHistoryRepository ?? LocalTravelHistoryRepository(),
        _fileStorageService =
            fileStorageService ?? createDocumentStorageService(),
        _appVersion = appVersion;

  static const format = 'camperboss-backup';
  static const schemaVersion = 2;
  static const _supportedSchemaVersions = {1, 2};

  final VehicleProfileRepository _profileRepository;
  final TripRepository _tripRepository;
  final ChecklistRepository _checklistRepository;
  final JournalRepository _journalRepository;
  final MaintenanceRepository _maintenanceRepository;
  final VehicleDocumentRepository _documentRepository;
  final FinanceRepository _financeRepository;
  final TravelHistoryRepository _travelHistoryRepository;
  final DocumentStorageService _fileStorageService;
  final String _appVersion;

  @override
  Future<BackupResult> createBackup(BackupOptions options) async {
    final createdAt = options.createdAt ?? DateTime.now();
    final snapshot = await _loadSnapshot();
    final payloads = _buildDataPayloads(snapshot);
    final archive = Archive();
    final manifestFiles = <BackupManifestFile>[];

    for (final entry in payloads.entries) {
      final bytes = utf8.encode(_prettyJson(entry.value));
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
      manifestFiles.add(_manifestFile(entry.key, bytes));
    }

    final missingFiles = <String>[];
    var fileCount = 0;
    if (options.includeFiles) {
      final sourcePaths = _collectFilePaths(snapshot)
          .where((path) => path.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      for (final filePath in sourcePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          missingFiles.add(filePath);
          continue;
        }
        final bytes = await file.readAsBytes();
        final backupPath = _backupPathForFile(filePath);
        archive.addFile(ArchiveFile(backupPath, bytes.length, bytes));
        manifestFiles.add(
          _manifestFile(backupPath, bytes, sourcePath: filePath),
        );
        fileCount++;
      }
    }

    final manifest = BackupManifest(
      format: format,
      schemaVersion: schemaVersion,
      appVersion: _appVersion,
      createdAt: createdAt,
      files: manifestFiles..sort((a, b) => a.path.compareTo(b.path)),
    );
    final manifestBytes = utf8.encode(_prettyJson(manifest.toMap()));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final outputDirectory =
        options.outputDirectory ?? await _defaultDirectory();
    await outputDirectory.create(recursive: true);
    final fileName = 'camperboss_backup_${_dateStamp(createdAt)}.zip';
    final output = await _uniqueFile(outputDirectory, fileName);
    final encoded = ZipEncoder().encode(archive);
    await output.writeAsBytes(encoded, flush: true);

    return BackupResult(
      path: output.path,
      manifest: manifest,
      recordCount: snapshot.recordCount,
      fileCount: fileCount,
      missingFiles: missingFiles,
    );
  }

  @override
  Future<BackupInspection> inspectBackup(String path) async {
    final errors = <String>[];
    final missingFiles = <String>[];
    BackupManifest? manifest;
    Archive? archive;

    try {
      archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    } catch (_) {
      return BackupInspection(
        isValid: false,
        manifest: null,
        recordCounts: const {},
        fileCount: 0,
        missingFiles: const [],
        errors: const ['Archive is not a valid ZIP file'],
      );
    }

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      errors.add('manifest.json is missing');
    } else {
      try {
        manifest = BackupManifest.fromMap(
          Map<String, Object?>.from(
            jsonDecode(utf8.decode(_bytes(manifestFile))) as Map,
          ),
        );
      } catch (_) {
        errors.add('manifest.json is malformed');
      }
    }

    if (manifest != null) {
      if (manifest.format != format) errors.add('Unsupported backup format');
      if (!_supportedSchemaVersions.contains(manifest.schemaVersion)) {
        errors.add('Unsupported schema version');
      }
      for (final entry in manifest.files) {
        final archived = archive.findFile(entry.path);
        if (archived == null) {
          missingFiles.add(entry.path);
          continue;
        }
        final bytes = _bytes(archived);
        final actual = sha256.convert(bytes).toString();
        if (actual != entry.sha256) {
          errors.add('Hash mismatch: ${entry.path}');
        }
      }
    }

    final recordCounts = <String, int>{};
    for (final dataPath in _dataPaths) {
      final file = archive.findFile(dataPath);
      if (file == null) continue;
      try {
        final decoded = jsonDecode(utf8.decode(_bytes(file)));
        recordCounts[dataPath] = decoded is List ? decoded.length : 0;
      } catch (_) {
        errors.add('Malformed data file: $dataPath');
      }
    }

    final fileCount = archive.files
        .where((file) => file.isFile && file.name.startsWith('files/'))
        .length;

    return BackupInspection(
      isValid: errors.isEmpty && missingFiles.isEmpty,
      manifest: manifest,
      recordCounts: recordCounts,
      fileCount: fileCount,
      missingFiles: missingFiles,
      errors: errors,
    );
  }

  @override
  Future<RestoreResult> restoreBackup(
    String path,
    RestoreStrategy strategy,
  ) async {
    final inspection = await inspectBackup(path);
    if (!inspection.isValid) {
      throw StateError('Backup is not valid: ${inspection.errors.join(', ')}');
    }

    final automaticBackup = await createBackup(
      BackupOptions(
        outputDirectory: File(path).parent,
        includeFiles: true,
        createdAt: DateTime.now(),
      ),
    );
    final before = await _loadSnapshot();

    _MaterializedRestore? materialized;
    try {
      final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
      final snapshot = _snapshotFromArchive(archive);
      materialized = await _materializeSnapshotFiles(
        archive,
        inspection.manifest!,
        snapshot,
      );
      final result = strategy == RestoreStrategy.replaceAll
          ? await _replaceAll(materialized.snapshot)
          : await _merge(materialized.snapshot);
      return RestoreResult(
        strategy: strategy,
        restoredRecords: result.restored,
        skippedRecords: result.skipped,
        conflicts: result.conflicts,
        automaticBackupPath: automaticBackup.path,
      );
    } catch (_) {
      if (materialized != null) {
        await _fileStorageService.deleteFiles(materialized.copiedPaths);
      }
      await _replaceAll(before);
      rethrow;
    }
  }

  Future<File> exportVehiclePdf({Directory? outputDirectory}) async {
    final snapshot = await _loadSnapshot();
    final doc = pw.Document();
    final profile = snapshot.profile;
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(level: 0, text: 'CamperBoss vehicle export'),
          if (profile != null) ...[
            pw.Text('${profile.brand} ${profile.model}'),
            pw.Text('${profile.vehicleType} - ${profile.year}'),
            pw.Text(
              'Dimensions: ${profile.length} x ${profile.width} x ${profile.height} m',
            ),
            pw.Text('Mileage: ${profile.mileage} km'),
          ] else
            pw.Text('No vehicle profile saved.'),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Maintenance'),
          _pdfTable(
            ['Date', 'Title', 'Km', 'Cost'],
            snapshot.maintenance
                .map((item) => [
                      _date(item.date),
                      item.title,
                      item.mileage.toStringAsFixed(0),
                      item.cost?.toStringAsFixed(2) ?? '',
                    ])
                .toList(),
          ),
        ],
      ),
    );
    return _writeExport(
      outputDirectory: outputDirectory,
      fileName: 'camperboss_vehicle.pdf',
      bytes: await doc.save(),
    );
  }

  Future<File> exportTripPdf(
    int tripId, {
    Directory? outputDirectory,
  }) async {
    final snapshot = await _loadSnapshot();
    final matchingTrips = snapshot.trips.where((item) => item.id == tripId);
    final trip = matchingTrips.isEmpty ? null : matchingTrips.first;
    if (trip == null) throw StateError('Trip not found');
    final bookings = snapshot.bookings.where((item) => item.tripId == tripId);
    final expenses = snapshot.expenses.where((item) => item.tripId == tripId);
    final fuel = snapshot.fuelEntries.where((item) => item.tripId == tripId);
    final matchingBudgets =
        snapshot.budgets.where((item) => item.tripId == tripId);
    final budget = matchingBudgets.isEmpty ? null : matchingBudgets.first;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(level: 0, text: trip.title),
          pw.Text(trip.summary),
          if (trip.startDate != null || trip.endDate != null)
            pw.Text(
                '${_optionalDate(trip.startDate)} - ${_optionalDate(trip.endDate)}'),
          if (trip.stages.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Stages'),
            ...trip.stages.map((stage) => pw.Bullet(text: stage)),
          ],
          pw.Header(level: 1, text: 'Budget'),
          pw.Text('Planned: ${budget?.plannedAmountMinor ?? 0} minor units'),
          pw.Text(
            'Spent: ${expenses.fold<int>(0, (sum, item) => sum + item.amountMinor) + fuel.fold<int>(0, (sum, item) => sum + item.totalCostMinor)} minor units',
          ),
          pw.Header(level: 1, text: 'Bookings'),
          _pdfTable(
            ['Date', 'Title', 'Type', 'Cost'],
            bookings
                .map((item) => [
                      _optionalDate(item.startsAt),
                      item.title,
                      item.type.name,
                      item.costMinor?.toString() ?? '',
                    ])
                .toList(),
          ),
          if (trip.notes != null) ...[
            pw.Header(level: 1, text: 'Notes'),
            pw.Text(trip.notes!),
          ],
        ],
      ),
    );
    return _writeExport(
      outputDirectory: outputDirectory,
      fileName: 'camperboss_trip_$tripId.pdf',
      bytes: await doc.save(),
    );
  }

  Future<Map<String, File>> exportCsv({Directory? outputDirectory}) async {
    final snapshot = await _loadSnapshot();
    return {
      'fuel': await _writeExport(
        outputDirectory: outputDirectory,
        fileName: 'camperboss_fuel.csv',
        bytes: utf8.encode(_csv([
          [
            'id',
            'vehicle_id',
            'trip_id',
            'date',
            'odometer_km',
            'volume_ml',
            'total_cost_minor',
            'currency_code'
          ],
          for (final item in snapshot.fuelEntries)
            [
              item.id,
              item.vehicleId,
              item.tripId ?? '',
              item.date.toIso8601String(),
              item.odometerKm,
              item.volumeMilliLitres,
              item.totalCostMinor,
              item.currencyCode,
            ],
        ])),
      ),
      'expenses': await _writeExport(
        outputDirectory: outputDirectory,
        fileName: 'camperboss_expenses.csv',
        bytes: utf8.encode(_csv([
          [
            'id',
            'scope',
            'trip_id',
            'vehicle_id',
            'category',
            'amount_minor',
            'currency_code',
            'occurred_at'
          ],
          for (final item in snapshot.expenses)
            [
              item.id,
              item.scope.name,
              item.tripId ?? '',
              item.vehicleId ?? '',
              item.category.name,
              item.amountMinor,
              item.currencyCode,
              item.occurredAt.toIso8601String(),
            ],
        ])),
      ),
      'maintenance': await _writeExport(
        outputDirectory: outputDirectory,
        fileName: 'camperboss_maintenance.csv',
        bytes: utf8.encode(_csv([
          ['id', 'category', 'title', 'date', 'mileage', 'cost', 'provider'],
          for (final item in snapshot.maintenance)
            [
              item.id ?? '',
              item.category,
              item.title,
              item.date.toIso8601String(),
              item.mileage,
              item.cost ?? '',
              item.provider ?? '',
            ],
        ])),
      ),
    };
  }

  Future<_BackupSnapshot> _loadSnapshot() async {
    final profile = await _profileRepository.loadProfile();
    final trips = await _tripRepository.listTrips();
    final budgets = <TripBudget>[];
    for (final trip in trips) {
      final id = trip.id;
      if (id == null) continue;
      final budget = await _financeRepository.loadTripBudget(id);
      if (budget != null) budgets.add(budget);
    }
    return _BackupSnapshot(
      profile: profile,
      trips: trips,
      checklist: await _checklistRepository.listItems(),
      journal: await _journalRepository.listEntries(),
      maintenance: await _maintenanceRepository.listRecords(),
      documents: await _documentRepository.listDocuments(),
      expenses: await _financeRepository.listExpenses(),
      fuelEntries: await _financeRepository.listFuelEntries(),
      budgets: budgets,
      bookings: await _financeRepository.listBookings(),
      tracks: await _travelHistoryRepository.listTracks(),
      memories: await _travelHistoryRepository.listMemories(),
    );
  }

  Map<String, Object?> _buildDataPayloads(_BackupSnapshot snapshot) {
    return {
      'data/vehicles.json': [
        if (snapshot.profile != null) snapshot.profile!.toMap(),
      ],
      'data/trips.json': snapshot.trips.map((item) => item.toMap()).toList(),
      'data/checklist.json':
          snapshot.checklist.map((item) => item.toMap()).toList(),
      'data/journal.json':
          snapshot.journal.map((item) => item.toMap()).toList(),
      'data/maintenance.json':
          snapshot.maintenance.map((item) => item.toMap()).toList(),
      'data/documents.json':
          snapshot.documents.map((item) => item.toMap()).toList(),
      'data/expenses.json':
          snapshot.expenses.map((item) => item.toMap()).toList(),
      'data/fuel.json':
          snapshot.fuelEntries.map((item) => item.toMap()).toList(),
      'data/budgets.json':
          snapshot.budgets.map((item) => item.toMap()).toList(),
      'data/bookings.json':
          snapshot.bookings.map((item) => item.toMap()).toList(),
      'data/gpx_tracks.json':
          snapshot.tracks.map((item) => item.toMap()).toList(),
      'data/travel_memories.json':
          snapshot.memories.map((item) => item.toMap()).toList(),
    };
  }

  _BackupSnapshot _snapshotFromArchive(Archive archive) {
    List<Map<String, Object?>> rows(String name) {
      final file = archive.findFile(name);
      if (file == null) return const [];
      final decoded = jsonDecode(utf8.decode(_bytes(file))) as List<dynamic>;
      return decoded
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList(growable: false);
    }

    final vehicles = rows('data/vehicles.json');
    return _BackupSnapshot(
      profile: vehicles.isEmpty ? null : VehicleProfile.fromMap(vehicles.first),
      trips: rows('data/trips.json').map(TripPlan.fromMap).toList(),
      checklist:
          rows('data/checklist.json').map(CamperChecklistItem.fromMap).toList(),
      journal: rows('data/journal.json').map(JournalEntry.fromMap).toList(),
      maintenance:
          rows('data/maintenance.json').map(MaintenanceRecord.fromMap).toList(),
      documents:
          rows('data/documents.json').map(VehicleDocument.fromMap).toList(),
      expenses: rows('data/expenses.json').map(Expense.fromMap).toList(),
      fuelEntries: rows('data/fuel.json').map(FuelEntry.fromMap).toList(),
      budgets: rows('data/budgets.json').map(TripBudget.fromMap).toList(),
      bookings: rows('data/bookings.json').map(TripBooking.fromMap).toList(),
      tracks: rows('data/gpx_tracks.json').map(GpxTrack.fromMap).toList(),
      memories:
          rows('data/travel_memories.json').map(TravelMemory.fromMap).toList(),
    );
  }

  Future<_MaterializedRestore> _materializeSnapshotFiles(
    Archive archive,
    BackupManifest manifest,
    _BackupSnapshot snapshot,
  ) async {
    final sourceToArchive = <String, String>{
      for (final entry in manifest.files)
        if (entry.sourcePath != null && entry.sourcePath!.isNotEmpty)
          entry.sourcePath!: entry.path,
    };
    final legacyByBasename = <String, List<String>>{};
    if (manifest.schemaVersion == 1) {
      for (final entry in manifest.files.where(
        (entry) => entry.path.startsWith('files/'),
      )) {
        legacyByBasename
            .putIfAbsent(p.basename(entry.path), () => <String>[])
            .add(entry.path);
      }
    }

    final copiedPaths = <String>[];
    final remap = <String, String>{};
    final stage =
        await Directory.systemTemp.createTemp('camperboss_restore_stage_');
    try {
      final referencedPaths = _collectFilePaths(snapshot)
          .where((path) => path.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      for (final originalPath in referencedPaths) {
        var archivePath = sourceToArchive[originalPath];
        if (archivePath == null && manifest.schemaVersion == 1) {
          final candidates = legacyByBasename[p.basename(originalPath)];
          if (candidates != null && candidates.length == 1) {
            archivePath = candidates.single;
          }
        }
        if (archivePath == null) continue;

        final archived = archive.findFile(archivePath);
        if (archived == null) {
          throw StateError('Backup file missing during restore: $archivePath');
        }
        final staged = File(
          p.join(
            stage.path,
            '${remap.length}_${_safeFileName(p.basename(originalPath))}',
          ),
        );
        await staged.writeAsBytes(_bytes(archived), flush: true);
        final privatePath =
            await _fileStorageService.copyIntoPrivateDocuments(staged.path);
        remap[originalPath] = privatePath;
        copiedPaths.add(privatePath);
      }

      return _MaterializedRestore(
        snapshot: _remapSnapshotPaths(snapshot, remap),
        copiedPaths: copiedPaths,
      );
    } catch (_) {
      await _fileStorageService.deleteFiles(copiedPaths);
      rethrow;
    } finally {
      if (stage.existsSync()) {
        await stage.delete(recursive: true);
      }
    }
  }

  _BackupSnapshot _remapSnapshotPaths(
    _BackupSnapshot snapshot,
    Map<String, String> remap,
  ) {
    String mapPath(String value) => remap[value] ?? value;
    String? mapOptionalPath(String? value) =>
        value == null ? null : mapPath(value);

    return _BackupSnapshot(
      profile: snapshot.profile,
      trips: snapshot.trips,
      checklist: snapshot.checklist,
      journal: snapshot.journal,
      maintenance: [
        for (final item in snapshot.maintenance)
          item.copyWith(
            attachmentPaths:
                item.attachmentPaths.map(mapPath).toList(growable: false),
          ),
      ],
      documents: [
        for (final item in snapshot.documents)
          item.copyWith(
            localFilePath: mapPath(item.localFilePath),
            thumbnailPath: mapOptionalPath(item.thumbnailPath),
            pagePaths: item.pagePaths.map(mapPath).toList(growable: false),
            pdfPath: mapOptionalPath(item.pdfPath),
          ),
      ],
      expenses: snapshot.expenses,
      fuelEntries: snapshot.fuelEntries,
      budgets: snapshot.budgets,
      bookings: snapshot.bookings,
      tracks: [
        for (final item in snapshot.tracks)
          item.copyWith(localFilePath: mapOptionalPath(item.localFilePath)),
      ],
      memories: [
        for (final item in snapshot.memories)
          item.copyWith(
            localPhotoPaths:
                item.localPhotoPaths.map(mapPath).toList(growable: false),
          ),
      ],
    );
  }

  Future<_RestoreCounters> _replaceAll(_BackupSnapshot snapshot) async {
    final current = await _loadSnapshot();
    for (final item in current.bookings) {
      await _financeRepository.deleteBooking(item.id);
    }
    for (final item in current.fuelEntries) {
      await _financeRepository.deleteFuelEntry(item.id);
    }
    for (final item in current.expenses) {
      await _financeRepository.deleteExpense(item.id);
    }
    for (final item in current.budgets) {
      await _financeRepository.deleteTripBudget(item.tripId);
    }
    for (final item in current.documents) {
      await _documentRepository.deleteDocument(item);
    }
    for (final item in current.maintenance) {
      final id = item.id;
      if (id != null) await _maintenanceRepository.deleteRecord(id);
    }
    for (final item in current.journal) {
      final id = item.id;
      if (id != null) await _journalRepository.deleteEntry(id);
    }
    for (final item in current.checklist) {
      final id = item.id;
      if (id != null) await _checklistRepository.deleteItem(id);
    }
    for (final item in current.trips) {
      final id = item.id;
      if (id != null) await _tripRepository.deleteTrip(id);
    }
    for (final item in current.memories) {
      await _travelHistoryRepository.deleteMemory(item.id);
    }
    for (final item in current.tracks) {
      await _travelHistoryRepository.deleteTrack(item.id);
    }
    await _profileRepository.deleteProfile();
    return _saveAll(snapshot);
  }

  Future<_RestoreCounters> _merge(_BackupSnapshot snapshot) async {
    final current = await _loadSnapshot();
    final counters = _RestoreCounters();
    if (snapshot.profile != null) {
      await _profileRepository.saveProfile(snapshot.profile!);
      counters.restored++;
    }
    await _mergeInt(
      incoming: snapshot.trips,
      current: current.trips,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      save: _tripRepository.saveTrip,
      counters: counters,
    );
    await _mergeInt(
      incoming: snapshot.checklist,
      current: current.checklist,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      save: _checklistRepository.saveItem,
      counters: counters,
    );
    await _mergeInt(
      incoming: snapshot.journal,
      current: current.journal,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      save: _journalRepository.saveEntry,
      counters: counters,
    );
    await _mergeInt(
      incoming: snapshot.maintenance,
      current: current.maintenance,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      save: _maintenanceRepository.saveRecord,
      counters: counters,
    );
    await _mergeInt(
      incoming: snapshot.documents,
      current: current.documents,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      save: _documentRepository.saveDocument,
      counters: counters,
    );
    await _mergeString(
      incoming: snapshot.expenses,
      current: current.expenses,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.occurredAt,
      save: _financeRepository.saveExpense,
      counters: counters,
    );
    await _mergeString(
      incoming: snapshot.fuelEntries,
      current: current.fuelEntries,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.date,
      save: _financeRepository.saveFuelEntry,
      counters: counters,
    );
    for (final budget in snapshot.budgets) {
      await _financeRepository.saveTripBudget(budget);
      counters.restored++;
    }
    await _mergeString(
      incoming: snapshot.bookings,
      current: current.bookings,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.startsAt ?? item.endsAt,
      save: _financeRepository.saveBooking,
      counters: counters,
    );
    await _mergeString(
      incoming: snapshot.tracks,
      current: current.tracks,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt ?? item.createdAt,
      save: _travelHistoryRepository.saveTrack,
      counters: counters,
    );
    await _mergeString(
      incoming: snapshot.memories,
      current: current.memories,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt ?? item.createdAt,
      save: _travelHistoryRepository.saveMemory,
      counters: counters,
    );
    return counters;
  }

  Future<_RestoreCounters> _saveAll(_BackupSnapshot snapshot) async {
    final counters = _RestoreCounters();
    if (snapshot.profile != null) {
      await _profileRepository.saveProfile(snapshot.profile!);
      counters.restored++;
    }
    for (final item in snapshot.trips) {
      await _tripRepository.saveTrip(item);
      counters.restored++;
    }
    for (final item in snapshot.checklist) {
      await _checklistRepository.saveItem(item);
      counters.restored++;
    }
    for (final item in snapshot.journal) {
      await _journalRepository.saveEntry(item);
      counters.restored++;
    }
    for (final item in snapshot.maintenance) {
      await _maintenanceRepository.saveRecord(item);
      counters.restored++;
    }
    for (final item in snapshot.documents) {
      await _documentRepository.saveDocument(item);
      counters.restored++;
    }
    for (final item in snapshot.expenses) {
      await _financeRepository.saveExpense(item);
      counters.restored++;
    }
    for (final item in snapshot.fuelEntries) {
      await _financeRepository.saveFuelEntry(item);
      counters.restored++;
    }
    for (final item in snapshot.budgets) {
      await _financeRepository.saveTripBudget(item);
      counters.restored++;
    }
    for (final item in snapshot.bookings) {
      await _financeRepository.saveBooking(item);
      counters.restored++;
    }
    for (final item in snapshot.tracks) {
      await _travelHistoryRepository.saveTrack(item);
      counters.restored++;
    }
    for (final item in snapshot.memories) {
      await _travelHistoryRepository.saveMemory(item);
      counters.restored++;
    }
    return counters;
  }

  Future<void> _mergeInt<T extends Object>({
    required List<T> incoming,
    required List<T> current,
    required int? Function(T item) idOf,
    required DateTime? Function(T item) updatedAtOf,
    required Future<Object?> Function(T item) save,
    required _RestoreCounters counters,
  }) async {
    final byId = {
      for (final item in current)
        if (idOf(item) != null) idOf(item): item
    };
    for (final item in incoming) {
      final id = idOf(item);
      final existing = id == null ? null : byId[id];
      if (existing != null &&
          !_isIncomingNewer(updatedAtOf(item), updatedAtOf(existing))) {
        counters.skipped++;
        if (_canonical(item) != _canonical(existing)) counters.conflicts++;
        continue;
      }
      await save(item);
      counters.restored++;
    }
  }

  Future<void> _mergeString<T extends Object>({
    required List<T> incoming,
    required List<T> current,
    required String Function(T item) idOf,
    required DateTime? Function(T item) updatedAtOf,
    required Future<Object?> Function(T item) save,
    required _RestoreCounters counters,
  }) async {
    final byId = {for (final item in current) idOf(item): item};
    for (final item in incoming) {
      final existing = byId[idOf(item)];
      if (existing != null &&
          !_isIncomingNewer(updatedAtOf(item), updatedAtOf(existing))) {
        counters.skipped++;
        if (_canonical(item) != _canonical(existing)) counters.conflicts++;
        continue;
      }
      await save(item);
      counters.restored++;
    }
  }

  bool _isIncomingNewer(DateTime? incoming, DateTime? existing) {
    if (existing == null) return true;
    if (incoming == null) return false;
    return incoming.isAfter(existing);
  }

  Iterable<String> _collectFilePaths(_BackupSnapshot snapshot) sync* {
    for (final document in snapshot.documents) {
      yield* document.filePaths;
    }
    for (final maintenance in snapshot.maintenance) {
      yield* maintenance.attachmentPaths;
    }
    for (final track in snapshot.tracks) {
      if (track.localFilePath != null && track.localFilePath!.isNotEmpty) {
        yield track.localFilePath!;
      }
    }
    for (final memory in snapshot.memories) {
      yield* memory.localPhotoPaths;
    }
  }

  String _backupPathForFile(String filePath) {
    final name = p.basename(filePath);
    final directory =
        filePath.toLowerCase().contains('thumb') ? 'thumbnails' : 'documents';
    final digest =
        sha256.convert(utf8.encode(filePath)).toString().substring(0, 16);
    return 'files/$directory/${digest}_${_safeFileName(name)}';
  }

  BackupManifestFile _manifestFile(
    String path,
    List<int> bytes, {
    String? sourcePath,
  }) {
    return BackupManifestFile(
      path: path,
      sha256: sha256.convert(bytes).toString(),
      size: bytes.length,
      sourcePath: sourcePath,
    );
  }

  List<int> _bytes(ArchiveFile file) {
    return file.content;
  }

  String _prettyJson(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  String _canonical(Object value) {
    if (value is VehicleProfile) return jsonEncode(value.toMap());
    if (value is TripPlan) return jsonEncode(value.toMap());
    if (value is CamperChecklistItem) return jsonEncode(value.toMap());
    if (value is JournalEntry) return jsonEncode(value.toMap());
    if (value is MaintenanceRecord) return jsonEncode(value.toMap());
    if (value is VehicleDocument) return jsonEncode(value.toMap());
    if (value is Expense) return jsonEncode(value.toMap());
    if (value is FuelEntry) return jsonEncode(value.toMap());
    if (value is TripBooking) return jsonEncode(value.toMap());
    if (value is GpxTrack) return jsonEncode(value.toMap());
    if (value is TravelMemory) return jsonEncode(value.toMap());
    return value.toString();
  }

  Future<Directory> _defaultDirectory() async {
    return getTemporaryDirectory();
  }

  Future<File> _writeExport({
    required Directory? outputDirectory,
    required String fileName,
    required List<int> bytes,
  }) async {
    final directory = outputDirectory ?? await _defaultDirectory();
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName));
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> _uniqueFile(Directory directory, String fileName) async {
    final base = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    var candidate = File(p.join(directory.path, fileName));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '$base-$suffix$extension'));
      suffix++;
    }
    return candidate;
  }

  pw.Widget _pdfTable(List<String> headers, List<List<String>> rows) {
    if (rows.isEmpty) return pw.Text('No records.');
    return pw.TableHelper.fromTextArray(headers: headers, data: rows);
  }

  String _csv(List<List<Object?>> rows) {
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  String _csvCell(Object? value) {
    final text = (value ?? '').toString();
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _dateStamp(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _date(DateTime date) => _dateStamp(date);

  String _optionalDate(DateTime? date) => date == null ? '' : _date(date);

  String _safeFileName(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

class _MaterializedRestore {
  const _MaterializedRestore({
    required this.snapshot,
    required this.copiedPaths,
  });

  final _BackupSnapshot snapshot;
  final List<String> copiedPaths;
}

class _BackupSnapshot {
  const _BackupSnapshot({
    required this.profile,
    required this.trips,
    required this.checklist,
    required this.journal,
    required this.maintenance,
    required this.documents,
    required this.expenses,
    required this.fuelEntries,
    required this.budgets,
    required this.bookings,
    required this.tracks,
    required this.memories,
  });

  final VehicleProfile? profile;
  final List<TripPlan> trips;
  final List<CamperChecklistItem> checklist;
  final List<JournalEntry> journal;
  final List<MaintenanceRecord> maintenance;
  final List<VehicleDocument> documents;
  final List<Expense> expenses;
  final List<FuelEntry> fuelEntries;
  final List<TripBudget> budgets;
  final List<TripBooking> bookings;
  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;

  int get recordCount {
    return (profile == null ? 0 : 1) +
        trips.length +
        checklist.length +
        journal.length +
        maintenance.length +
        documents.length +
        expenses.length +
        fuelEntries.length +
        budgets.length +
        bookings.length +
        tracks.length +
        memories.length;
  }
}

class _RestoreCounters {
  var restored = 0;
  var skipped = 0;
  var conflicts = 0;
}

const _dataPaths = [
  'data/vehicles.json',
  'data/trips.json',
  'data/checklist.json',
  'data/journal.json',
  'data/maintenance.json',
  'data/documents.json',
  'data/expenses.json',
  'data/fuel.json',
  'data/budgets.json',
  'data/bookings.json',
  'data/gpx_tracks.json',
  'data/travel_memories.json',
];
