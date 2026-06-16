import '../../data/models/app_reminder.dart';

enum NotificationPermissionState {
  granted,
  denied,
  unavailable,
}

abstract interface class LocalNotificationService {
  Future<void> initialize();
  Future<NotificationPermissionState> getPermissionState();
  Future<bool> requestPermission();
  Future<void> scheduleReminder(AppReminder reminder);
  Future<void> cancelReminder(String reminderId);
  Future<void> rescheduleAll(List<AppReminder> reminders);
  Future<void> showTestNotification();
  String? consumeLaunchPayload();
}

LocalNotificationService createLocalNotificationService() {
  return UnsupportedLocalNotificationService();
}

class UnsupportedLocalNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionState> getPermissionState() async {
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleReminder(AppReminder reminder) async {}

  @override
  Future<void> cancelReminder(String reminderId) async {}

  @override
  Future<void> rescheduleAll(List<AppReminder> reminders) async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  String? consumeLaunchPayload() => null;
}
