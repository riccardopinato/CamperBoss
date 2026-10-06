import 'package:easy_localization/easy_localization.dart';
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
        _error = 'home_error_unavailable'.tr();
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
        title: 'home_cockpit_title'.tr(),
        subtitle: 'home_cockpit_subtitle'.tr(),
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
            if (_isFirstRun(snapshot)) ...[
              _FirstRunCard(
                onStart: () => _push(const GuidedOnboardingScreen()),
              ),
              const SizedBox(height: 16),
              ActionTile(
                icon: Icons.menu_book_outlined,
                title: 'home_offline_guides'.tr(),
                subtitle: 'home_offline_guides_body'.tr(),
                onTap: () => _push(const OfflineGuidesScreen()),
              ),
            ] else ...[
              _ReadinessCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _MetricsGrid(snapshot: snapshot),
              const SizedBox(height: 24),
              SelectedLocationWeatherCard(service: widget.weatherService),
              const SizedBox(height: 24),
              SectionHeader(title: 'home_needs_attention'.tr()),
              const SizedBox(height: 12),
              if (snapshot.actions.isEmpty)
                PremiumCard(
                  child: Text('home_no_urgent'.tr()),
                )
              else
                for (final action in snapshot.actions) ...[
                  ActionTile(
                    icon: _iconFor(action.type),
                    title: action.titleKey.tr(namedArgs: action.args),
                    subtitle: action.detailKey.tr(namedArgs: action.args),
                    onTap: () => _openAction(action),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.rocket_launch_outlined,
                title: 'home_guided_setup'.tr(),
                subtitle: 'home_guided_setup_body'.tr(),
                onTap: () => _push(const GuidedOnboardingScreen()),
              ),
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.menu_book_outlined,
                title: 'home_offline_guides'.tr(),
                subtitle: 'home_offline_guides_body'.tr(),
                onTap: () => _push(const OfflineGuidesScreen()),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _isFirstRun(HomeCockpitSnapshot snapshot) {
    return snapshot.vehicle == null &&
        snapshot.checklistTotal == 0 &&
        snapshot.documentCount == 0 &&
        snapshot.maintenanceCount == 0;
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

class _FirstRunCard extends StatelessWidget {
  const _FirstRunCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'home_guided_setup'.tr(),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'home_guided_setup'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text('home_guided_setup_body'.tr()),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.arrow_forward),
              label: Text('home_guided_setup'.tr()),
            ),
          ],
        ),
      ),
    );
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
                  'home_boss_readiness'.tr(),
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
                ? 'home_readiness_not_enough'.tr()
                : _scoreLabel(score),
          ),
          const SizedBox(height: 16),
          ResourceBar(
            label: 'home_data_coverage'.tr(),
            value: coverage / 100,
            detail: 'home_data_coverage_detail'.tr(namedArgs: {'coverage': coverage.toString()}),
          ),
          if (score != null) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'home_readiness'.tr(),
              value: score / 100,
              detail: 'home_readiness_detail'.tr(),
            ),
          ],
        ],
      ),
    );
  }

  static String _scoreLabel(int score) {
    if (score >= 90) return 'home_readiness_score_90'.tr();
    if (score >= 70) return 'home_readiness_score_70'.tr();
    if (score >= 50) return 'home_readiness_score_50'.tr();
    return 'home_readiness_score_low'.tr();
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

    return GridView.extent(
      maxCrossAxisExtent: 260,
      childAspectRatio: 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricTile(
          icon: Icons.speed_outlined,
          label: 'home_mileage'.tr(),
          value: vehicle == null ? '--' : '${vehicle.mileage.round()} km',
          detail: vehicle == null
              ? 'home_vehicle_not_configured'.tr()
              : '${vehicle.brand} ${vehicle.model}',
        ),
        MetricTile(
          icon: Icons.checklist_outlined,
          label: 'home_checklist'.tr(),
          value: snapshot.checklistTotal == 0 ? '--' : 'home_open_count'.tr(namedArgs: {'count': openChecks.toString()}),
          detail: snapshot.checklistTotal == 0
              ? 'home_checklist_empty'.tr()
              : 'home_checklist_complete'.tr(namedArgs: {'completed': snapshot.checklistCompleted.toString(), 'total': snapshot.checklistTotal.toString()}),
        ),
        MetricTile(
          icon: Icons.folder_copy_outlined,
          label: 'home_documents'.tr(),
          value: snapshot.documentCount == 0 ? '--' : 'home_alert_count'.tr(namedArgs: {'count': documentAlerts.toString()}),
          detail: snapshot.documentCount == 0
              ? 'home_documents_empty'.tr()
              : 'home_documents_stored'.tr(namedArgs: {'count': snapshot.documentCount.toString()}),
        ),
        MetricTile(
          icon: Icons.build_circle_outlined,
          label: 'home_maintenance'.tr(),
          value:
              snapshot.maintenanceCount == 0 ? '--' : 'home_alert_count'.tr(namedArgs: {'count': maintenanceAlerts.toString()}),
          detail: snapshot.maintenanceCount == 0
              ? 'home_maintenance_empty'.tr()
              : 'home_maintenance_records'.tr(namedArgs: {'count': snapshot.maintenanceCount.toString()}),
        ),
      ],
    );
  }
}
