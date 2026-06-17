import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_models.dart';
import '../../data/repositories/installed_resource_repository.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import '../services/app_download_manager.dart';
import '../services/storage_inspector.dart';

final downloadManagerProvider = Provider<AppDownloadManager>((ref) {
  final manager = BackgroundDownloaderManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final downloadsProvider = StreamProvider<List<DownloadRecord>>((ref) async* {
  final manager = ref.watch(downloadManagerProvider);
  await manager.reconcile();
  yield* manager.watchDownloads();
});

final offlineManifestRepositoryProvider =
    Provider<OfflineManifestRepository>((ref) {
  return LocalOfflineManifestRepository();
});

final installedResourceRepositoryProvider =
    Provider<InstalledResourceRepository>((ref) {
  return LocalInstalledResourceRepository();
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
