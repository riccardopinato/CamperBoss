import 'package:camperboss/core/services/fake_local_notification_service.dart';
import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/core/services/local_notification_service.dart';
import 'package:camperboss/core/services/reminder_coordinator.dart';
import 'package:camperboss/core/services/reminder_factory.dart';
import 'package:camperboss/data/models/app_reminder.dart';
import 'package:camperboss/data/models/maintenance_record.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/repositories/local_maintenance_repository.dart';
import 'package:camperboss/data/repositories/local_reminder_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/features/settings/presentation/notification_settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryReminderRepository implements ReminderRepository {
  ReminderSettings settings = const ReminderSettings();
  final reminders = <AppReminder>[];

  @override
  Future<void> deleteSourceReminders(
    ReminderSourceType sourceType,
    String sourceId,
  ) async {
    reminders.removeWhere(
      (reminder) =>
          reminder.sourceType == sourceType && reminder.sourceId == sourceId,
    );
  }

  @override
  Future<List<AppReminder>> listReminders() async => [...reminders];

  @override
  Future<ReminderSettings> loadSettings() async => settings;

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

class MemoryDocumentRepository implements VehicleDocumentRepository {
  MemoryDocumentRepository(this.documents);

  final List<VehicleDocument> documents;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {}

  @override
  Future<List<VehicleDocument>> listDocuments() async => documents;

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async {
    return document;
  }
}

class MemoryMaintenanceRepository implements MaintenanceRepository {
  MemoryMaintenanceRepository(this.records);

  final List<MaintenanceRecord> records;

  @override
  Future<void> deleteRecord(int id) async {}

  @override
  Future<List<MaintenanceRecord>> listRecords() async => records;

  @override
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record) async {
    return record;
  }
}

