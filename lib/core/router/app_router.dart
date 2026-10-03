import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_reminder.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/camper_hub_screen.dart';
import '../../features/settings/presentation/more_hub_screen.dart';
import '../../features/trip/presentation/trip_hub_screen.dart';
import '../services/app_system_services.dart';
import '../services/reminder_coordinator.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final ReminderCoordinator _reminderCoordinator =
      AppSystemServices.instance.reminders;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const TripHubScreen(),
    const CamperHubScreen(),
    MoreHubScreen(reminderCoordinator: _reminderCoordinator),
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
        ReminderSourceType.document => 3,
        ReminderSourceType.maintenance => 3,
        ReminderSourceType.booking => 2,
        ReminderSourceType.custom => 4,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: 'nav_home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: 'nav_map'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: 'nav_trips'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_outlined),
            selectedIcon: const Icon(Icons.directions_bus),
            label: 'nav_vehicle'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more),
            label: 'nav_more'.tr(),
          ),
        ],
      ),
    );
  }
}
