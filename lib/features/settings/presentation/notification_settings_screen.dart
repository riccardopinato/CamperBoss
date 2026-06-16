import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
      widget.coordinator ?? ReminderCoordinator();

  ReminderSettings _settings = const ReminderSettings();
  NotificationPermissionState _permission =
      NotificationPermissionState.unavailable;
  bool _isLoading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _coordinator.loadSettings();
    final permission = await _coordinator.permissionState();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permission = permission;
      _isLoading = false;
    });
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() => _settings = _settings.copyWith(enabled: enabled));
    if (enabled) {
      final granted = await _coordinator.requestPermission();
      _permission = granted
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    await _coordinator.saveSettings(_settings);
    if (mounted) setState(() {});
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
    await _coordinator.showTestNotification();
    if (!mounted) return;
    setState(() => _status = 'notification_test_sent'.tr());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ScreenScaffold(
      title: 'notification_settings_title'.tr(),
      subtitle: 'notification_settings_subtitle'.tr(),
      children: [
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
                      onPressed: _settings.enabled ? _sendTest : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text('notification_test'.tr()),
                    ),
                  ],
                ),
                if (_permission == NotificationPermissionState.denied) ...[
                  const SizedBox(height: 12),
                  Text('notification_permission_denied_help'.tr()),
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
