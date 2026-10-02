import 'package:camperboss/core/providers/download_manager_provider.dart';
import 'package:camperboss/core/services/app_download_manager.dart';
import 'package:camperboss/core/services/offline_system_coordinator.dart';
import 'package:camperboss/core/services/storage_inspector.dart';
import 'package:camperboss/data/models/download_models.dart';
import 'package:camperboss/features/offline/presentation/offline_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline content screen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(FakeDownloadManager()),
          downloadsProvider.overrideWithValue(
            const AsyncData<List<DownloadRecord>>([]),
          ),
          storageInspectorProvider.overrideWithValue(
            const _FakeStorageInspector(),
          ),
          offlineSystemSnapshotProvider.overrideWithValue(
            const AsyncData<OfflineSystemSnapshot>(
              OfflineSystemSnapshot(
                mapRegions: [],
                guidePackages: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineContentScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('offline_empty_title'), findsOneWidget);
    expect(find.text('offline_wifi_only'), findsOneWidget);
  });

  testWidgets('download row shows progress and actions', (tester) async {
    final now = DateTime(2026);
    final record = DownloadRecord(
      packageId: 'manual-1',
      taskId: 'manual-1-2026',
      type: DownloadPackageType.manual,
      title: 'Manuale prova',
      version: '2026.06',
      fileName: 'manual.pdf',
      localPath: '/tmp/manual.pdf',
      status: DownloadStatus.running,
      downloadedBytes: 50,
      totalBytes: 100,
      expectedSha256: '',
      installedSha256: '',
      createdAt: now,
      updatedAt: now,
      progress: 0.5,
    );
    final manager = FakeDownloadManager([record]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(manager),
          downloadsProvider.overrideWithValue(
            AsyncData<List<DownloadRecord>>([record]),
          ),
          storageInspectorProvider.overrideWithValue(
            const _FakeStorageInspector(),
          ),
          offlineSystemSnapshotProvider.overrideWithValue(
            const AsyncData<OfflineSystemSnapshot>(
              OfflineSystemSnapshot(
                mapRegions: [],
                guidePackages: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineContentScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Manuale prova'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('offline_pause'), findsOneWidget);
    expect(find.text('offline_cancel'), findsOneWidget);
  });

  testWidgets('offline content screen shows storage projection',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadManagerProvider.overrideWithValue(FakeDownloadManager()),
          downloadsProvider.overrideWithValue(
            const AsyncData<List<DownloadRecord>>([]),
          ),
          storageInspectorProvider.overrideWithValue(
            const _FakeStorageInspector(),
          ),
          offlineSystemSnapshotProvider.overrideWithValue(
            const AsyncData<OfflineSystemSnapshot>(
              OfflineSystemSnapshot(
                mapRegions: [],
                guidePackages: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineContentScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('offline_storage_title'), findsOneWidget);
    expect(find.textContaining('1.0 MB'), findsOneWidget);
  });
}

class _FakeStorageInspector implements StorageInspector {
  const _FakeStorageInspector();

  @override
  Future<int> getAvailableBytes() async => 1024 * 1024;

  @override
  Future<int> getUsedBytesByCategory(DownloadPackageType type) async => 0;

  @override
  Future<StorageProjection> projectInstallation(
    Iterable<DownloadablePackage> packages,
  ) async {
    return const StorageProjection(
      availableBytes: 1024 * 1024,
      usedBytes: 0,
      selectedBytes: 0,
      projectedUsedBytes: 0,
      projectedRemainingBytes: 1024 * 1024,
      pressure: StoragePressure.normal,
      usedByType: {},
    );
  }
}
