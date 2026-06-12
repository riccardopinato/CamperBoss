import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final places = MockCamperRepository.places.skip(1);

    return ScreenScaffold(
      title: 'Smart map',
      subtitle: 'Mocked camper places before real map integration.',
      children: [
        PremiumCard(
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
                const Positioned(
                  left: 32,
                  top: 42,
                  child: Icon(Icons.location_on, size: 42),
                ),
                const Positioned(
                  right: 44,
                  bottom: 48,
                  child: Icon(Icons.rv_hookup, size: 40),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.navigation, size: 54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Filters'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            FilterChip(label: Text('Water'), selected: true, onSelected: null),
            FilterChip(label: Text('Dump'), selected: false, onSelected: null),
            FilterChip(label: Text('24h'), selected: true, onSelected: null),
            FilterChip(label: Text('Wi-Fi'), selected: false, onSelected: null),
          ],
        ),
        const SizedBox(height: 24),
        for (final place in places) ...[
          PlaceCard(
            name: place.name,
            type: place.type,
            distance: place.distance,
            rating: place.rating,
            tags: place.tags,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
