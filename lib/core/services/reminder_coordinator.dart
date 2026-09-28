import 'package:flutter/foundation.dart';
import '../../data/models/app_reminder.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/maintenance_record.dart';
import '../../data/models/vehicle_document.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_reminder_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import 'local_notification_service.dart';
import 'reminder_factory.dart';

abstract interface class ReminderSyncService {
  Future<void> syncDocument(VehicleDocument document);
  Future<void> deleteDocumentReminders(String sourceId);
  Future<void> syncMaintenance(MaintenanceRecord record);
  Future<void> deleteMaintenanceReminders(String sourceId);
  Future<void> syncBooking(TripBooking booking);
  Future<void> deleteBookingReminders(String sourceId);
}

class ReminderCoordinator implements ReminderSyncService {
  ReminderCoordinator({
    ReminderRepository? reminderRepository,
    VehicleDocumentRepository? documentRepository,
    MaintenanceRepository? maintenanceRepository,
    FinanceRepository? financeRepository,
    LocalNotificationService? notificationService,
    ReminderFactory? factory,
    DateTime Function()? clock,
  })  : _reminderRepository = reminderRepository ?? LocalReminderRepository(),
        _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository(),
        _notificationService =
            notificationService ?? createLocalNotificationService(),
        _factory = factory ?? ReminderFactory(),
        _clock = clock ?? DateTime.now;

  final ReminderRepository _reminderRepository;
  final VehicleDocumentRepository _documentRepository;
  final MaintenanceRepository _maintenanceRepository;
  final FinanceRepository _financeRepository;
  final LocalNotificationService _notificationService;
  final ReminderFactory _factory;
  final DateTime Function() _clock;

  Future<void> initializeAndReconcile() async {
    await _notificationService.initialize();
    await reconcile();
  }

  Future<void> reconcile({DateTime? now}) async {
    final settings = await _reminderRepository.loadSettings();
    final documents = await _documentRepository.listDocuments();
    final maintenance = await _maintenanceRepository.listRecords();
    final bookings = await _financeRepository.listBookings();
    final reminders = <AppReminder>[
      for (final document in documents)
        ..._factory.forDocument(document, settings: settings, now: now),
      for (final record in maintenance)
        ..._factory.forMaintenance(record, settings: settings, now: now),
      for (final booking in bookings)
        ..._factory.forBooking(booking, settings: settings, now: now),
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final limited = _limitForPlatform(reminders);
    final groupedSources = <String, List<AppReminder>>{};
    for (final reminder in limited) {
      final key = '${reminder.sourceType.storageValue}:${reminder.sourceId}';
      groupedSources.putIfAbsent(key, () => []).add(reminder);
    }

    for (final document in documents) {
      final id = document.id;
      if (id == null) continue;
      await _reminderRepository.replaceSourceReminders(
        ReminderSourceType.document,
        id.toString(),
        groupedSources['document:$id'] ?? const [],
      );
    }
    for (final record in maintenance) {
      final id = record.id;
      if (id == null) continue;
      await _reminderRepository.replaceSourceReminders(
        ReminderSourceType.maintenance,
        id.toString(),
        groupedSources['maintenance:$id'] ?? const [],
      );
    }
    for (final booking in bookings) {
      await _reminderRepository.replaceSourceReminders(
        ReminderSourceType.booking,
        booking.id,
        groupedSources['booking:${booking.id}'] ?? const [],
      );
    }

    await _notificationService.rescheduleAll(limited);
  }

  Future<void> syncDocument(VehicleDocument document) async {
    final id = document.id;
    if (id == null) return;
    final settings = await _reminderRepository.loadSettings();
    final reminders = _factory.forDocument(
      document,
      settings: settings,
      now: _clock(),
    );
    await _reminderRepository.replaceSourceReminders(
      ReminderSourceType.document,
      id.toString(),
      reminders,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<void> deleteDocumentReminders(String sourceId) async {
    await _reminderRepository.deleteSourceReminders(
      ReminderSourceType.document,
      sourceId,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<void> syncMaintenance(MaintenanceRecord record) async {
    final id = record.id;
    if (id == null) return;
    final settings = await _reminderRepository.loadSettings();
    final reminders = _factory.forMaintenance(
      record,
      settings: settings,
      now: _clock(),
    );
    await _reminderRepository.replaceSourceReminders(
      ReminderSourceType.maintenance,
      id.toString(),
      reminders,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<void> deleteMaintenanceReminders(String sourceId) async {
    await _reminderRepository.deleteSourceReminders(
      ReminderSourceType.maintenance,
      sourceId,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<void> syncBooking(TripBooking booking) async {
    final settings = await _reminderRepository.loadSettings();
    final reminders = _factory.forBooking(
      booking,
      settings: settings,
      now: _clock(),
    );
    await _reminderRepository.replaceSourceReminders(
      ReminderSourceType.booking,
      booking.id,
      reminders,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<void> deleteBookingReminders(String sourceId) async {
    await _reminderRepository.deleteSourceReminders(
      ReminderSourceType.booking,
      sourceId,
    );
    await _notificationService.rescheduleAll(await activeReminders());
  }

  Future<List<AppReminder>> activeReminders() async {
    final reminders = await _reminderRepository.listReminders();
    final future = reminders
        .where((reminder) =>
            reminder.enabled && reminder.scheduledAt.isAfter(_clock()))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _limitForPlatform(future);
  }

  Future<ReminderSettings> loadSettings() => _reminderRepository.loadSettings();

  Future<void> saveSettings(ReminderSettings settings) async {
    await _reminderRepository.saveSettings(settings);
    await reconcile();
  }

  Future<NotificationPermissionState> permissionState() {
    return _notificationService.getPermissionState();
  }

  Future<bool> requestPermission() {
    return _notificationService.requestPermission();
  }

  Future<void> showTestNotification() {
    return _notificationService.showTestNotification();
  }

  ReminderPayload? consumeLaunchPayload() {
    return ReminderPayload.tryParse(
        _notificationService.consumeLaunchPayload());
  }

  List<AppReminder> _limitForPlatform(List<AppReminder> reminders) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return reminders;
    return _factory.limitForIos(reminders);
  }
}
