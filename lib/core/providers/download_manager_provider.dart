import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_models.dart';
import '../../data/models/offline_map_models.dart';
import '../../data/repositories/installed_resource_repository.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import '../../data/repositories/offline_map_repository.dart';
import '../../data/repositories/offline_poi_repository.dart';
import '../services/app_download_manager.dart';
import '../services/app_system_services.dart';
import '../services/offline_system_coordinator.dart';
import '../services/storage_inspector.dart';

final downloadManagerProvider = Provider<AppDownloadManager>((ref) {
  return AppSystemServices.instance.downloads;
});

final offlineSystemProvider = Provider<OfflineSystemCoordinator>((ref) {
  return AppSystemServices.instance.offline;
});

final offlineSystemSnapshotProvider =
    FutureProvider<OfflineSystemSnapshot>((ref) {
  return ref.watch(offlineSystemProvider).snapshot();
});

final downloadsProvider = StreamProvider<List<DownloadRecord>>((ref) async* {
  final manager = ref.watch(downloadManagerProvider);
  await manager.reconcile();
  yield* manager.watchDownloads();
});

final offlineManifestRepositoryProvider =
    Provider<OfflineManifestRepository>((ref) {
  return AppSystemServices.instance.offlineManifestRepository;
});

final installedResourceRepositoryProvider =
    Provider<InstalledResourceRepository>((ref) {
  return AppSystemServices.instance.installedResources;
});

final installedResourcesProvider =
    StreamProvider<List<InstalledResource>>((ref) async* {
  final repository = ref.watch(installedResourceRepositoryProvider);
  await repository.reconcile();
  yield* repository.watchAll();
});

final storageInspectorProvider = Provider<StorageInspector>((ref) {
  return LocalStorageInspector(
    repository: ref.watch(installedResourceRepositoryProvider),
  );
});

final storageProjectionProvider = FutureProvider<StorageProjection>((ref) {
  return ref.watch(storageInspectorProvider).projectInstallation(const []);
});

final offlineMapRepositoryProvider = Provider<OfflineMapRepository>((ref) {
  return LocalOfflineMapRepository(
    installedRepository: ref.watch(installedResourceRepositoryProvider),
  );
});

final installedMapRegionsProvider =
    StreamProvider<List<InstalledMapRegion>>((ref) async* {
  final repository = ref.watch(offlineMapRepositoryProvider);
  yield* repository.watchInstalledRegions();
});

final offlinePoiRepositoryProvider = Provider<PoiRepository>((ref) {
  return LocalOfflinePoiRepository();
});
