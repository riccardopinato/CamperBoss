import 'package:flutter/material.dart';

import '../../../core/services/weather_service.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/weather_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    this.weatherService = const WeatherService(),
    super.key,
  });

  final WeatherService weatherService;

  @override
  Widget build(BuildContext context) {
    final featuredPlace = MockCamperRepository.places[0];

    return ScreenScaffold(
      title: 'Camper cockpit',
      subtitle: 'Today looks good for the road. Two checks need attention.',
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Boss Score',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '82',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready to depart after fridge mode and tire pressure checks.',
              ),
              const SizedBox(height: 16),
              const ResourceBar(
                label: 'Trip readiness',
                value: 0.82,
                detail: '5 of 7 critical checks completed',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            MetricTile(
              icon: Icons.water_drop_outlined,
              label: 'Fresh water',
              value: '86 L',
              detail: 'Approx. 2.5 days left',
            ),
            MetricTile(
              icon: Icons.battery_charging_full_outlined,
              label: 'Battery',
              value: '74%',
              detail: 'Solar charging active',
            ),
            MetricTile(
              icon: Icons.propane_tank_outlined,
              label: 'Gas',
              value: '11 kg',
              detail: 'Heating safe tonight',
            ),
            MetricTile(
              icon: Icons.scale_outlined,
              label: 'Payload',
              value: '+180 kg',
              detail: 'Within 3.5t limit',
            ),
          ],
        ),
        const SizedBox(height: 24),
        SelectedLocationWeatherCard(service: weatherService),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Today'),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.warning_amber_outlined,
          title: 'Two departure checks open',
          subtitle: 'Fridge travel mode and tire pressure',
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.route_outlined,
          title: 'Dolomites route is 55% ready',
          subtitle: 'Fuel stop selected, overnight backup missing',
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recommended stop', action: 'View map'),
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
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 36),
              const SizedBox(height: 12),
              Text(
                'Pro route intelligence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock offline maps, payload-aware filters, weather risk alerts, and unlimited trip history.',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: PrimaryButton(
                  label: 'Preview Pro',
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
