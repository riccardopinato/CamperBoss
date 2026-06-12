import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/trip_card.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTrip = MockCamperRepository.trips[0];

    return ScreenScaffold(
      title: 'Trip planner',
      subtitle: 'Build routes with stages, costs, and stop checks.',
      children: [
        TripCard(
          title: activeTrip.title,
          summary: activeTrip.summary,
          progress: activeTrip.progress,
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
      ],
    );
  }
}
