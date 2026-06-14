import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/state/selected_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/camper_place.dart';
import '../../../data/repositories/local_poi_cache_repository.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    this.places,
    this.cacheRepository,
    this.onOpenDirections,
    super.key,
  });

  final List<CamperPlace>? places;
  final PoiCacheRepository? cacheRepository;
  final Future<void> Function(CamperPlace place)? onOpenDirections;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _filterLabels = {
    'sosta': 'Sosta',
    'camping': 'Camping',
    'parcheggio': 'Parcheggio',
    'acqua': 'Acqua',
    'scarico': 'Scarico',
    'gpl': 'GPL',
    'assistenza': 'Assistenza',
  };

  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geocodingService = const GeocodingService();
  final _locationService = const LocationService();
  final _distance = const Distance();
  Timer? _debounce;
  List<GeoLocationResult> _results = const [];
  late final List<CamperPlace> _places =
      widget.places ?? MockCamperRepository.places;
  late final PoiCacheRepository _cacheRepository =
      widget.cacheRepository ?? LocalPoiCacheRepository();
  late final Set<String> _activeFilters = {..._filterLabels.keys};
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isRefreshingCache = false;
  bool _isClearingCache = false;
  String? _error;
  PoiCacheSnapshot? _cacheSnapshot;

  @override
  void initState() {
    super.initState();
    _loadCacheSnapshot();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheSnapshot() async {
    try {
      final snapshot = await _cacheRepository.loadSnapshot();
      if (!mounted) return;
      setState(() => _cacheSnapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'POI cache unavailable');
    }
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final trimmed = query.trim();
      if (trimmed.length < 3) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _error = null;
          _isSearching = false;
        });
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

  Future<void> _refreshCache() async {
    setState(() {
      _isRefreshingCache = true;
      _error = null;
    });

    try {
      final snapshot = await _cacheRepository.refresh(
        region: 'North Italy',
        places: _places,
      );
      if (!mounted) return;
      setState(() => _cacheSnapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'POI cache refresh failed');
    } finally {
      if (mounted) {
        setState(() => _isRefreshingCache = false);
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
      _error = null;
    });

    try {
      final snapshot = await _cacheRepository.clear();
      if (!mounted) return;
      setState(() => _cacheSnapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'POI cache clear failed');
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  Future<void> _openDirections(CamperPlace place) async {
    final handler = widget.onOpenDirections;
    if (handler != null) {
      await handler(place);
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() => _error = 'Directions unavailable');
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  List<CamperPlace> _filteredPlaces(LatLng selectedPoint) {
    final filtered = _places
        .where((place) => _activeFilters.contains(place.category))
        .toList();
    filtered.sort(
      (a, b) => _distanceKm(a, selectedPoint).compareTo(
        _distanceKm(b, selectedPoint),
      ),
    );
    return filtered;
  }

  double _distanceKm(CamperPlace place, LatLng selectedPoint) {
    return _distance.as(
      LengthUnit.Kilometer,
      selectedPoint,
      LatLng(place.latitude, place.longitude),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'camping':
        return Icons.cabin_outlined;
      case 'parcheggio':
        return Icons.local_parking_outlined;
      case 'acqua':
        return Icons.water_drop_outlined;
      case 'scarico':
        return Icons.delete_outline;
      case 'gpl':
        return Icons.local_gas_station_outlined;
      case 'assistenza':
        return Icons.build_outlined;
      case 'sosta':
      default:
        return Icons.rv_hookup;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'camping':
        return AppColors.forest;
      case 'parcheggio':
        return AppColors.text;
      case 'acqua':
        return AppColors.gold;
      case 'scarico':
        return Colors.blueGrey;
      case 'gpl':
        return Colors.deepOrange;
      case 'assistenza':
        return Colors.redAccent;
      case 'sosta':
      default:
        return AppColors.moss;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GeoLocationResult>(
      valueListenable: selectedLocationController,
      builder: (context, selectedLocation, _) {
        final selectedPoint = LatLng(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );
        final places = _filteredPlaces(selectedPoint);
        final cacheSnapshot = _cacheSnapshot;

        return ScreenScaffold(
          title: 'Smart map',
          subtitle: 'Search a city, select it, then filters and POI react.',
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
                              for (final place in places)
                                Marker(
                                  point: LatLng(
                                    place.latitude,
                                    place.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    _iconForCategory(place.category),
                                    color: _colorForCategory(place.category),
                                    size: 32,
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
              'Map uses OpenStreetMap tiles live. Offline storage applies to POI only.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResourceBar(
                    label: 'Cache POI offline',
                    value: _places.isEmpty
                        ? 0
                        : (cacheSnapshot?.itemCount ?? 0) / _places.length,
                    detail: cacheSnapshot == null
                        ? 'No saved POI cache'
                        : '${cacheSnapshot.region} - ${cacheSnapshot.itemCount} items - ${cacheSnapshot.sizeLabel}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cacheSnapshot == null
                        ? 'POI only, no map tiles'
                        : 'Updated ${cacheSnapshot.updatedLabel} - POI only, no map tiles',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _isRefreshingCache ? null : _refreshCache,
                        icon: _isRefreshingCache
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isClearingCache ? null : _clearCache,
                        icon: _isClearingCache
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
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
              children: [
                for (final entry in _filterLabels.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _activeFilters.contains(entry.key),
                    onSelected: (_) => _toggleFilter(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'POI', action: '${places.length} visible'),
            const SizedBox(height: 12),
            if (places.isEmpty)
              const PremiumCard(
                child: Text('No POI match the active filters'),
              ),
            for (final place in places) ...[
              PlaceCard(
                name: place.name,
                type: '${place.type} - ${_filterLabels[place.category]}',
                distance:
                    '${_distanceKm(place, selectedPoint).toStringAsFixed(1)} km',
                rating: place.rating,
                tags: place.tags,
                address: place.address,
                city: place.city,
                coordinates:
                    '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                services: place.services,
                source: place.source,
                onDirections: () => _openDirections(place),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
