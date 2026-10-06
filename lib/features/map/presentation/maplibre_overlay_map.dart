import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/config/map_engine_v2_config.dart';

class MapLibreOverlayPoint {
  const MapLibreOverlayPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.selected = false,
    this.kind = 'point',
  });

  final String id;
  final double latitude;
  final double longitude;
  final bool selected;
  final String kind;
}

class MapLibreOverlayPath {
  const MapLibreOverlayPath({
    required this.id,
    required this.points,
    this.colorHex = '#E6B85C',
    this.width = 4,
  });

  final String id;
  final List<MapLibreOverlayPoint> points;
  final String colorHex;
  final double width;
}

/// Shared secondary-map renderer.
///
/// Step 16D uses this widget for route previews and travel history so every
/// cartographic surface in CamperBoss is rendered by MapLibre and can reuse
/// the same native style/offline cache prepared by the main Map screen.
class MapLibreOverlayMap extends StatefulWidget {
  const MapLibreOverlayMap({
    required this.paths,
    required this.points,
    this.onPointTap,
    this.renderMap = true,
    this.fallbackLatitude = 45.6049,
    this.fallbackLongitude = 10.6351,
    super.key,
  });

  final List<MapLibreOverlayPath> paths;
  final List<MapLibreOverlayPoint> points;
  final ValueChanged<String>? onPointTap;
  final bool renderMap;
  final double fallbackLatitude;
  final double fallbackLongitude;

  @override
  State<MapLibreOverlayMap> createState() => _MapLibreOverlayMapState();
}

class _MapLibreOverlayMapState extends State<MapLibreOverlayMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _rendering = false;

  @override
  void didUpdateWidget(covariant MapLibreOverlayMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths != widget.paths || oldWidget.points != widget.points) {
      unawaited(_renderOverlays());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<MapLibreOverlayPoint> get _allPoints => [
        ...widget.points,
        for (final path in widget.paths) ...path.points,
      ];

  LatLng get _initialCenter {
    final points = _allPoints;
    if (points.isEmpty) {
      return LatLng(widget.fallbackLatitude, widget.fallbackLongitude);
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }
    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  double get _initialZoom {
    final points = _allPoints;
    if (points.length < 2) return 12;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }
    final span = math.max(maxLat - minLat, maxLon - minLon);
    if (span <= 0.03) return 13.5;
    if (span <= 0.12) return 11.5;
    if (span <= 0.5) return 9.5;
    if (span <= 2) return 7.5;
    if (span <= 6) return 5.8;
    return 4.5;
  }

  Future<void> _renderOverlays() async {
    final controller = _controller;
    if (!_styleReady || controller == null || controller.isDisposed || _rendering) {
      return;
    }

    _rendering = true;
    try {
      await controller.clearLines();
      await controller.clearCircles();

      final paths = widget.paths
          .where((path) => path.points.length > 1)
          .toList(growable: false);
      if (paths.isNotEmpty) {
        await controller.addLines(
          [
            for (final path in paths)
              LineOptions(
                geometry: [
                  for (final point in path.points)
                    LatLng(point.latitude, point.longitude),
                ],
                lineColor: path.colorHex,
                lineWidth: path.width,
                lineOpacity: 0.92,
              ),
          ],
          [
            for (final path in paths)
              <String, dynamic>{'pathId': path.id},
          ],
        );
      }

      if (widget.points.isNotEmpty) {
        await controller.addCircles(
          [
            for (final point in widget.points)
              CircleOptions(
                geometry: LatLng(point.latitude, point.longitude),
                circleRadius: point.selected ? 10 : 7,
                circleColor: _pointColor(point),
                circleStrokeColor: '#FFFFFF',
                circleStrokeWidth: point.selected ? 3 : 2,
              ),
          ],
          [
            for (final point in widget.points)
              <String, dynamic>{'pointId': point.id},
          ],
        );
      }
    } finally {
      _rendering = false;
    }
  }

  String _pointColor(MapLibreOverlayPoint point) {
    if (point.selected) return '#E6B85C';
    return switch (point.kind) {
      'memory' => '#7E57C2',
      'plannedStop' => '#1565C0',
      'waypoint' => '#E6B85C',
      _ => '#455A64',
    };
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['pointId']?.toString();
    if (id != null) widget.onPointTap?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.renderMap) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: const Center(
          child: Icon(Icons.map_outlined, size: 56),
        ),
      );
    }

    return MapLibreMap(
      styleString: MapEngineV2Config.styleUrl,
      initialCameraPosition: CameraPosition(
        target: _initialCenter,
        zoom: _initialZoom,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        controller.onCircleTapped.add(_onCircleTapped);
      },
      onStyleLoadedCallback: () {
        _styleReady = true;
        unawaited(_renderOverlays());
      },
      annotationOrder: const [
        AnnotationType.line,
        AnnotationType.circle,
      ],
      annotationConsumeTapEvents: const [AnnotationType.circle],
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      logoEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
    );
  }
}
