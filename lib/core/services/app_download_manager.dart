import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/download_models.dart';
import '../../data/repositories/download_record_repository.dart';
import '../../data/repositories/installed_resource_repository.dart';
import '../../data/repositories/offline_manifest_repository.dart';
import 'download_file_verifier.dart';
import 'offline_package_installer.dart';
import 'storage_inspector.dart';

abstract interface class AppDownloadManager {
  Stream<List<DownloadRecord>> watchDownloads();
  Future<void> enqueue(DownloadablePackage package);
  Future<void> pause(String id);
  Future<void> resume(String id);
  Future<void> cancel(String id);
  Future<void> retry(String id);
  Future<void> delete(String id);
  Future<void> reconcile();
}

class BackgroundDownloaderManager implements AppDownloadManager {
  BackgroundDownloaderManager({
    DownloadRecordRepository? repository,
    InstalledResourceRepository? installedRepository,
    OfflineManifestRepository? manifestRepository,
    FileDownloader? downloader,
    DownloadFileVerifier verifier = const DownloadFileVerifier(),
    OfflinePackageInstaller packageInstaller =
        const NoopOfflinePackageInstaller(),
    StorageInspector? storageInspector,
    this.allowedHosts = const {},
  })  : _repository = repository ?? LocalDownloadRecordRepository(),
        _installedRepository =
            installedRepository ?? LocalInstalledResourceRepository(),
        _manifestRepository =
            manifestRepository ?? LocalOfflineManifestRepository(),
        _downloader = downloader ?? FileDownloader(),
        _verifier = verifier,
        _packageInstaller = packageInstaller,
        _storageInspector = storageInspector {
    _subscription = _downloader.updates.listen(_handleUpdate);
  }

  final DownloadRecordRepository _repository;
  final InstalledResourceRepository _installedRepository;
  final OfflineManifestRepository _manifestRepository;
  final FileDownloader _downloader;
  final DownloadFileVerifier _verifier;
  final OfflinePackageInstaller _packageInstaller;
  final StorageInspector? _storageInspector;
  final Set<String> allowedHosts;
  late final _controller = StreamController<List<DownloadRecord>>.broadcast(
    onListen: () {
      _publish();
    },
  );
  StreamSubscription<TaskUpdate>? _subscription;
  var _started = false;

  @override
  Stream<List<DownloadRecord>> watchDownloads() {
    return _controller.stream;
  }

  @override
  Future<void> enqueue(DownloadablePackage package) async {
    await _ensureStarted();
    final uri = Uri.tryParse(package.url);
    if (uri == null || uri.scheme != 'https') {
      throw ArgumentError('Invalid package URL');
    }
    if (allowedHosts.isNotEmpty && !allowedHosts.contains(uri.host)) {
      throw ArgumentError('Package URL host is not allowed');
    }
    _validateFileName(package.fileName);
    final destinationDirectory =
        normalizeOfflineDestinationDirectory(package.destinationDirectory);
    if (package.fileSizeBytes < 0) {
      throw ArgumentError('Package size cannot be negative');
    }

    final storageInspector = _storageInspector;
    if (storageInspector != null) {
      final projection =
          await storageInspector.projectInstallation([package]);
      if (!projection.canInstall) {
        throw InsufficientStorageException(
          requiredBytes:
              package.fileSizeBytes + projection.safetyMarginBytes,
          availableBytes: projection.availableBytes,
        );
      }
    }

    final now = DateTime.now();
    final taskId = buildDownloadTaskId(package);
    final tempDirectory = '$destinationDirectory/partial';
    final task = DownloadTask(
      taskId: taskId,
      url: package.url,
      filename: '${package.fileName}.part',
      directory: tempDirectory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: package.group,
      updates: Updates.statusAndProgress,
      requiresWiFi: package.requiresWifiByDefault,
      retries: 2,
      allowPause: true,
      priority: package.priority.clamp(0, 10),
      metaData: package.id,
      displayName: package.title,
    );

    final support = await getApplicationSupportDirectory();
    final finalPath = p.join(
      support.path,
      destinationDirectory,
      package.fileName,
    );

    await _repository.saveRecord(
      DownloadRecord(
        packageId: package.id,
        taskId: taskId,
        type: package.type,
        title: package.title,
        version: package.version,
        fileName: package.fileName,
        localPath: finalPath,
        status: DownloadStatus.queued,
        downloadedBytes: 0,
        totalBytes: package.fileSizeBytes,
        expectedSha256: package.expectedSha256,
        installedSha256: '',
        createdAt: now,
        updatedAt: now,
        group: package.group,
      ),
    );
    await _installedRepository.upsert(
      InstalledResource(
        packageId: package.id,
        type: package.type,
        version: package.version,
        localPath: finalPath,
        fileSizeBytes: package.fileSizeBytes,
        status: InstalledResourceStatus.installing,
      ),
    );
    await _publish();

    final queued = await _downloader.enqueue(task);
    if (!queued) {
      await _updateRecord(
        package.id,
        status: DownloadStatus.failed,
        lastError: 'Task could not be enqueued',
      );
    }
  }

