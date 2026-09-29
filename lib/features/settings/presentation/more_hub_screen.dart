import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/reminder_coordinator.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../offline/presentation/offline_content_screen.dart';
import '../../offline/presentation/offline_guides_screen.dart';
import '../../onboarding/presentation/guided_onboarding_screen.dart';
import '../../search/presentation/local_search_screen.dart';
import '../../settings/presentation/language_settings_screen.dart';
import '../../settings/presentation/notification_settings_screen.dart';

class MoreHubScreen extends StatelessWidget {
  MoreHubScreen({
    ReminderCoordinator? reminderCoordinator,
    super.key,
  }) : _reminderCoordinator = reminderCoordinator ?? ReminderCoordinator();

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
          icon: Icons.menu_book_outlined,
          title: 'more_guides'.tr(),
          subtitle: 'more_guides_body'.tr(),
          onTap: () => _open(context, const OfflineGuidesScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.language_outlined,
          title: 'more_language'.tr(),
          subtitle: 'more_language_body'.tr(),
          onTap: () => _open(context, const LanguageSettingsScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.notifications_outlined,
          title: 'more_notifications'.tr(),
          subtitle: 'more_notifications_body'.tr(),
          onTap: () => _open(
            context,
            NotificationSettingsScreen(coordinator: _reminderCoordinator),
          ),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.rocket_launch_outlined,
          title: 'more_setup'.tr(),
          subtitle: 'more_setup_body'.tr(),
          onTap: () => _open(context, const GuidedOnboardingScreen()),
        ),
      ],
    );
  }
}
