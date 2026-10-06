import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_system_services.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../offline/presentation/offline_content_screen.dart';
import 'backup_tools_screen.dart';
import '../../onboarding/presentation/guided_onboarding_screen.dart';
import '../../search/presentation/local_search_screen.dart';
import '../../settings/presentation/language_settings_screen.dart';
import '../../settings/presentation/notification_settings_screen.dart';

class MoreHubScreen extends StatelessWidget {
  MoreHubScreen({
    ReminderCoordinator? reminderCoordinator,
    super.key,
  }) : _reminderCoordinator =
            reminderCoordinator ?? AppSystemServices.instance.reminders;

  final ReminderCoordinator _reminderCoordinator;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'more_title'.tr(),
      subtitle: 'more_subtitle'.tr(),
      children: [
        ActionTile(
          icon: Icons.manage_search_outlined,
          title: 'search_title'.tr(),
          subtitle: 'more_search_body'.tr(),
          onTap: () => _open(context, const LocalSearchScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.cloud_download_outlined,
          title: 'more_offline'.tr(),
          subtitle: 'more_offline_body'.tr(),
          onTap: () => _open(context, const OfflineContentScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.backup_outlined,
          title: 'backup_title'.tr(),
          subtitle: 'backup_subtitle'.tr(),
          onTap: () => _open(context, const BackupToolsScreen()),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'more_title'.tr()),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_outlined),
                title: Text('more_language'.tr()),
                subtitle: Text('more_language_body'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const LanguageSettingsScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: Text('more_notifications'.tr()),
                subtitle: Text('more_notifications_body'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  NotificationSettingsScreen(
                    coordinator: _reminderCoordinator,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.rocket_launch_outlined),
                title: Text('more_setup'.tr()),
                subtitle: Text('more_setup_body'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const GuidedOnboardingScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
