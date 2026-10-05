import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/services/app_system_services.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/maplibre_offline_region_manager.dart';
import '../../../core/state/selected_location.dart';
import '../../../data/models/camper_place.dart';
import '../../../data/models/download_models.dart';
import '../../../data/repositories/local_poi_cache_repository.dart';
import '../../../data/repositories/map_view_state_repository.dart';
import '../../../data/repositories/offline_map_repository.dart';
import '../../../data/repositories/offline_poi_repository.dart';
import '../../offline/presentation/offline_content_screen.dart';
import 'map_engine_v2_preview_screen.dart';
import 'map_place_filters.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    this.places,
    this.cacheRepository,
    this.offlineMapRepository,
    this.poiRepository,
    this.mapLibreOfflineManager,
    this.mapViewStateRepository,
    this.onOpenDirections,
    this.renderMap = true,
    super.key,
  });

  final List<CamperPlace>? places;
  final PoiCacheRepository? cacheRepository;

  /// Retained only for source compatibility with the Step 7 PMTiles path.
  /// Step 16D no longer exposes or activates this legacy renderer.
  final OfflineMapRepository? offlineMapRepository;
  final PoiRepository? poiRepository;
  final MapLibreOfflineRegionManager? mapLibreOfflineManager;
  final MapViewStateRepository? mapViewStateRepository;
  final Future<void> Function(CamperPlace place)? onOpenDirections;
  final bool renderMap;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchController = TextEditingController();
  final _geocodingService = const GeocodingService();
  final _locationService = const LocationService();
  final _distance = const Distance();
  Timer? _debounce;
  StreamSubscription<List<DownloadRecord>>? _downloadSubscription;
  String _poiDownloadSignature = '';

  List<GeoLocationResult> _results = const [];
  late List<CamperPlace> _places = widget.places ?? const <CamperPlace>[];
  late final PoiCacheRepository _cacheRepository =
      widget.cacheRepository ?? LocalPoiCacheRepository();
  late final PoiRepository _poiRepository =
      widget.poiRepository ?? LocalOfflinePoiRepository();
  late final Set<String> _activeFilters = {...mapFilterLabels.keys};

  bool _isSearching = false;
  bool _isLocating = false;
  bool _isRefreshingCache = false;
  bool _isClearingCache = false;
  String? _error;
  PoiCacheSnapshot? _cacheSnapshot;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    if (widget.places == null && widget.poiRepository == null) {
      _downloadSubscription = AppSystemServices.instance.downloads
          .watchDownloads()
          .listen(_handleDownloadRecords);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _downloadSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleDownloadRecords(List<DownloadRecord> records) {
    final installedPoiIds = records
        .where(
          (record) =>
              record.type == DownloadPackageType.poiDatabase &&
              record.status == DownloadStatus.completed,
        )
        .map((record) => record.packageId)
        .toList(growable: false)
      ..sort();
    final signature = installedPoiIds.join('|');
    if (signature == _poiDownloadSignature) return;
    _poiDownloadSignature = signature;
    unawaited(_loadLocalData());
  }

  Future<void> _loadLocalData() async {
    try {
      final snapshot = await _cacheRepository.loadSnapshot();
      final offlinePlaces = await _poiRepository.listAll();
      if (!mounted) return;
      setState(() {
        _cacheSnapshot = snapshot;
        if (offlinePlaces.isNotEmpty && widget.places == null) {
          _places = offlinePlaces;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'map_error_poi_cache_unavailable'.tr());
    }
  }

  Future<void> _search(String query) async {
    final language = context.locale.languageCode;
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
        final results = await _geocodingService.search(trimmed, language: language);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isSearching = false;
          _error = results.isEmpty ? 'map_error_no_locations'.tr() : null;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _error = 'map_error_location_search'.tr();
        });
      }
    });
  }

  void _selectLocation(GeoLocationResult location) {
    selectedLocationController.value = location;
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
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _refreshCache() async {
    setState(() {
      _isRefreshingCache = true;
      _error = null;
    });

    try {
      final snapshot = await _cacheRepository.refresh(
        region: selectedLocationController.value?.label ?? 'map_custom_area'.tr(),
        places: _places,
      );
      if (!mounted) return;
      setState(() => _cacheSnapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'map_error_cache_refresh'.tr());
    } finally {
      if (mounted) setState(() => _isRefreshingCache = false);
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
      setState(() => _error = 'map_error_cache_clear'.tr());
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  Future<void> _openOfflineContent() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OfflineContentScreen(),
      ),
    );
    if (mounted) {
      await _loadLocalData();
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
      setState(() => _error = 'map_error_directions'.tr());
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

  List<CamperPlace> _filteredPlaces(LatLng? selectedPoint) {
    return filterAndSortPlaces(
      places: _places,
      activeFilters: _activeFilters,
      selectedPoint: selectedPoint,
      distance: _distance,
    );
  }

  double _distanceKm(CamperPlace place, LatLng selectedPoint) {
    return _distance.as(
      LengthUnit.Kilometer,
      selectedPoint,
      LatLng(place.latitude, place.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GeoLocationResult?>(
      valueListenable: selectedLocationController,
      builder: (context, selectedLocation, _) {
        final selectedPoint = selectedLocation == null
            ? null
            : LatLng(selectedLocation.latitude, selectedLocation.longitude);
        // Renderer fallback only: never use this coordinate for POI distance
        // labels or distance-based sorting.
        final mapCenter = selectedPoint ?? const LatLng(42.5, 12.5);
        final places = _filteredPlaces(selectedPoint);
        final cacheSnapshot = _cacheSnapshot;

        return ScreenScaffold(
          title: 'map_title'.tr(),
          subtitle: 'map_subtitle'.tr(),
          children: [
            Semantics(
              container: true,
              label: 'map_semantics_interactive'.tr(),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLocation?.label ?? 'map_default_label'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'offline_title'.tr(),
                          onPressed: _openOfflineContent,
                          icon: const Icon(Icons.cloud_download_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height:
                          MediaQuery.sizeOf(context).height < 720 ? 420 : 520,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MapEngineV2PreviewScreen(
                          key: const ValueKey('primary-maplibre-map'),
                          places: places,
                          initialLatitude: mapCenter.latitude,
                          initialLongitude: mapCenter.longitude,
                          onOpenDirections: _openDirections,
                          offlineManager: widget.mapLibreOfflineManager,
                          stateRepository: widget.mapViewStateRepository,
                          renderMap: widget.renderMap,
                          embedded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              tooltip: 'common_clear'.tr(),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _results = const [];
                                  _error = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      hintText: 'map_search_hint'.tr(),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label:
                          Text(_isLocating ? 'map_locating'.tr() : 'map_use_my_location'.tr()),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
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
            const SizedBox(height: 12),
            Text(
              'map_offline_explanation'.tr(),
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
                    label: 'map_poi_cache'.tr(),
                    value: _places.isEmpty
                        ? 0
                        : (cacheSnapshot?.itemCount ?? 0) / _places.length,
                    detail: cacheSnapshot == null
                        ? 'map_poi_cache_empty'.tr()
                        : 'map_poi_cache_detail'.tr(
                            namedArgs: {
                              'region': cacheSnapshot.region,
                              'count': cacheSnapshot.itemCount.toString(),
                              'size': cacheSnapshot.sizeLabel,
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cacheSnapshot == null
                        ? 'map_poi_cache_cartography_note'.tr()
                        : 'map_poi_cache_updated'.tr(
                            namedArgs: {'updated': cacheSnapshot.updatedLabel},
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _isRefreshingCache ? null : _refreshCache,
                        icon: _isRefreshingCache
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: Text('common_refresh'.tr()),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isClearingCache ? null : _clearCache,
                        icon: _isClearingCache
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                        label: Text('common_delete'.tr()),
                      ),
                      IconButton.outlined(
                        tooltip: 'offline_title'.tr(),
                        onPressed: _openOfflineContent,
                        icon: const Icon(Icons.cloud_download_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'map_filters'.tr()),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in mapFilterLabels.entries)
                  FilterChip(
                    key: ValueKey('map-filter-${entry.key}'),
                    label: Text(entry.value.tr()),
                    selected: _activeFilters.contains(entry.key),
                    onSelected: (_) => _toggleFilter(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'map_poi'.tr(),
              action: 'map_poi_visible'.tr(
                namedArgs: {'count': places.length.toString()},
              ),
            ),
            const SizedBox(height: 12),
            if (places.isEmpty)
              PremiumCard(child: Text('map_poi_empty'.tr())),
            for (final place in places) ...[
              PlaceCard(
                name: place.name,
                type:
                    '${place.type} - ${mapFilterLabels[place.category]?.tr() ?? place.category}',
                distance: selectedPoint == null
                    ? ''
                    : '${localizedDecimal(
                        _distanceKm(place, selectedPoint),
                        locale: context.locale.toLanguageTag(),
                      )} km',
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
