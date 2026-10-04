import 'dart:io';

import '../../data/models/download_models.dart';

abstract interface class OfflinePackageInstaller {
  Future<void> install(DownloadRecord record, File file);
  Future<void> uninstall(DownloadRecord record);
  Future<void> reconcile();
}

class NoopOfflinePackageInstaller implements OfflinePackageInstaller {
  const NoopOfflinePackageInstaller();

  @override
  Future<void> install(DownloadRecord record, File file) async {}

  @override
  Future<void> uninstall(DownloadRecord record) async {}

  @override
  Future<void> reconcile() async {}
}
