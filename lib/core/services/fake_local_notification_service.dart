import '../../data/models/app_reminder.dart';
import 'local_notification_service.dart';

class FakeLocalNotificationService implements LocalNotificationService {
  NotificationPermissionState permissionState =
      NotificationPermissionState.granted;
  NotificationTimezoneState timezoneState = NotificationTimezoneState.local;
  final scheduled = <AppReminder>[];
  final canceledIds = <String>[];
  int testNotifications = 0;
  String? launchPayload;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionState> getPermissionState() async {
    return permissionState;
  }

  @override
  Future<NotificationTimezoneState> getTimezoneState() async {
    return timezoneState;
  }

  @override
  Future<bool> requestPermission() async {
    permissionState = NotificationPermissionState.granted;
    return true;
  }

  @override
  Future<void> scheduleReminder(AppReminder reminder) async {
    scheduled.removeWhere((item) => item.id == reminder.id);
    scheduled.add(reminder);
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    canceledIds.add(reminderId);
    scheduled.removeWhere((item) => item.id == reminderId);
  }

  @override
  Future<void> rescheduleAll(List<AppReminder> reminders) async {
    scheduled
      ..clear()
      ..addAll(reminders);
  }

  @override
  Future<void> showTestNotification() async {
    testNotifications += 1;
  }

  @override
  String? consumeLaunchPayload() {
    final payload = launchPayload;
    launchPayload = null;
    return payload;
  }
}
