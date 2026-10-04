import 'dart:io';

import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_travel_history_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import 'managed_media_inspector.dart';

ManagedMediaInspector createManagedMediaInspector() {
  return LocalManagedMediaInspector();
}

class LocalManagedMediaInspector implements ManagedMediaInspector {
  LocalManagedMediaInspector({
    VehicleDocumentRepository? documentRepository,
    MaintenanceRepository? maintenanceRepository,
    TravelHistoryRepository? historyRepository,
  })  : _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _historyRepository =
            historyRepository ?? LocalTravelHistoryRepository();

  final VehicleDocumentRepository _documentRepository;
  final MaintenanceRepository _maintenanceRepository;
  final TravelHistoryRepository _historyRepository;

  @override
  Future<ManagedMediaSnapshot> snapshot() async {
    try {
      final documents = await _documentRepository.listDocuments();
      final maintenance = await _maintenanceRepository.listRecords();
      final tracks = await _historyRepository.listTracks();
      final memories = await _historyRepository.listMemories();

      final paths = <String>{
        for (final document in documents)
          ...document.filePaths.where((path) => path.isNotEmpty),
        for (final record in maintenance)
          ...record.attachmentPaths.where((path) => path.isNotEmpty),
        for (final track in tracks)
          if (track.localFilePath case final path? when path.isNotEmpty) path,
        for (final memory in memories)
          ...memory.localPhotoPaths.where((path) => path.isNotEmpty),
      };

      var bytes = 0;
      var count = 0;
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;
        bytes += await file.length();
        count++;
      }

      return ManagedMediaSnapshot(
        bytes: bytes,
        fileCount: count,
        isAvailable: true,
      );
    } catch (_) {
      return const ManagedMediaSnapshot(
        bytes: 0,
        fileCount: 0,
        isAvailable: false,
      );
    }
  }
}
