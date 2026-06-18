import '../../data/models/app_reminder.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/maintenance_record.dart';
import '../../data/models/vehicle_document.dart';

class ReminderFactory {
  ReminderFactory({
    this.defaultHour = 9,
    this.iosLimit = 50,
  });

  final int defaultHour;
  final int iosLimit;

  List<AppReminder> forDocument(
    VehicleDocument document, {
    ReminderSettings settings = const ReminderSettings(),
    DateTime? now,
  }) {
    final id = document.id;
    final expiry = document.expiryDate;
    if (id == null || expiry == null || !settings.enabled) return const [];
    return _build(
      sourceType: ReminderSourceType.document,
      sourceId: id.toString(),
      title: document.title,
      body: 'Document expires on ${_dateLabel(expiry)}',
      dueDate: expiry,
      settings: settings,
      now: now,
    );
  }

  List<AppReminder> forMaintenance(
    MaintenanceRecord record, {
    ReminderSettings settings = const ReminderSettings(),
    DateTime? now,
  }) {
    final id = record.id;
    final dueDate = record.nextDueDate;
    if (id == null || dueDate == null || !settings.enabled) return const [];
    return _build(
      sourceType: ReminderSourceType.maintenance,
      sourceId: id.toString(),
      title: record.title,
      body: 'Maintenance due on ${_dateLabel(dueDate)}',
      dueDate: dueDate,
      settings: settings,
      now: now,
    );
  }

  List<AppReminder> forBooking(
    TripBooking booking, {
    ReminderSettings settings = const ReminderSettings(),
    DateTime? now,
  }) {
    final dueDate = booking.startsAt;
    if (booking.status == BookingStatus.canceled ||
        dueDate == null ||
        !settings.enabled) {
      return const [];
    }
    return _build(
      sourceType: ReminderSourceType.booking,
      sourceId: booking.id,
      title: booking.title,
      body: 'Booking starts on ${_dateLabel(dueDate)}',
      dueDate: dueDate,
      settings: settings,
      now: now,
    );
  }

  List<AppReminder> limitForIos(List<AppReminder> reminders) {
    final sorted = [...reminders]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return sorted.take(iosLimit).toList();
  }

  List<AppReminder> _build({
    required ReminderSourceType sourceType,
    required String sourceId,
    required String title,
    required String body,
    required DateTime dueDate,
    required ReminderSettings settings,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final days = [...settings.advanceDays]..sort((a, b) => b.compareTo(a));
    final reminders = <AppReminder>[];

    for (final advanceDay in days) {
      final scheduledDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - advanceDay,
        defaultHour,
      );
      if (!scheduledDate.isAfter(reference)) continue;
      final reminderId = '${sourceType.storageValue}:$sourceId:$advanceDay';
      reminders.add(
        AppReminder(
          id: reminderId,
          sourceType: sourceType,
          sourceId: sourceId,
          title: title,
          body: advanceDay == 0 ? body : '$body ($advanceDay days before)',
          scheduledAt: scheduledDate,
        ),
      );
    }

    return reminders;
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
