import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../config/map_engine_v2_config.dart';

class MapLibreOfflineRegionSnapshot {
  const MapLibreOfflineRegionSnapshot({
    required this.id,
    required this.name,
    required this.downloadedBytes,
    required this.isComplete,
    this.progress = 0,
  });

  final String id;
  final String name;
  final int downloadedBytes;
  final bool isComplete;
  final double progress;
}

class MapLibreOfflineRegionRequest {
  const MapLibreOfflineRegionRequest({
    required this.id,
    required this.name,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.minZoom,
    required this.maxZoom,
  });

  final String id;
  final String name;
  final double south;
  final double west;
  final double north;
  final double east;
  final double minZoom;
  final double maxZoom;
}

MapLibreOfflineRegionRequest mapLibreOfflineRequestForViewport({
  required String id,
  required String name,
  required double south,
  required double west,
  required double north,
  required double east,
  required double currentZoom,
}) {
  final normalizedSouth = math.min(south, north).clamp(-85.0, 85.0).toDouble();
  final normalizedNorth = math.max(south, north).clamp(-85.0, 85.0).toDouble();
  final normalizedWest = math.min(west, east).clamp(-180.0, 180.0).toDouble();
  final normalizedEast = math.max(west, east).clamp(-180.0, 180.0).toDouble();

  final largestSpan = math.max(
    normalizedNorth - normalizedSouth,
    normalizedEast - normalizedWest,
  );
  final minZoom = math.min(
    currentZoom.floorToDouble(),
    MapEngineV2Config.minimumOfflineZoom,
  ).clamp(4.0, MapEngineV2Config.minimumOfflineZoom).toDouble();
  final adaptiveMax =
      MapEngineV2Config.offlineMaxZoomForSpan(largestSpan);
  final maxZoom = math
      .max(adaptiveMax, currentZoom.ceilToDouble())
      .clamp(minZoom, 17.0)
      .toDouble();

  return MapLibreOfflineRegionRequest(
    id: id,
    name: name,
    south: normalizedSouth,
    west: normalizedWest,
    north: normalizedNorth,
    east: normalizedEast,
    minZoom: minZoom,
    maxZoom: maxZoom,
  );
}

abstract interface class MapLibreOfflineRegionManager {
  bool get isSupported;

  Future<List<MapLibreOfflineRegionSnapshot>> listRegions();

  Stream<MapLibreOfflineRegionSnapshot> download(
    MapLibreOfflineRegionRequest request,
  );

  Future<void> delete(String regionId);

  Future<void> clearAmbientCache();
}

