import 'package:camperboss/core/providers/download_manager_provider.dart';
import 'package:camperboss/core/services/app_download_manager.dart';
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
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineContentScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('offline_empty_title'), findsOneWidget);
    expect(find.text('offline_wifi_only'), findsOneWidget);
  });

  testWidgets('download row shows progress and actions', (tester) async {
    final now = DateTime(2026);
    final manager = FakeDownloadManager([
      DownloadRecord(
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
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [downloadManagerProvider.overrideWithValue(manager)],
        child: const MaterialApp(home: Scaffold(body: OfflineContentScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manuale prova'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('offline_pause'), findsOneWidget);
    expect(find.text('offline_cancel'), findsOneWidget);
  });
}
