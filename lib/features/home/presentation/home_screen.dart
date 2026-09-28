import 'package:flutter/material.dart';

import '../../../core/services/home_cockpit_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/weather_summary_card.dart';
import '../../checklist/presentation/checklist_screen.dart';
import '../../documents/presentation/vehicle_documents_screen.dart';
import '../../maintenance/presentation/maintenance_screen.dart';
import '../../offline/presentation/offline_guides_screen.dart';
import '../../onboarding/presentation/guided_onboarding_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../trip/presentation/trip_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.weatherService = const WeatherService(),
    this.cockpitService,
    super.key,
  });

  final WeatherService weatherService;
  final HomeCockpitService? cockpitService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCockpitService _cockpitService =
      widget.cockpitService ?? HomeCockpitService();

  HomeCockpitSnapshot? _snapshot;
  bool _isLoading = true;
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
      final snapshot = await _cockpitService.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Cockpit data unavailable';
      });
    }
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openAction(HomeCockpitAction action) async {
    final page = switch (action.type) {
      HomeCockpitActionType.vehicle => const ProfileScreen(),
      HomeCockpitActionType.checklist => const ChecklistScreen(),
      HomeCockpitActionType.documents => const VehicleDocumentsScreen(),
      HomeCockpitActionType.maintenance => const MaintenanceScreen(),
      HomeCockpitActionType.trip => const TripPlannerScreen(),
    };
    await _push(page);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return RefreshIndicator(
      onRefresh: _load,
      child: ScreenScaffold(
        title: 'Camper cockpit',
        subtitle: 'Only real local data contributes to your readiness.',
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot != null) ...[
            _ReadinessCard(snapshot: snapshot),
            const SizedBox(height: 16),
            _MetricsGrid(snapshot: snapshot),
            const SizedBox(height: 24),
            SelectedLocationWeatherCard(service: widget.weatherService),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Needs attention'),
            const SizedBox(height: 12),
            if (snapshot.actions.isEmpty)
              const PremiumCard(
                child: Text(
                  'No urgent local items are currently flagged. Pull to refresh after editing your data.',
                ),
              )
            else
              for (final action in snapshot.actions) ...[
                ActionTile(
                  icon: _iconFor(action.type),
                  title: action.title,
                  subtitle: action.detail,
                  onTap: () => _openAction(action),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.rocket_launch_outlined,
              title: 'Guided setup',
              subtitle:
                  'Configure permissions, vehicle basics and starter offline content.',
              onTap: () => _push(const GuidedOnboardingScreen()),
            ),
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.menu_book_outlined,
              title: 'Offline guides',
              subtitle: 'Open installed guides without relying on connectivity.',
              onTap: () => _push(const OfflineGuidesScreen()),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(HomeCockpitActionType type) {
    return switch (type) {
      HomeCockpitActionType.vehicle => Icons.directions_bus_outlined,
      HomeCockpitActionType.checklist => Icons.checklist_outlined,
      HomeCockpitActionType.documents => Icons.folder_copy_outlined,
      HomeCockpitActionType.maintenance => Icons.build_circle_outlined,
      HomeCockpitActionType.trip => Icons.route_outlined,
    };
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.snapshot});

  final HomeCockpitSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final score = snapshot.readinessScore;
    final coverage = snapshot.readinessCoverage;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Boss Readiness',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                score == null ? '--' : '$score',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score == null
                ? 'Add enough real data before CamperBoss calculates a readiness score.'
                : _scoreLabel(score),
          ),
          const SizedBox(height: 16),
          ResourceBar(
            label: 'Data coverage',
            value: coverage / 100,
            detail: '$coverage% of readiness signals are configured',
          ),
          if (score != null) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'Readiness',
              value: score / 100,
              detail: 'Calculated only from configured local signals',
            ),
          ],
        ],
      ),
    );
  }

  static String _scoreLabel(int score) {
    if (score >= 90) return 'No major readiness issue is currently detected.';
    if (score >= 70) return 'Mostly ready, with a few items still worth checking.';
    if (score >= 50) return 'Several checks should be reviewed before departure.';
    return 'Important readiness items need attention.';
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.snapshot});

  final HomeCockpitSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final vehicle = snapshot.vehicle;
    final openChecks = snapshot.checklistOpen;
    final documentAlerts =
        snapshot.expiredDocuments + snapshot.documentsDueSoon;
    final maintenanceAlerts =
        snapshot.overdueMaintenance + snapshot.maintenanceDueSoon;

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricTile(
          icon: Icons.speed_outlined,
          label: 'Mileage',
          value: vehicle == null ? '--' : '${vehicle.mileage.round()} km',
          detail: vehicle == null
              ? 'Vehicle not configured'
              : '${vehicle.brand} ${vehicle.model}',
        ),
        MetricTile(
          icon: Icons.checklist_outlined,
          label: 'Checklist',
          value: snapshot.checklistTotal == 0 ? '--' : '$openChecks open',
          detail: snapshot.checklistTotal == 0
              ? 'No checklist created'
              : '${snapshot.checklistCompleted}/${snapshot.checklistTotal} complete',
        ),
        MetricTile(
          icon: Icons.folder_copy_outlined,
          label: 'Documents',
          value: snapshot.documentCount == 0 ? '--' : '$documentAlerts alerts',
          detail: snapshot.documentCount == 0
              ? 'No documents saved'
              : '${snapshot.documentCount} stored locally',
        ),
        MetricTile(
          icon: Icons.build_circle_outlined,
          label: 'Maintenance',
          value:
              snapshot.maintenanceCount == 0 ? '--' : '$maintenanceAlerts alerts',
          detail: snapshot.maintenanceCount == 0
              ? 'No service history'
              : '${snapshot.maintenanceCount} records',
        ),
      ],
    );
  }
}