void main() {
  test('generates stable notification ids without hashCode', () {
    expect(stableNotificationId('document:42:30'), isPositive);
    expect(
      stableNotificationId('document:42:30'),
      stableNotificationId('document:42:30'),
    );
    expect(
      stableNotificationId('document:42:30'),
      isNot(stableNotificationId('document:42:7')),
    );
  });

  test('generates 30/7/1/0 day document reminders at 09:00', () {
    final factory = ReminderFactory();
    final reminders = factory.forDocument(
      VehicleDocument(
        id: 42,
        category: 'document_category_insurance',
        title: 'Insurance',
        localFilePath: '/private/insurance.pdf',
        mimeType: 'application/pdf',
        ocrStatus: DocumentOcrStatus.notRequested,
        expiryDate: DateTime(2026, 8, 31),
      ),
      now: DateTime(2026, 7, 1),
    );

    expect(reminders.map((item) => item.scheduledAt), [
      DateTime(2026, 8, 1, 9),
      DateTime(2026, 8, 24, 9),
      DateTime(2026, 8, 30, 9),
      DateTime(2026, 8, 31, 9),
    ]);
  });

  test('excludes reminder dates in the past', () {
    final reminders = ReminderFactory().forMaintenance(
      MaintenanceRecord(
        id: 7,
        category: 'Oil',
        title: 'Oil service',
        date: DateTime(2026, 1, 1),
        mileage: 30000,
        nextDueDate: DateTime(2026, 7, 10),
      ),
      now: DateTime(2026, 7, 9, 10),
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.id, 'maintenance:7:0');
  });

  test('reschedules changed document expiry', () async {
    final repository = MemoryReminderRepository();
    final notifications = FakeLocalNotificationService();
    final coordinator = ReminderCoordinator(
      reminderRepository: repository,
      documentRepository: MemoryDocumentRepository(const []),
      maintenanceRepository: MemoryMaintenanceRepository(const []),
      notificationService: notifications,
    );

    await coordinator.syncDocument(_document(DateTime(2026, 8, 31)));
    await coordinator.syncDocument(_document(DateTime(2026, 9, 30)));

    expect(repository.reminders, hasLength(4));
    expect(repository.reminders.first.scheduledAt, DateTime(2026, 8, 31, 9));
    expect(notifications.scheduled, hasLength(4));
  });

  test('deletes document reminders', () async {
    final repository = MemoryReminderRepository();
    final coordinator = ReminderCoordinator(
      reminderRepository: repository,
      documentRepository: MemoryDocumentRepository(const []),
      maintenanceRepository: MemoryMaintenanceRepository(const []),
      notificationService: FakeLocalNotificationService(),
    );

    await coordinator.syncDocument(_document(DateTime(2026, 8, 31)));
    await coordinator.deleteDocumentReminders('42');

    expect(repository.reminders, isEmpty);
  });

  test('limits iOS scheduling to the nearest 50 reminders', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final reminders = List.generate(
      80,
      (index) => AppReminder(
        id: 'custom:$index:0',
        sourceType: ReminderSourceType.custom,
        sourceId: '$index',
        title: 'Reminder $index',
        body: 'Body',
        scheduledAt: DateTime(2026, 1, 1 + index, 9),
      ),
    );

    expect(ReminderFactory().limitForIos(reminders), hasLength(50));
  });

  test('controller saves settings and requests permission explicitly',
      () async {
    final repository = MemoryReminderRepository();
    final notifications = FakeLocalNotificationService()
      ..permissionState = NotificationPermissionState.denied;
    final coordinator = ReminderCoordinator(
      reminderRepository: repository,
      documentRepository: MemoryDocumentRepository(const []),
      maintenanceRepository: MemoryMaintenanceRepository(const []),
      notificationService: notifications,
    );

    await coordinator.saveSettings(
      const ReminderSettings(enabled: true, advanceDays: [14, 0]),
    );
    final granted = await coordinator.requestPermission();

    expect(granted, isTrue);
    expect((await coordinator.loadSettings()).advanceDays, [14, 0]);
  });

  test('reconciliation is idempotent', () async {
    final repository = MemoryReminderRepository();
    final notifications = FakeLocalNotificationService();
    final coordinator = ReminderCoordinator(
      reminderRepository: repository,
      documentRepository: MemoryDocumentRepository([
        _document(DateTime(2026, 8, 31)),
      ]),
      maintenanceRepository: MemoryMaintenanceRepository(const []),
      notificationService: notifications,
    );

    await coordinator.reconcile(now: DateTime(2026, 7, 1));
    await coordinator.reconcile(now: DateTime(2026, 7, 1));

    expect(repository.reminders.map((item) => item.id).toSet(), hasLength(4));
    expect(
        notifications.scheduled.map((item) => item.id).toSet(), hasLength(4));
  });

  test('parses notification payload safely', () {
    final payload = const ReminderPayload(
      sourceType: ReminderSourceType.document,
      sourceId: '42',
    ).encode();

    final parsed = ReminderPayload.tryParse(payload);

    expect(parsed?.sourceType, ReminderSourceType.document);
    expect(parsed?.sourceId, '42');
    expect(ReminderPayload.tryParse('{bad json'), isNull);
  });

  testWidgets('notification settings screen updates reminders', (tester) async {
    final repository = MemoryReminderRepository();
    final coordinator = ReminderCoordinator(
      reminderRepository: repository,
      documentRepository: MemoryDocumentRepository(const []),
      maintenanceRepository: MemoryMaintenanceRepository(const []),
      notificationService: FakeLocalNotificationService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(coordinator: coordinator),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('notification_settings_title'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '14, 3, 0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.settings.advanceDays, [14, 3, 0]);
  });
}

VehicleDocument _document(DateTime expiryDate) {
  return VehicleDocument(
    id: 42,
    category: 'document_category_insurance',
    title: 'Insurance',
    localFilePath: '/private/insurance.pdf',
    mimeType: 'application/pdf',
    ocrStatus: DocumentOcrStatus.notRequested,
    expiryDate: expiryDate,
  );
}
