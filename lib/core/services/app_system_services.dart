import '../config/offline_content_config.dart';
import '../../data/repositories/installed_resource_repository.dart';
import '../../data/repositories/map_view_state_repository.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import '../../data/repositories/offline_poi_repository.dart';
import '../../data/repositories/poi_package_state_repository.dart';
import 'app_download_manager.dart';
import 'data_integrity_service.dart';
import 'local_search_service.dart';
import 'maplibre_offline_region_manager.dart';
import 'offline_guides_service.dart';
import 'offline_system_coordinator.dart';
import 'poi_catalog_service.dart';
import 'poi_package_installer.dart';
import 'reminder_coordinator.dart';
import 'remote_manifest_loader.dart';

/// Process-wide service container for cross-feature infrastructure.
class AppSystemServices {
  AppSystemServices._();

  static final AppSystemServices instance = AppSystemServices._();

  late final InstalledResourceRepository installedResources =
      LocalInstalledResourceRepository();

  late final RemoteManifestLoader? _remoteManifestLoader =
      OfflineContentConfig.manifestUri case final uri?
          ? RemoteManifestLoader(uri: uri)
          : null;

  late final OfflineManifestRepository offlineManifestRepository =
      LocalOfflineManifestRepository(
    remoteLoader: _remoteManifestLoader?.load,
    allowedHosts: OfflineContentConfig.allowedHosts,
  );

  late final PoiRepository poiRepository = LocalOfflinePoiRepository();
  late final PoiPackageStateRepository poiPackageStates =
      LocalPoiPackageStateRepository();

  late final PoiPackageInstaller poiPackageInstaller = PoiPackageInstaller(
    poiRepository: poiRepository,
    stateRepository: poiPackageStates,
    manifestRepository: offlineManifestRepository,
    installedRepository: installedResources,
  );

  late final AppDownloadManager downloads = BackgroundDownloaderManager(
    installedRepository: installedResources,
    manifestRepository: offlineManifestRepository,
    packageInstaller: poiPackageInstaller,
    allowedHosts: OfflineContentConfig.allowedHosts,
  );

  late final PoiCatalogService poiCatalog = PoiCatalogService(
    manifestRepository: offlineManifestRepository,
    downloadManager: downloads,
    stateRepository: poiPackageStates,
    remoteConfigured: OfflineContentConfig.isRemoteCatalogConfigured,
  );

  late final MapLibreOfflineRegionManager mapOfflineManager =
      const NativeMapLibreOfflineRegionManager();
  late final MapViewStateRepository mapViewStateRepository =
      MapViewStateRepository();
  late final OfflineGuidesService guides = LocalOfflineGuidesService(
    installedRepository: installedResources,
  );

  late final OfflineSystemCoordinator offline = OfflineSystemCoordinator(
    downloadManager: downloads,
    mapManager: mapOfflineManager,
    mapStateRepository: mapViewStateRepository,
    guidesService: guides,
  );

  late final ReminderCoordinator reminders = ReminderCoordinator();
  late final LocalSearchService search = LocalSearchService();
  late final DataIntegrityService integrity = DataIntegrityService();

  DataIntegrityReport? lastIntegrityReport;
  bool _initializationStarted = false;

  Future<void> initialize() async {
    if (_initializationStarted) return;
    _initializationStarted = true;

    try {
      await offline.reconcile();
    } catch (_) {
      // Recovery remains available from the Offline UI.
    }
    try {
      await reminders.initializeAndReconcile();
    } catch (_) {
      // Notification/plugin errors must not block startup.
    }
    try {
      await search.ensureFresh(force: true);
    } catch (_) {
      // Search can rebuild lazily when opened.
    }
    try {
      lastIntegrityReport = await integrity.audit();
    } catch (_) {
      lastIntegrityReport = null;
    }
  }
}
