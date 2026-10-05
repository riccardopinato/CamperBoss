import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_system_services.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../data/models/app_reminder.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    this.coordinator,
    super.key,
  });

  final ReminderCoordinator? coordinator;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final ReminderCoordinator _coordinator =
      widget.coordinator ?? AppSystemServices.instance.reminders;

  ReminderSettings _settings = const ReminderSettings();
  NotificationPermissionState _permission =
      NotificationPermissionState.unavailable;
  NotificationTimezoneState _timezoneState =
      NotificationTimezoneState.unavailable;
  bool _isLoading = true;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await _coordinator.loadSettings();
      final permission = await _coordinator.permissionState();
      final timezoneState = await _coordinator.timezoneState();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _permission = permission;
        _timezoneState = timezoneState;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'notification_load_failed'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      var effectiveEnabled = enabled;
      if (enabled) {
        final granted = await _coordinator.requestPermission();
        _permission = granted
            ? NotificationPermissionState.granted
            : NotificationPermissionState.denied;
        effectiveEnabled = granted;
      }
      final settings = _settings.copyWith(enabled: effectiveEnabled);
      await _coordinator.saveSettings(settings);
      if (!mounted) return;
      setState(() => _settings = settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'notification_save_failed'.tr());
      await _load();
    }
  }

  Future<void> _saveDays(String value) async {
    final days = value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .where((day) => day >= 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return;
    final settings = _settings.copyWith(advanceDays: days);
    await _coordinator.saveSettings(settings);
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _sendTest() async {
    if (_permission != NotificationPermissionState.granted) {
      setState(() => _error = 'notification_test_permission_required'.tr());
      return;
    }
    try {
      await _coordinator.showTestNotification();
      if (!mounted) return;
      setState(() {
        _error = null;
        _status = 'notification_test_sent'.tr();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'notification_test_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ScreenScaffold(
      title: 'notification_settings_title'.tr(),
      subtitle: 'notification_settings_subtitle'.tr(),
      children: [
        if (_error != null) ...[
          PremiumCard(
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!)),
                IconButton(
                  tooltip: 'retry'.tr(),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionHeader(title: 'notification_local_reminders'.tr()),
        const SizedBox(height: 12),
        PremiumCard(
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: _settings.enabled,
                  contentPadding: EdgeInsets.zero,
                  title: Text('notification_enable'.tr()),
                  subtitle: Text(_permissionLabel()),
                  onChanged: _setEnabled,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _settings.advanceDays.join(', '),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'notification_advance_days'.tr(),
                    helperText: 'notification_advance_days_help'.tr(),
                  ),
                  onFieldSubmitted: _saveDays,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text('notification_refresh_permission'.tr()),
                    ),
                    FilledButton.icon(
                      onPressed: _settings.enabled &&
                              _permission == NotificationPermissionState.granted
                          ? _sendTest
                          : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text('notification_test'.tr()),
                    ),
                  ],
                ),
                if (_permission == NotificationPermissionState.denied) ...[
                  const SizedBox(height: 12),
                  Text('notification_permission_denied_help'.tr()),
                ],
                if (_timezoneState ==
                    NotificationTimezoneState.utcFallback) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('notification_timezone_utc_fallback'.tr()),
                      ),
                    ],
                  ),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _permissionLabel() {
    return switch (_permission) {
      NotificationPermissionState.granted =>
        'notification_permission_granted'.tr(),
      NotificationPermissionState.denied =>
        'notification_permission_denied'.tr(),
      NotificationPermissionState.unavailable =>
        'notification_permission_unavailable'.tr(),
    };
  }
}
