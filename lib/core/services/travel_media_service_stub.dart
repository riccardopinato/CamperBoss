import '../../data/models/travel_history_models.dart';

class ImportedGpxFile {
  const ImportedGpxFile({
    required this.content,
    required this.localPath,
    required this.fileName,
  });

  final String content;
  final String localPath;
  final String fileName;
}

abstract interface class TravelMediaService {
  Future<ImportedGpxFile?> importGpxFile();
  Future<PhotoLocationCandidate?> importPhoto();
  Future<List<int>?> readPrivateFile(String path);
  Future<String> writeTextFile(String fileName, String content);
  Future<String> writeBinaryFile(String fileName, List<int> bytes);
  Future<void> deleteFiles(Iterable<String?> paths);
}

TravelMediaService createTravelMediaService() {
  return UnsupportedTravelMediaService();
}

class UnsupportedTravelMediaService implements TravelMediaService {
  @override
  Future<ImportedGpxFile?> importGpxFile() {
    throw UnsupportedError('travel_history_platform_unsupported');
  }

  @override
  Future<PhotoLocationCandidate?> importPhoto() {
    throw UnsupportedError('travel_history_platform_unsupported');
  }

  @override
  Future<List<int>?> readPrivateFile(String path) async => null;

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {}

  @override
  Future<String> writeTextFile(String fileName, String content) {
    throw UnsupportedError('travel_history_platform_unsupported');
  }

  @override
  Future<String> writeBinaryFile(String fileName, List<int> bytes) {
    throw UnsupportedError('travel_history_platform_unsupported');
  }
}
