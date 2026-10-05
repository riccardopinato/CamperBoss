import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/app_reminder.dart';
import 'local_notification_service_stub.dart';

export 'local_notification_service_stub.dart'
    show
        LocalNotificationService,
        NotificationPermissionState,
        NotificationTimezoneState;

LocalNotificationService createLocalNotificationService() {
  return FlutterLocalNotificationService();
}

class FlutterLocalNotificationService implements LocalNotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _deadlineChannelId = 'camperboss_deadlines';
  static const _maintenanceChannelId = 'camperboss_maintenance';
  static const _deadlineChannelName = 'Deadline reminders';
  static const _maintenanceChannelName = 'Maintenance reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  String? _launchPayload;
  bool _initialized = false;
  NotificationTimezoneState _timezoneState =
      NotificationTimezoneState.unavailable;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _setLocalTimezone();

    const android = AndroidInitializationSettings('app_notification');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    _launchPayload = launchDetails?.notificationResponse?.payload;

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        _launchPayload = response.payload;
      },
    );

    _initialized = true;
  }

  @override
  Future<NotificationPermissionState> getPermissionState() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissions = await ios?.checkPermissions();
      if (permissions == null) {
        return NotificationPermissionState.unavailable;
      }
      return permissions.isEnabled
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<NotificationTimezoneState> getTimezoneState() async {
    await initialize();
    return _timezoneState;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleReminder(AppReminder reminder) async {
    await initialize();
    if (!reminder.enabled || !reminder.scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      notificationDetails: _detailsFor(reminder.sourceType),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.payload,
    );
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    await initialize();
    await _plugin.cancel(id: stableNotificationId(reminderId));
  }

  @override
  Future<void> rescheduleAll(List<AppReminder> reminders) async {
    await initialize();
    await _plugin.cancelAll();
    final limited = Platform.isIOS ? reminders.take(50) : reminders;
    for (final reminder in limited) {
      await scheduleReminder(reminder);
    }
  }

  @override
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: stableNotificationId('test-local-reminder'),
      title: 'CamperBoss',
      body: 'Local reminders are ready.',
      notificationDetails: _detailsFor(ReminderSourceType.custom),
      payload: const ReminderPayload(
        sourceType: ReminderSourceType.custom,
        sourceId: 'test',
      ).encode(),
    );
  }

  @override
  String? consumeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  NotificationDetails _detailsFor(ReminderSourceType sourceType) {
    final isMaintenance = sourceType == ReminderSourceType.maintenance;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isMaintenance ? _maintenanceChannelId : _deadlineChannelId,
        isMaintenance ? _maintenanceChannelName : _deadlineChannelName,
        channelDescription: isMaintenance
            ? 'Local maintenance due reminders'
            : 'Local document expiry reminders',
        icon: 'app_notification',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _setLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      _timezoneState = NotificationTimezoneState.local;
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      _timezoneState = NotificationTimezoneState.utcFallback;
    }
  }
}
