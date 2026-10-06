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
import 'restore_recovery_bootstrap.dart';
import 'storage_inspector.dart';

/// Process-wide service container for cross-feature infrastructure.
class AppSystemServices {
  AppSystemServices._();

  static final AppSystemServices instance = AppSystemServices._();

  late final InstalledResourceRepository installedResources =
      LocalInstalledResourceRepository();

  late final RemoteManifestLoader? _remoteManifestLoader =
      _createRemoteManifestLoader();

  late final OfflineManifestRepository offlineManifestRepository =
      LocalOfflineManifestRepository(
    remoteLoader: _remoteManifestLoader?.load,
    allowedHosts: OfflineContentConfig.allowedHosts,
  );

  late final PoiRepository poiRepository = LocalOfflinePoiRepository();
  late final PoiPackageStateRepository poiPackageStates =
      LocalPoiPackageStateRepository();

  late final MapLibreOfflineRegionManager mapOfflineManager =
      const NativeMapLibreOfflineRegionManager();

  late final StorageInspector storageInspector = LocalStorageInspector(
    repository: installedResources,
    mapManager: mapOfflineManager,
  );

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
    storageInspector: storageInspector,
    allowedHosts: OfflineContentConfig.allowedHosts,
  );

  late final PoiCatalogService poiCatalog = PoiCatalogService(
    manifestRepository: offlineManifestRepository,
    downloadManager: downloads,
    stateRepository: poiPackageStates,
    remoteConfigured: OfflineContentConfig.isRemoteCatalogConfigured,
  );

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

  RemoteManifestLoader? _createRemoteManifestLoader() {
    final uri = OfflineContentConfig.manifestUri;
    return uri == null ? null : RemoteManifestLoader(uri: uri);
  }

  Future<void> initialize() async {
    if (_initializationStarted) return;

    // A pending restore journal means canonical local data may be only
    // partially replaced. Recover it before any derived service reads state.
    await recoverInterruptedRestoreIfNeeded();
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
