import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/config/map_engine_v2_config.dart';
import '../../../core/services/maplibre_offline_region_manager.dart';
import '../../../data/models/camper_place.dart';
import '../../../data/repositories/map_view_state_repository.dart';
import '../../../shared/widgets/premium_card.dart';
import '../domain/maplibre_poi_clusterer.dart';

/// Production MapLibre surface used by the main Map tab.
///
/// The historical class name is intentionally retained for source compatibility
/// while Step 16D promotes this engine from a preview to the single user-facing
/// map/offline implementation.
class MapEngineV2PreviewScreen extends StatefulWidget {
  const MapEngineV2PreviewScreen({
    required this.places,
    required this.initialLatitude,
    required this.initialLongitude,
    this.onOpenDirections,
    this.offlineManager,
    this.stateRepository,
    this.renderMap = true,
    this.embedded = false,
    super.key,
  });

  final List<CamperPlace> places;
  final double initialLatitude;
  final double initialLongitude;
  final Future<void> Function(CamperPlace place)? onOpenDirections;
  final MapLibreOfflineRegionManager? offlineManager;
  final MapViewStateRepository? stateRepository;
  final bool renderMap;
  final bool embedded;

  @override
  State<MapEngineV2PreviewScreen> createState() =>
      _MapEngineV2PreviewScreenState();
}

class _MapEngineV2PreviewScreenState extends State<MapEngineV2PreviewScreen> {
  final MapLibrePoiClusterer _clusterer = const MapLibrePoiClusterer();

  late final MapLibreOfflineRegionManager _offlineManager =
      widget.offlineManager ?? const NativeMapLibreOfflineRegionManager();
  late final MapViewStateRepository _stateRepository =
      widget.stateRepository ?? MapViewStateRepository();

