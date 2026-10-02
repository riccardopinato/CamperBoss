import '../../data/models/guide_models.dart';
import '../../data/repositories/map_view_state_repository.dart';
import 'app_download_manager.dart';
import 'maplibre_offline_region_manager.dart';
import 'offline_guides_service.dart';

class VerifiedOfflineMapRegion {
  const VerifiedOfflineMapRegion({
    required this.region,
    required this.viewport,
  });

  final MapLibreOfflineRegionSnapshot region;
  final OfflineRegionViewport? viewport;

  bool get canOpenOffline => region.isComplete && viewport != null;
}

class OfflineSystemSnapshot {
  const OfflineSystemSnapshot({
    required this.mapRegions,
    required this.guidePackages,
  });

  final List<VerifiedOfflineMapRegion> mapRegions;
  final List<GuidePackage> guidePackages;

  int get openableMapRegionCount =>
      mapRegions.where((item) => item.canOpenOffline).length;

  bool get hasOpenableOfflineContent =>
      openableMapRegionCount > 0 || guidePackages.isNotEmpty;
}

/// Single coordination boundary for all offline subsystems.
class OfflineSystemCoordinator {
  OfflineSystemCoordinator({
    required this.downloadManager,
    required this.mapManager,
    required this.mapStateRepository,
    required this.guidesService,
  });

  final AppDownloadManager downloadManager;
  final MapLibreOfflineRegionManager mapManager;
  final MapViewStateRepository mapStateRepository;
  final OfflineGuidesService guidesService;

  Future<void> reconcile() async {
    await downloadManager.reconcile();
    await guidesService.listInstalledPackages();
    await snapshot();
  }

  Future<OfflineSystemSnapshot> snapshot() async {
    final regions = await mapManager.listRegions();
    final verified = <VerifiedOfflineMapRegion>[];
    for (final region in regions) {
      verified.add(
        VerifiedOfflineMapRegion(
          region: region,
          viewport: region.isComplete
              ? await mapStateRepository.findRegion(region.id)
              : null,
        ),
      );
    }

    return OfflineSystemSnapshot(
      mapRegions: List.unmodifiable(verified),
      guidePackages:
          List.unmodifiable(await guidesService.listInstalledPackages()),
    );
  }

  Future<bool> canOpenMapRegion(String regionId) async {
    final state = await snapshot();
    return state.mapRegions.any(
      (item) => item.region.id == regionId && item.canOpenOffline,
    );
  }
}
