import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/weather_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredPlace = MockCamperRepository.places[0];

    return ScreenScaffold(
      title: 'Ready for the next stop?',
      subtitle: 'Plan, check, drive, and remember the trip.',
      children: [
        const WeatherSummaryCard(),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.route_outlined,
          title: 'Plan a weekend route',
          subtitle: 'Fuel, stages, costs, and overnight stops',
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.check_circle_outline,
          title: 'Pre-trip checklist',
          subtitle: 'Water, gas, lights, fridge, documents',
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Nearby places', action: 'View map'),
        const SizedBox(height: 12),
        PlaceCard(
          name: featuredPlace.name,
          type: featuredPlace.type,
          distance: featuredPlace.distance,
          rating: featuredPlace.rating,
          tags: featuredPlace.tags,
        ),
        const SizedBox(height: 24),
        PremiumCard(
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 36),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Unlock offline maps, premium filters, and unlimited trip history.',
                ),
              ),
              PrimaryButton(
                label: 'Upgrade',
                icon: Icons.workspace_premium_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
