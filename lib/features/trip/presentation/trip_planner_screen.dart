import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/trip_card.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTrip = MockCamperRepository.trips[0];

    return ScreenScaffold(
      title: 'Trip planner',
      subtitle: 'Route, budget, autonomy, and risk planning in one place.',
      children: [
        TripCard(
          title: activeTrip.title,
          summary: activeTrip.summary,
          progress: activeTrip.progress,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            MetricTile(
              icon: Icons.local_gas_station_outlined,
              label: 'Fuel',
              value: 'EUR 86',
              detail: '2 planned stops',
            ),
            MetricTile(
              icon: Icons.toll_outlined,
              label: 'Tolls',
              value: 'EUR 24',
              detail: 'Avoidable via scenic route',
            ),
            MetricTile(
              icon: Icons.schedule_outlined,
              label: 'Drive time',
              value: '5h 40m',
              detail: 'Split across 3 stages',
            ),
            MetricTile(
              icon: Icons.height_outlined,
              label: 'Risk',
              value: 'Low',
              detail: 'No critical bridge alerts',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const PremiumCard(
          child: ResourceBar(
            label: 'Planner completion',
            value: 0.55,
            detail: 'Add backup overnight stop and weather checkpoint',
          ),
        ),
        const SizedBox(height: 16),
        const ActionTile(
          icon: Icons.flag_outlined,
          title: 'Stage 1: Verona to Molveno',
          subtitle: 'Check mountain roads and LPG before arrival',
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.night_shelter_outlined,
          title: 'Overnight: lake area',
          subtitle: 'Arrive before 19:00, reserve backup spot',
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.cloud_outlined,
          title: 'Weather checkpoint',
          subtitle: 'Wind gusts expected near mountain pass after 16:00',
        ),
      ],
    );
  }
}