class NativeMapLibreOfflineRegionManager
    implements MapLibreOfflineRegionManager {
  const NativeMapLibreOfflineRegionManager();

  @override
  bool get isSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      MapEngineV2Config.isOfflineDownloadConfigured;

  @override
  Future<List<MapLibreOfflineRegionSnapshot>> listRegions() async {
    if (!isSupported) return const [];

    final nativeRegions = await ml.getListOfRegions();
    final regions = <MapLibreOfflineRegionSnapshot>[];

    for (final region in nativeRegions) {
      if (!_belongsToCamperBoss(region)) continue;
      final status = await ml.getOfflineRegionStatus(region.id);
      regions.add(_toDomain(region, status));
    }

    regions.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return List<MapLibreOfflineRegionSnapshot>.unmodifiable(regions);
  }

  @override
  Stream<MapLibreOfflineRegionSnapshot> download(
    MapLibreOfflineRegionRequest request,
  ) {
    final controller = StreamController<MapLibreOfflineRegionSnapshot>();
    unawaited(_download(request, controller));
    return controller.stream;
  }

  Future<void> _download(
    MapLibreOfflineRegionRequest request,
    StreamController<MapLibreOfflineRegionSnapshot> controller,
  ) async {
    try {
      if (!isSupported) {
        throw UnsupportedError(
          'MapLibre offline regions require Android and an approved offline map provider.',
        );
      }

      final existing = await ml.getListOfRegions();
      for (final region in existing) {
        if (!_matches(region, request.id)) continue;

        final status = await ml.getOfflineRegionStatus(region.id);
        if (status.isComplete) {
          controller.add(_toDomain(region, status));
          return;
        }
        await ml.deleteOfflineRegion(region.id);
      }

      controller.add(
        MapLibreOfflineRegionSnapshot(
          id: request.id,
          name: request.name,
          downloadedBytes: 0,
          isComplete: false,
        ),
      );

      final completion = Completer<void>();
      var lastBytes = 0;
      var lastProgress = 0.0;

      final nativeRegion = await ml.downloadOfflineRegion(
        ml.OfflineRegionDefinition(
          bounds: ml.LatLngBounds(
            southwest: ml.LatLng(request.south, request.west),
            northeast: ml.LatLng(request.north, request.east),
          ),
          mapStyleUrl: MapEngineV2Config.offlineStyleUrl!,
          minZoom: request.minZoom,
          maxZoom: request.maxZoom,
        ),
        metadata: <String, dynamic>{
          'camperBossRegionId': request.id,
          'name': request.name,
          'engine': MapEngineV2Config.engineId,
        },
        onEvent: (event) {
          if (event is ml.InProgress) {
            lastBytes = event.completedResourceSize;
            lastProgress =
                (event.progress / 100).clamp(0.0, 1.0).toDouble();
            if (!controller.isClosed) {
              controller.add(
                MapLibreOfflineRegionSnapshot(
                  id: request.id,
                  name: request.name,
                  downloadedBytes: lastBytes,
                  isComplete: false,
                  progress: lastProgress,
                ),
              );
            }
          } else if (event is ml.Success && !completion.isCompleted) {
            completion.complete();
          } else if (event is ml.Error && !completion.isCompleted) {
            completion.completeError(StateError(event.cause.toString()));
          }
        },
      );

      await completion.future;
      final status = await ml.getOfflineRegionStatus(nativeRegion.id);

      if (!controller.isClosed) {
        controller.add(
          MapLibreOfflineRegionSnapshot(
            id: request.id,
            name: request.name,
            downloadedBytes: status.completedResourceSize > 0
                ? status.completedResourceSize
                : lastBytes,
            isComplete: status.isComplete,
            progress: status.isComplete
                ? 1
                : (status.downloadProgress / 100)
                    .clamp(lastProgress, 1.0)
                    .toDouble(),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    } finally {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  @override
  Future<void> delete(String regionId) async {
    if (!isSupported) return;

    final regions = await ml.getListOfRegions();
    for (final region in regions) {
      if (_matches(region, regionId)) {
        await ml.deleteOfflineRegion(region.id);
      }
    }
  }

  @override
  Future<void> clearAmbientCache() async {
    if (isSupported) {
      await ml.clearAmbientCache();
    }
  }

  bool _belongsToCamperBoss(ml.OfflineRegion region) {
    return region.metadata['engine']?.toString() ==
            MapEngineV2Config.engineId ||
        region.metadata.containsKey('camperBossRegionId');
  }

  bool _matches(ml.OfflineRegion region, String domainId) {
    return region.metadata['camperBossRegionId']?.toString() == domainId ||
        region.id.toString() == domainId;
  }

  MapLibreOfflineRegionSnapshot _toDomain(
    ml.OfflineRegion region,
    ml.OfflineRegionStatus status,
  ) {
    return MapLibreOfflineRegionSnapshot(
      id: region.metadata['camperBossRegionId']?.toString() ??
          region.id.toString(),
      name: region.metadata['name']?.toString() ?? 'CamperBoss offline map',
      downloadedBytes: status.completedResourceSize,
      isComplete: status.isComplete,
      progress: status.isComplete
          ? 1
          : (status.downloadProgress / 100)
              .clamp(0.0, 1.0)
              .toDouble(),
    );
  }
}
