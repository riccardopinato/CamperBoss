import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const entries = MockCamperRepository.journal;

    return ScreenScaffold(
      title: 'Travel journal',
      subtitle: 'Keep notes, memories, mileage, and favorite stops.',
      children: [
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.95,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            MetricTile(
              icon: Icons.route_outlined,
              label: 'Km',
              value: '412',
              detail: 'This trip',
            ),
            MetricTile(
              icon: Icons.euro_outlined,
              label: 'Spend',
              value: '148',
              detail: 'Tracked',
            ),
            MetricTile(
              icon: Icons.favorite_border,
              label: 'Stops',
              value: '6',
              detail: 'Saved',
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final entry in entries) ...[
          PremiumCard(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  child: const Icon(Icons.photo_camera_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.summary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Memory prompt',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add one photo and one practical note for tonight. Future you will thank you before repeating the route.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
