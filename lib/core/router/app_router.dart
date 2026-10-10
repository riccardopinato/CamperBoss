import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_reminder.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/camper_hub_screen.dart';
import '../../features/settings/presentation/more_hub_screen.dart';
import '../../features/trip/presentation/trip_hub_screen.dart';
import '../services/app_system_services.dart';
import '../services/reminder_coordinator.dart';

const camperBossTopLevelRoutes = <String>[
  '/',
  '/map',
  '/trips',
  '/camper',
  '/more',
];

Map<String, WidgetBuilder> camperBossRoutes() => {
      '/': (_) => const AppShell(initialIndex: 0),
      '/map': (_) => const AppShell(initialIndex: 1),
      '/trips': (_) => const AppShell(initialIndex: 2),
      '/camper': (_) => const AppShell(initialIndex: 3),
      '/more': (_) => const AppShell(initialIndex: 4),
    };

class AppShell extends StatefulWidget {
  const AppShell({
    this.initialIndex = 0,
    super.key,
  });

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex.clamp(0, 4);
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
    _applyReminderLaunchPayload();
  }

  void _applyReminderLaunchPayload() {
    // AppSystemServices.initialize() already initializes/reconciles reminders
    // before CamperBossApp is mounted and deliberately isolates plugin errors
    // from startup. Do not initialize the notification plugin a second time
    // from AppShell, otherwise a native/plugin packaging failure can escape as
    // an unhandled async exception and terminate runtime certification.
    final payload = _reminderCoordinator.consumeLaunchPayload();
    if (payload == null) return;

    _index = switch (payload.sourceType) {
      ReminderSourceType.document => 3,
      ReminderSourceType.maintenance => 3,
      ReminderSourceType.booking => 2,
      ReminderSourceType.custom => 4,
    };
  }

  void _selectDestination(int value) {
    if (value == _index) return;
    if (kIsWeb) {
      Navigator.of(context).pushNamed(camperBossTopLevelRoutes[value]);
      return;
    }
    setState(() => _index = value);
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
        onDestinationSelected: _selectDestination,
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