  MapLibreMapController? _mapController;
  bool _styleReady = false;
  bool _syncingPoi = false;
  bool _downloadingOffline = false;
  bool _restoredCamera = false;
  double _zoom = MapEngineV2Config.initialZoom;
  double _offlineProgress = 0;
  String? _error;
  CamperPlace? _selectedPlace;
  List<MapLibreOfflineRegionSnapshot> _offlineRegions = const [];
  Map<String, MapLibrePoiCluster> _clustersById = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadOfflineRegions());
  }

  @override
  void didUpdateWidget(covariant MapEngineV2PreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places ||
        oldWidget.places.length != widget.places.length) {
      unawaited(_syncPoiAnnotations());
    }

    if (oldWidget.initialLatitude != widget.initialLatitude ||
        oldWidget.initialLongitude != widget.initialLongitude) {
      _selectedPlace = null;
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        unawaited(
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(widget.initialLatitude, widget.initialLongitude),
              math.max(_zoom, 11.5),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOfflineRegions() async {
    try {
      final regions = await _offlineManager.listRegions();
      if (!mounted) return;
      setState(() {
        _offlineRegions = regions;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _restoreCameraIfAvailable() async {
    if (_restoredCamera) return;
    _restoredCamera = true;
    final controller = _mapController;
    if (controller == null || controller.isDisposed) return;

    final saved = await _stateRepository.loadCamera();
    if (saved == null || !mounted) return;
    _zoom = saved.zoom;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(saved.latitude, saved.longitude),
        saved.zoom,
      ),
    );
  }

  Future<void> _persistCamera() async {
    final controller = _mapController;
    if (controller == null || controller.isDisposed) return;
    try {
      final camera = await controller.queryCameraPosition();
      if (camera == null) return;
      _zoom = camera.zoom;
      await _stateRepository.saveCamera(
        MapViewportState(
          latitude: camera.target.latitude,
          longitude: camera.target.longitude,
          zoom: camera.zoom,
        ),
      );
    } catch (_) {
      // Camera persistence is best-effort and must never break the map.
    }
  }

  Future<void> _syncPoiAnnotations() async {
    final controller = _mapController;
    if (!_styleReady ||
        controller == null ||
        controller.isDisposed ||
        _syncingPoi) {
      return;
    }

    _syncingPoi = true;
    try {
      final camera = await controller.queryCameraPosition();
      final zoom = camera?.zoom ?? _zoom;
      _zoom = zoom;

      final clusters = _clusterer.cluster(
        places: widget.places,
        zoom: zoom,
      );
      final byId = <String, MapLibrePoiCluster>{
        for (final cluster in clusters) cluster.id: cluster,
      };

      await controller.clearCircles();
      if (clusters.isNotEmpty) {
        await controller.addCircles(
          [
            for (final cluster in clusters)
              CircleOptions(
                geometry: LatLng(cluster.latitude, cluster.longitude),
                circleRadius: cluster.isCluster
                    ? (12 + cluster.count.clamp(2, 20) * 0.35)
                    : 8,
                circleColor: cluster.isCluster
                    ? '#E6B85C'
                    : _colorForCategory(cluster.singlePlace?.category),
                circleStrokeColor: '#FFFFFF',
                circleStrokeWidth: cluster.isCluster ? 2.8 : 2.2,
              ),
          ],
          [
            for (final cluster in clusters)
              <String, dynamic>{
                'clusterId': cluster.id,
                'count': cluster.count,
              },
          ],
        );
      }

      if (!mounted) return;
      setState(() {
        _clustersById = Map<String, MapLibrePoiCluster>.unmodifiable(byId);
        _error = null;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _syncingPoi = false;
    }
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['clusterId']?.toString();
    final cluster = id == null ? null : _clustersById[id];
    if (cluster == null) return;

    if (cluster.isCluster) {
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        unawaited(
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(cluster.latitude, cluster.longitude),
              math.min(_zoom + 2, 17),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _selectedPlace = cluster.singlePlace);
  }

  Future<void> _prepareVisibleAreaOffline() async {
    final controller = _mapController;
    if (!_offlineManager.isSupported ||
        controller == null ||
        controller.isDisposed ||
        !_styleReady ||
        _downloadingOffline) {
      return;
    }

    setState(() {
      _downloadingOffline = true;
      _offlineProgress = 0;
      _error = null;
    });

    try {
      final bounds = await controller.getVisibleRegion();
      final camera = await controller.queryCameraPosition();
      final zoom = camera?.zoom ?? _zoom;
      final center = camera?.target ??
          LatLng(widget.initialLatitude, widget.initialLongitude);

      final id =
          'camperboss-v2-${center.latitude.toStringAsFixed(3)}-${center.longitude.toStringAsFixed(3)}-${zoom.round()}';
      final request = mapLibreOfflineRequestForViewport(
        id: id,
        name:
            'Area ${center.latitude.toStringAsFixed(2)}, ${center.longitude.toStringAsFixed(2)}',
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        currentZoom: zoom,
      );

      await _stateRepository.saveRegion(
        OfflineRegionViewport(
          id: request.id,
          name: request.name,
          centerLatitude: center.latitude,
          centerLongitude: center.longitude,
          zoom: zoom,
          south: request.south,
          west: request.west,
          north: request.north,
          east: request.east,
        ),
      );

      await for (final snapshot in _offlineManager.download(request)) {
        if (!mounted) return;
        setState(() => _offlineProgress = snapshot.progress);
      }
      await _loadOfflineRegions();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _downloadingOffline = false);
    }
  }

  Future<void> _openRegion(MapLibreOfflineRegionSnapshot region) async {
    final saved = await _stateRepository.findRegion(region.id);
    final controller = _mapController;
    if (saved == null || controller == null || controller.isDisposed) {
      if (mounted) {
        setState(() {
          _error =
              'Area offline disponibile, ma il viewport storico non è stato salvato. Aprila dalla posizione corrente e risalvala se necessario.';
        });
      }
      return;
    }

    _zoom = saved.zoom;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(saved.centerLatitude, saved.centerLongitude),
        saved.zoom,
      ),
    );
    await _stateRepository.saveCamera(
      MapViewportState(
        latitude: saved.centerLatitude,
        longitude: saved.centerLongitude,
        zoom: saved.zoom,
      ),
    );
  }

  Future<void> _deleteRegion(MapLibreOfflineRegionSnapshot region) async {
    try {
      await _offlineManager.delete(region.id);
      await _stateRepository.deleteRegion(region.id);
      await _loadOfflineRegions();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _clearAmbientCache() async {
    try {
      await _offlineManager.clearAmbientCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cartografica temporanea eliminata')),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildMapBody(context);
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mappa'),
        actions: [
          IconButton(
            tooltip: 'Pulisci cache temporanea',
            onPressed: _offlineManager.isSupported ? _clearAmbientCache : null,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: body,
      floatingActionButton: _offlineManager.isSupported
          ? FloatingActionButton.extended(
              onPressed: _downloadingOffline || !_styleReady
                  ? null
                  : _prepareVisibleAreaOffline,
              icon: _downloadingOffline
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
              label: const Text('Salva area offline'),
            )
          : null,
    );
  }

  Widget _buildMapBody(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: widget.renderMap
              ? MapLibreMap(
                  styleString: MapEngineV2Config.styleUrl,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.initialLatitude,
                      widget.initialLongitude,
                    ),
                    zoom: MapEngineV2Config.initialZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    controller.onCircleTapped.add(_onCircleTapped);
                    unawaited(_restoreCameraIfAvailable());
                  },
                  onStyleLoadedCallback: () {
                    _styleReady = true;
                    unawaited(_syncPoiAnnotations());
                  },
                  onCameraMove: (position) {
                    _zoom = position.zoom;
                  },
                  onCameraIdle: () {
                    unawaited(_persistCamera());
                    unawaited(_syncPoiAnnotations());
                  },
                  annotationOrder: const [AnnotationType.circle],
                  annotationConsumeTapEvents: const [AnnotationType.circle],
                  trackCameraPosition: true,
                  doubleClickZoomEnabled: false,
                  compassEnabled: true,
                  compassViewPosition: CompassViewPosition.topRight,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  logoEnabled: false,
                  attributionButtonPosition:
                      AttributionButtonPosition.bottomRight,
                )
              : ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const Center(child: Icon(Icons.map_outlined, size: 72)),
                ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mappa & offline',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Chip(
                      label: Text(
                        _offlineManager.isSupported
                            ? 'Offline disponibile'
                            : 'Solo online',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.places.length} POI visibili',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  MapEngineV2Config.attribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (_downloadingOffline) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _offlineProgress > 0 ? _offlineProgress : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preparazione area offline: ${(_offlineProgress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_offlineRegions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final region in _offlineRegions)
                        InputChip(
                          label: Text(
                            '${region.name} - ${_sizeLabel(region.downloadedBytes)}',
                          ),
                          avatar: Icon(
                            region.isComplete
                                ? Icons.offline_pin_outlined
                                : Icons.downloading_outlined,
                            size: 18,
                          ),
                          onPressed:
                              region.isComplete ? () => _openRegion(region) : null,
                          onDeleted: () => _deleteRegion(region),
                        ),
                    ],
                  ),
                ],
                if (widget.embedded && _offlineManager.isSupported) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _downloadingOffline || !_styleReady
                            ? null
                            : _prepareVisibleAreaOffline,
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: const Text('Salva area offline'),
                      ),
                      IconButton.outlined(
                        tooltip: 'Pulisci cache temporanea',
                        onPressed: _clearAmbientCache,
                        icon: const Icon(Icons.cleaning_services_outlined),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_selectedPlace != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: PremiumCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlace!.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          [
                            _selectedPlace!.type,
                            if (_selectedPlace!.city != null)
                              _selectedPlace!.city!,
                            if (_selectedPlace!.source != null)
                              _selectedPlace!.source!,
                          ].join(' - '),
                        ),
                        if (widget.onOpenDirections != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                widget.onOpenDirections!(_selectedPlace!),
                            icon: const Icon(Icons.directions_outlined),
                            label: const Text('Indicazioni'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiudi',
                    onPressed: () => setState(() => _selectedPlace = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _colorForCategory(String? category) {
    return switch (category) {
      'camping' => '#2F6F45',
      'sosta' => '#1565C0',
      'parcheggio' => '#546E7A',
      'acqua' => '#0288D1',
      'scarico' => '#6A1B9A',
      'gpl' => '#EF6C00',
      'assistenza' => '#C62828',
      _ => '#455A64',
    };
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
