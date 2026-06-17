import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_reminder.dart';
import '../services/reminder_coordinator.dart';
import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/documents/presentation/vehicle_documents_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/offline/presentation/offline_content_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/notification_settings_screen.dart';
import '../../features/trip/presentation/trip_planner_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final ReminderCoordinator _reminderCoordinator = ReminderCoordinator();

  List<Widget> get _screens => [
        const HomeScreen(),
        const MapScreen(),
        const TripPlannerScreen(),
        const ChecklistScreen(),
        const JournalScreen(),
        const VehicleDocumentsScreen(),
        const MaintenanceScreen(),
        const OfflineContentScreen(),
        NotificationSettingsScreen(coordinator: _reminderCoordinator),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _initializeReminders();
  }

  Future<void> _initializeReminders() async {
    await _reminderCoordinator.initializeAndReconcile();
    final payload = _reminderCoordinator.consumeLaunchPayload();
    if (!mounted || payload == null) return;
    setState(() {
      _index = switch (payload.sourceType) {
        ReminderSourceType.document => 5,
        ReminderSourceType.maintenance => 6,
        ReminderSourceType.custom => 8,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'nav_home'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'nav_map'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'nav_trips'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'nav_lists'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'nav_journal'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Docs',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_download_outlined),
            selectedIcon: Icon(Icons.cloud_download),
            label: 'nav_offline'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'nav_notifications'.tr(),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'nav_profile'.tr(),
          ),
        ],
      ),
    );
  }
}
