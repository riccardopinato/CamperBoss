import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/state/selected_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geocodingService = const GeocodingService();
  final _locationService = const LocationService();
  Timer? _debounce;
  List<GeoLocationResult> _results = const [];
  bool _isSearching = false;
  bool _isLocating = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final trimmed = query.trim();
      if (trimmed.length < 3) {
        if (mounted) {
          setState(() {
            _results = const [];
            _error = null;
            _isSearching = false;
          });
        }
        return;
      }

      setState(() {
        _isSearching = true;
        _error = null;
      });

      try {
        final results = await _geocodingService.search(trimmed);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isSearching = false;
          _error = results.isEmpty ? 'No locations found' : null;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _error = 'Location search unavailable';
        });
      }
    });
  }

  void _selectLocation(GeoLocationResult location) {
    selectedLocationController.value = location;
    _mapController.move(LatLng(location.latitude, location.longitude), 11.5);
    _searchController.text = location.name;
    setState(() => _results = const []);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _error = null;
    });

    try {
      final location = await _locationService.currentLocation();
      if (!mounted) return;
      _selectLocation(location);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = MockCamperRepository.places.skip(1);

    return ValueListenableBuilder<GeoLocationResult>(
      valueListenable: selectedLocationController,
      builder: (context, selectedLocation, _) {
        final selectedPoint = LatLng(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );

        return ScreenScaffold(
          title: 'Smart map',
          subtitle: 'Search a city, select it, then weather and map react.',
          children: [
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _results = const [];
                                  _error = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      hintText: 'Search a city or postal code...',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isLocating ? 'Locating...' : 'Use my location',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final result in _results)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(result.name),
                        subtitle: Text(result.label),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _selectLocation(result),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(selectedLocation.label),
                  const SizedBox(height: 14),
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selectedPoint,
                          initialZoom: 10.2,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.camperboss.camperboss',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedPoint,
                                width: 48,
                                height: 48,
                                child: const Icon(
                                  Icons.navigation,
                                  color: AppColors.gold,
                                  size: 42,
                                ),
                              ),
                              const Marker(
                                point: LatLng(45.621, 10.57),
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.rv_hookup,
                                  color: AppColors.moss,
                                  size: 38,
                                ),
                              ),
                              const Marker(
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Live map tiles from OpenStreetMap. Location search uses Open-Meteo Geocoding.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            const PremiumCard(
              child: ResourceBar(
                label: 'Offline cache: North Italy',
                value: 0.64,
                detail: '1,284 places ready without connection',
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Filters'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                FilterChip(
                    label: Text('Water'), selected: true, onSelected: null),
                FilterChip(
                    label: Text('Dump'), selected: false, onSelected: null),
                FilterChip(
                    label: Text('24h'), selected: true, onSelected: null),
                FilterChip(
                    label: Text('Wi-Fi'), selected: false, onSelected: null),
                FilterChip(
                  label: Text('No height limit'),
                  selected: true,
                  onSelected: null,
                ),
                FilterChip(
                    label: Text('Pets'), selected: true, onSelected: null),
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
      },
    );
  }
}
