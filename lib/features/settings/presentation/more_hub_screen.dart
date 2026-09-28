import 'package:flutter/material.dart';

import '../../../core/services/reminder_coordinator.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../offline/presentation/offline_content_screen.dart';
import '../../offline/presentation/offline_guides_screen.dart';
import '../../onboarding/presentation/guided_onboarding_screen.dart';
import '../../search/presentation/local_search_screen.dart';
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
      title: 'More',
      subtitle: 'Search, offline content, reminders and setup.',
      children: [
        ActionTile(
          icon: Icons.manage_search_outlined,
          title: 'Search',
          subtitle: 'Search your local CamperBoss data without cloud upload.',
          onTap: () => _open(context, const LocalSearchScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.cloud_download_outlined,
          title: 'Offline content',
          subtitle: 'Manage downloaded resources and storage.',
          onTap: () => _open(context, const OfflineContentScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.menu_book_outlined,
          title: 'Offline guides',
          subtitle: 'Read installed guides without a connection.',
          onTap: () => _open(context, const OfflineGuidesScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Reminder permission, timing and local test controls.',
          onTap: () => _open(
            context,
            NotificationSettingsScreen(coordinator: _reminderCoordinator),
          ),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.rocket_launch_outlined,
          title: 'Guided setup',
          subtitle: 'Resume configuration without creating demo content.',
          onTap: () => _open(context, const GuidedOnboardingScreen()),
        ),
      ],
    );
  }
}
