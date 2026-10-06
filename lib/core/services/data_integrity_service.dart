import '../../data/models/app_reminder.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_journal_repository.dart';
import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_reminder_repository.dart';
import '../../data/repositories/local_route_preview_repository.dart';
import '../../data/repositories/local_travel_history_repository.dart';
import '../../data/repositories/local_trip_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import 'local_file_probe.dart';

class DataIntegrityIssue {
  const DataIntegrityIssue({
    required this.code,
    required this.entityId,
    required this.message,
  });

  final String code;
  final String entityId;
  final String message;
}

class DataIntegrityReport {
  const DataIntegrityReport(this.issues);

  final List<DataIntegrityIssue> issues;

  bool get isClean => issues.isEmpty;
}

/// Read-only cross-domain integrity audit. It never deletes user data.
class DataIntegrityService {
  DataIntegrityService({
    TripRepository? tripRepository,
    FinanceRepository? financeRepository,
    JournalRepository? journalRepository,
    VehicleDocumentRepository? documentRepository,
    MaintenanceRepository? maintenanceRepository,
    TravelHistoryRepository? travelHistoryRepository,
    ReminderRepository? reminderRepository,
    RoutePreviewRepository? routeRepository,
    LocalFileProbe fileProbe = const LocalFileProbe(),
  })  : _tripRepository = tripRepository ?? LocalTripRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository(),
        _journalRepository = journalRepository ?? LocalJournalRepository(),
        _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _travelHistoryRepository =
            travelHistoryRepository ?? LocalTravelHistoryRepository(),
        _reminderRepository = reminderRepository ?? LocalReminderRepository(),
        _routeRepository = routeRepository ?? LocalRoutePreviewRepository(),
        _fileProbe = fileProbe;

  final TripRepository _tripRepository;
  final FinanceRepository _financeRepository;
  final JournalRepository _journalRepository;
  final VehicleDocumentRepository _documentRepository;
  final MaintenanceRepository _maintenanceRepository;
  final TravelHistoryRepository _travelHistoryRepository;
  final ReminderRepository _reminderRepository;
  final RoutePreviewRepository _routeRepository;
  final LocalFileProbe _fileProbe;

