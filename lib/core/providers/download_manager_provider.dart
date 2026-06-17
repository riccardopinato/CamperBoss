import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_models.dart';
import '../services/app_download_manager.dart';

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
