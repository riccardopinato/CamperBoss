import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

import '../../../core/theme/app_colors.dart';

class MapMarkerClusterLayer extends StatelessWidget {
  const MapMarkerClusterLayer({
    required this.markers,
    super.key,
  });

  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 52,
        size: const Size(48, 48),
        computeSize: _sizeForCluster,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
        disableClusteringAtZoom: 17,
        zoomToBoundsOnClick: true,
        centerMarkerOnClick: false,
        spiderfyCluster: true,
        showPolygon: false,
        animationsOptions: const AnimationsOptions(
          zoom: Duration(milliseconds: 260),
          fitBound: Duration(milliseconds: 260),
          centerMarker: Duration(milliseconds: 180),
          spiderfy: Duration(milliseconds: 260),
        ),
        builder: (context, markers) => _ClusterBubble(count: markers.length),
      ),
    );
  }

  Size _sizeForCluster(List<Marker> markers) {
    if (markers.length >= 50) return const Size(68, 68);
    if (markers.length >= 10) return const Size(58, 58);
    return const Size(48, 48);
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = count >= 50
        ? scheme.primary
        : count >= 10
            ? scheme.secondary
            : AppColors.surfaceSoft;
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(
          color: foreground.withValues(alpha: 0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}
