import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final places = MockCamperRepository.places.skip(1);
    const lakeGarda = LatLng(45.6049, 10.6351);

    return ScreenScaffold(
      title: 'Smart map',
      subtitle: 'Camper-friendly stops, service points, and route risks.',
      children: [
        PremiumCard(
          child: AspectRatio(
            aspectRatio: 1.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: lakeGarda,
                  initialZoom: 10.2,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.camperboss.camperboss',
                  ),
                  MarkerLayer(
                    markers: const [
                      Marker(
                        point: lakeGarda,
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.navigation,
                          color: AppColors.gold,
                          size: 42,
                        ),
                      ),
                      Marker(
                        point: LatLng(45.621, 10.57),
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.rv_hookup,
                          color: AppColors.moss,
                          size: 38,
                        ),
                      ),
                      Marker(
                        point: LatLng(45.55, 10.72),
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.water_drop,
                          color: AppColors.gold,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Live map tiles from OpenStreetMap. Offline cache and premium tile providers can be layered later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search lake, city, service point...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const ResourceBar(
                label: 'Offline cache: North Italy',
                value: 0.64,
                detail: '1,284 places ready without connection',
              ),
            ],
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
            FilterChip(
              label: Text('No height limit'),
              selected: true,
              onSelected: null,
            ),
            FilterChip(label: Text('Pets'), selected: true, onSelected: null),
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