  Future<DataIntegrityReport> audit() async {
    final trips = await _tripRepository.listTrips();
    final expenses = await _financeRepository.listExpenses();
    final fuel = await _financeRepository.listFuelEntries();
    final bookings = await _financeRepository.listBookings();
    final budgets = _financeRepository is LocalFinanceRepository
        ? await _financeRepository.listTripBudgets()
        : const [];
    final journal = await _journalRepository.listEntries();
    final documents = await _documentRepository.listDocuments();
    final maintenance = await _maintenanceRepository.listRecords();
    final tracks = await _travelHistoryRepository.listTracks();
    final memories = await _travelHistoryRepository.listMemories();
    final reminders = await _reminderRepository.listReminders();
    final routes = _routeRepository is LocalRoutePreviewRepository
        ? await _routeRepository.listRoutes()
        : const [];

    final issues = <DataIntegrityIssue>[];
    final tripIds = trips.map((item) => item.id).whereType<int>().toSet();
    final documentIds =
        documents.map((item) => item.id).whereType<int>().toSet();
    final maintenanceIds =
        maintenance.map((item) => item.id).whereType<int>().toSet();
    final bookingIds = bookings.map((item) => item.id).toSet();

    void checkTripRef(String kind, String id, int? tripId) {
      if (tripId != null && !tripIds.contains(tripId)) {
        issues.add(
          DataIntegrityIssue(
            code: 'orphan_trip_reference',
            entityId: '$kind:$id',
            message: 'References missing trip $tripId',
          ),
        );
      }
    }

    void checkDocumentRef(String kind, String id, int? documentId) {
      if (documentId != null && !documentIds.contains(documentId)) {
        issues.add(
          DataIntegrityIssue(
            code: 'orphan_document_reference',
            entityId: '$kind:$id',
            message: 'References missing document $documentId',
          ),
        );
      }
    }

    for (final item in expenses) {
      checkTripRef('expense', item.id, item.tripId);
      checkDocumentRef('expense', item.id, item.documentId);
    }
    for (final item in fuel) {
      checkTripRef('fuel', item.id, item.tripId);
      checkDocumentRef('fuel', item.id, item.documentId);
    }
    for (final item in bookings) {
      checkTripRef('booking', item.id, item.tripId);
      checkDocumentRef('booking', item.id, item.documentId);
    }
    for (final item in budgets) {
      checkTripRef('budget', item.tripId.toString(), item.tripId);
    }
    for (final item in tracks) {
      checkTripRef('gpx', item.id, item.tripId);
    }
    for (final item in memories) {
      checkTripRef('memory', item.id, item.tripId);
    }
    for (final route in routes) {
      checkTripRef('route', route.tripId.toString(), route.tripId);
    }
    for (final reminder in reminders) {
      final sourceId = int.tryParse(reminder.sourceId);
      final valid = switch (reminder.sourceType) {
        ReminderSourceType.document =>
          sourceId != null && documentIds.contains(sourceId),
        ReminderSourceType.maintenance =>
          sourceId != null && maintenanceIds.contains(sourceId),
        ReminderSourceType.booking => bookingIds.contains(reminder.sourceId),
        ReminderSourceType.custom => true,
      };
      if (!valid) {
        issues.add(
          DataIntegrityIssue(
            code: 'orphan_reminder_source',
            entityId: 'reminder:${reminder.id}',
            message:
                'References missing ${reminder.sourceType.storageValue} ${reminder.sourceId}',
          ),
        );
      }
    }

    if (_fileProbe.isSupported) {
      for (final document in documents) {
        for (final path in document.filePaths.where((item) => item.isNotEmpty)) {
          await _checkPath(issues, 'document', document.id?.toString() ?? document.title, path);
        }
      }
      for (final record in maintenance) {
        for (final path in record.attachmentPaths.where((item) => item.isNotEmpty)) {
          await _checkPath(issues, 'maintenance', record.id?.toString() ?? record.title, path);
        }
      }
      for (final track in tracks) {
        final path = track.localFilePath;
        if (path != null && path.isNotEmpty) {
          await _checkPath(issues, 'gpx', track.id, path);
        }
      }
      for (final memory in memories) {
        for (final path in memory.localPhotoPaths.where((item) => item.isNotEmpty)) {
          await _checkPath(issues, 'memory', memory.id, path);
        }
      }
    }

    _checkDuplicateIds(issues, 'trip', trips.map((item) => item.id?.toString()));
    _checkDuplicateIds(
      issues,
      'journal',
      journal.map((item) => item.id?.toString()),
    );
    _checkDuplicateIds(
      issues,
      'document',
      documents.map((item) => item.id?.toString()),
    );
    _checkDuplicateIds(
      issues,
      'maintenance',
      maintenance.map((item) => item.id?.toString()),
    );
    _checkDuplicateIds(issues, 'expense', expenses.map((item) => item.id));
    _checkDuplicateIds(issues, 'fuel', fuel.map((item) => item.id));
    _checkDuplicateIds(issues, 'booking', bookings.map((item) => item.id));
    _checkDuplicateIds(issues, 'gpx', tracks.map((item) => item.id));
    _checkDuplicateIds(issues, 'memory', memories.map((item) => item.id));
    _checkDuplicateIds(issues, 'reminder', reminders.map((item) => item.id));
    _checkDuplicateIds(
      issues,
      'route',
      routes.map((item) => item.tripId.toString()),
    );

    return DataIntegrityReport(List.unmodifiable(issues));
  }

  Future<void> _checkPath(
    List<DataIntegrityIssue> issues,
    String kind,
    String id,
    String path,
  ) async {
    if (!await _fileProbe.exists(path)) {
      issues.add(
        DataIntegrityIssue(
          code: 'missing_media_file',
          entityId: '$kind:$id',
          message: 'Referenced local file is missing: $path',
        ),
      );
    }
  }

  void _checkDuplicateIds(
    List<DataIntegrityIssue> issues,
    String kind,
    Iterable<String?> ids,
  ) {
    final seen = <String>{};
    for (final id in ids.whereType<String>()) {
      if (!seen.add(id)) {
        issues.add(
          DataIntegrityIssue(
            code: 'duplicate_id',
            entityId: '$kind:$id',
            message: 'Duplicate $kind id $id',
          ),
        );
      }
    }
  }
}