  @override
  Future<void> pause(String id) async {
    final record = await _repository.getRecord(id);
    final task = await _taskFor(record);
    if (record == null || task == null) return;
    final paused = await _downloader.pause(task);
    if (paused) {
      await _updateRecord(id, status: DownloadStatus.paused);
    }
  }

  @override
  Future<void> resume(String id) async {
    final record = await _repository.getRecord(id);
    final task = await _taskFor(record);
    if (record == null || task == null) return;
    final resumed = await _downloader.resume(task);
    if (resumed) {
      await _updateRecord(id, status: DownloadStatus.running);
    }
  }

  @override
  Future<void> cancel(String id) async {
    final record = await _repository.getRecord(id);
    if (record == null) return;
    await _downloader.cancelTaskWithId(record.taskId);
    await _deletePartial(record);
    await _updateRecord(id, status: DownloadStatus.canceled);
  }

  @override
  Future<void> retry(String id) async {
    final record = await _repository.getRecord(id);
    if (record == null) return;

    final task = await _taskFor(record);
    if (task == null) {
      DownloadManifest? cachedManifest;
      try {
        cachedManifest = await _manifestRepository.loadCachedManifest();
      } catch (_) {
        cachedManifest = null;
      }

      final package = findRetryPackage(cachedManifest, record);
      if (package == null) {
        await _updateRecord(
          id,
          status: DownloadStatus.failed,
          lastError: 'Retry metadata is unavailable',
        );
        return;
      }

      await enqueue(package);
      return;
    }

    await _updateRecord(id, status: DownloadStatus.queued, lastError: null);
    final queued = await _downloader.enqueue(task);
    if (!queued) {
      await _updateRecord(
        id,
        status: DownloadStatus.failed,
        lastError: 'Retry could not be enqueued',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    final record = await _repository.getRecord(id);
    if (record == null) return;
    await _downloader.cancelTaskWithId(record.taskId);
    await _deletePartial(record);
    await _packageInstaller.uninstall(record);
    final installed = File(record.localPath);
    if (await installed.exists()) {
      await installed.delete();
    }
    await _repository.deleteRecord(id);
    await _installedRepository.delete(id);
    await _publish();
  }

  @override
  Future<void> reconcile() async {
    await _ensureStarted();
    final records = await _repository.listRecords();
    final pluginRecords = await _downloader.database.allRecords();
    final pluginTaskIds = pluginRecords.map((record) => record.taskId).toSet();

    for (final record in records) {
      final installed = File(record.localPath);
      final installedExists = await installed.exists();
      if (record.status == DownloadStatus.completed && !installedExists) {
        await _updateRecord(
          record.packageId,
          status: DownloadStatus.failed,
          lastError: 'Installed file is missing',
        );
        continue;
      }
      if ((record.status == DownloadStatus.running ||
              record.status == DownloadStatus.queued) &&
          !pluginTaskIds.contains(record.taskId)) {
        await _updateRecord(
          record.packageId,
          status: DownloadStatus.failed,
          lastError: 'Download task was lost by the operating system',
        );
      }
      if (installedExists && record.status != DownloadStatus.completed) {
        await _verifyAndInstall(record);
      }
    }
    await _installedRepository.reconcile();
    await _packageInstaller.reconcile();
    await _publish();
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    await _downloader.start(
      doTrackTasks: true,
      markDownloadedComplete: false,
      doRescheduleKilledTasks: true,
    );
    _started = true;
  }

  Future<DownloadTask?> _taskFor(DownloadRecord? record) async {
    if (record == null) return null;
    final taskRecord = await _downloader.database.recordForId(record.taskId);
    final task = taskRecord?.task;
    return task is DownloadTask ? task : null;
  }

  Future<void> _handleUpdate(TaskUpdate update) async {
    if (update.task.metaData.isEmpty) return;
    switch (update) {
      case TaskStatusUpdate():
        await _handleStatus(update);
      case TaskProgressUpdate():
        await _handleProgress(update);
    }
  }

  Future<void> _handleStatus(TaskStatusUpdate update) async {
    final packageId = update.task.metaData;
    final status = switch (update.status) {
      TaskStatus.enqueued => DownloadStatus.queued,
      TaskStatus.running => DownloadStatus.running,
      TaskStatus.paused => DownloadStatus.paused,
      TaskStatus.complete => DownloadStatus.verifying,
      TaskStatus.failed => DownloadStatus.failed,
      TaskStatus.canceled => DownloadStatus.canceled,
      TaskStatus.notFound => DownloadStatus.failed,
      TaskStatus.waitingToRetry => DownloadStatus.queued,
    };
    await _updateRecord(packageId, status: status);
    if (update.status == TaskStatus.complete) {
      final record = await _repository.getRecord(packageId);
      if (record != null) {
        await _verifyAndInstall(record);
      }
    }
  }

  Future<void> _handleProgress(TaskProgressUpdate update) async {
    final packageId = update.task.metaData;
    final record = await _repository.getRecord(packageId);
    if (record == null) return;
    final progress = update.progress.clamp(0.0, 1.0);
    await _repository.saveRecord(
      record.copyWith(
        status: DownloadStatus.running,
        progress: progress,
        downloadedBytes: record.totalBytes > 0
            ? (record.totalBytes * progress).round()
            : record.downloadedBytes,
        updatedAt: DateTime.now(),
      ),
    );
    await _publish();
  }

  void _validateFileName(String fileName) {
    if (fileName.trim().isEmpty ||
        fileName.contains('/') ||
        fileName.contains('\\') ||
        fileName.contains('..')) {
      throw ArgumentError('Invalid package file name');
    }
  }

  Future<void> _verifyAndInstall(DownloadRecord record) async {
    await _updateRecord(record.packageId, status: DownloadStatus.verifying);
    final support = await getApplicationSupportDirectory();
    final partial = File(
      p.join(
        support.path,
        p.dirname(p.relative(record.localPath, from: support.path)),
        'partial',
        '${record.fileName}.part',
      ),
    );
    final target = File(record.localPath);
    final candidate = await partial.exists() ? partial : target;
    final verification = await _verifier.verify(
      file: candidate,
      expectedBytes: record.totalBytes,
      expectedSha256: record.expectedSha256,
    );
    if (!verification.valid) {
      if (await partial.exists()) {
        await partial.delete();
      }
      await _updateRecord(
        record.packageId,
        status: DownloadStatus.corrupted,
        installedSha256: verification.actualSha256 ?? '',
        lastError: verification.error,
      );
      await _installedRepository.upsert(
        InstalledResource(
          packageId: record.packageId,
          type: record.type,
          version: record.version,
          localPath: record.localPath,
          fileSizeBytes: record.totalBytes,
          installedSha256: verification.actualSha256,
          status: InstalledResourceStatus.corrupted,
          lastVerifiedAt: DateTime.now(),
          lastError: verification.error,
        ),
      );
      return;
    }

    await target.parent.create(recursive: true);
    final previous = File(target.path + '.previous');
    var previousMoved = false;
    var promotedNewCandidate = false;

    try {
      if (candidate.path != target.path) {
        if (await previous.exists()) {
          await previous.delete();
        }
        if (await target.exists()) {
          await target.rename(previous.path);
          previousMoved = true;
        }
        await candidate.rename(target.path);
        promotedNewCandidate = true;
      }

      await _packageInstaller.install(record, target);

      if (previousMoved && await previous.exists()) {
        await previous.delete();
      }
    } catch (error) {
      if (promotedNewCandidate && await target.exists()) {
        await target.delete();
      }
      if (previousMoved && await previous.exists()) {
        await previous.rename(target.path);
      }

      final prefix = _isNoSpaceError(error)
          ? 'Package activation failed: insufficient device storage'
          : 'Package activation failed: ' + error.toString();
      await _updateRecord(
        record.packageId,
        status: DownloadStatus.failed,
        installedSha256: verification.actualSha256 ?? record.expectedSha256,
        lastError: prefix,
      );
      final failedSize =
          await target.exists() ? await target.length() : record.totalBytes;
      await _installedRepository.upsert(
        InstalledResource(
          packageId: record.packageId,
          type: record.type,
          version: record.version,
          localPath: target.path,
          fileSizeBytes: failedSize,
          installedSha256:
              verification.actualSha256 ?? record.expectedSha256,
          status: InstalledResourceStatus.failed,
          lastVerifiedAt: DateTime.now(),
          lastError: prefix,
        ),
      );
      return;
    }

    await _repository.saveRecord(
      record.copyWith(
        status: DownloadStatus.completed,
        localPath: target.path,
        downloadedBytes: await target.length(),
        installedSha256: verification.actualSha256 ?? record.expectedSha256,
        progress: 1,
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
        lastError: null,
      ),
    );
    await _installedRepository.upsert(
      InstalledResource(
        packageId: record.packageId,
        type: record.type,
        version: record.version,
        localPath: target.path,
        fileSizeBytes: await target.length(),
        installedSha256: verification.actualSha256 ?? record.expectedSha256,
        status: InstalledResourceStatus.installed,
        installedAt: DateTime.now(),
        lastVerifiedAt: DateTime.now(),
      ),
    );
    await _publish();
  }

  bool _isNoSpaceError(Object error) {
    if (error is! FileSystemException) return false;
    final code = error.osError?.errorCode;
    final message = error.osError?.message.toLowerCase() ?? '';
    return code == 28 ||
        message.contains('no space') ||
        message.contains('disk full');
  }

  Future<void> _deletePartial(DownloadRecord record) async {
    final support = await getApplicationSupportDirectory();
    final partial = File(
      p.join(
        support.path,
        p.dirname(p.relative(record.localPath, from: support.path)),
        'partial',
        '${record.fileName}.part',
      ),
    );
    if (await partial.exists()) {
      await partial.delete();
    }
  }

  Future<void> _updateRecord(
    String packageId, {
    required DownloadStatus status,
    String? installedSha256,
    String? lastError,
  }) async {
    final record = await _repository.getRecord(packageId);
    if (record == null) return;
    await _repository.saveRecord(
      record.copyWith(
        status: status,
        installedSha256: installedSha256,
        updatedAt: DateTime.now(),
        lastError: lastError,
      ),
    );
    await _publish();
  }

  Future<void> _publish() async {
    if (_controller.isClosed) return;
    _controller.add(await _repository.listRecords());
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}

DownloadablePackage? findRetryPackage(
  DownloadManifest? manifest,
  DownloadRecord record,
) {
  if (manifest == null) return null;
  for (final package in manifest.packages) {
    if (package.id == record.packageId &&
        package.version == record.version &&
        package.fileName == record.fileName) {
      return package;
    }
  }
  return null;
}

class FakeDownloadManager implements AppDownloadManager {
  FakeDownloadManager([List<DownloadRecord> records = const []])
      : _records = [...records];

  final List<DownloadRecord> _records;
  late final _controller = StreamController<List<DownloadRecord>>.broadcast(
    onListen: _emit,
  );

  @override
  Stream<List<DownloadRecord>> watchDownloads() {
    return _controller.stream;
  }

  @override
  Future<void> enqueue(DownloadablePackage package) async {
    final now = DateTime.now();
    _records.removeWhere((record) => record.packageId == package.id);
    _records.add(
      DownloadRecord(
        packageId: package.id,
        taskId: buildDownloadTaskId(package),
        type: package.type,
        title: package.title,
        version: package.version,
        fileName: package.fileName,
        localPath: '/tmp/${package.fileName}',
        status: DownloadStatus.queued,
        downloadedBytes: 0,
        totalBytes: package.fileSizeBytes,
        expectedSha256: package.expectedSha256,
        installedSha256: '',
        createdAt: now,
        updatedAt: now,
        group: package.group,
      ),
    );
    _emit();
  }

  @override
  Future<void> pause(String id) => _setStatus(id, DownloadStatus.paused);

  @override
  Future<void> resume(String id) => _setStatus(id, DownloadStatus.running);

  @override
  Future<void> cancel(String id) => _setStatus(id, DownloadStatus.canceled);

  @override
  Future<void> retry(String id) => _setStatus(id, DownloadStatus.queued);

  @override
  Future<void> delete(String id) async {
    _records.removeWhere((record) => record.packageId == id);
    _emit();
  }

  @override
  Future<void> reconcile() async => _emit();

  Future<void> _setStatus(String id, DownloadStatus status) async {
    final index = _records.indexWhere((record) => record.packageId == id);
    if (index == -1) return;
    _records[index] = _records[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_records));
    }
  }
}
