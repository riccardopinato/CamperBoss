import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  return LocalTravelMediaService();
}

class LocalTravelMediaService implements TravelMediaService {
  @override
  Future<ImportedGpxFile?> importGpxFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['gpx'],
    );
    final path = picked?.path;
    if (path == null) return null;
    final localPath = await _copyIntoPrivateStorage(path, subdirectory: 'gpx');
    return ImportedGpxFile(
      content: await File(localPath).readAsString(),
      localPath: localPath,
      fileName: p.basename(path),
    );
  }

  @override
  Future<PhotoLocationCandidate?> importPhoto() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    final path = picked?.path;
    if (path == null) return null;

    final localPath =
        await _copyIntoPrivateStorage(path, subdirectory: 'travel_memories');
    final bytes = await File(localPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null || !image.hasExif) {
      return PhotoLocationCandidate(path: localPath, previewBytes: bytes);
    }

    final gpsIfd = image.exif.gpsIfd;
    final exifIfd = image.exif.exifIfd;
    var latitude = gpsIfd.gpsLatitude;
    var longitude = gpsIfd.gpsLongitude;
    final latitudeRef = gpsIfd.gpsLatitudeRef;
    final longitudeRef = gpsIfd.gpsLongitudeRef;
    if (latitude != null && latitudeRef == 'S') latitude = -latitude;
    if (longitude != null && longitudeRef == 'W') longitude = -longitude;

    final dateRaw =
        exifIfd[0x9003]?.toString() ?? image.exif.imageIfd[0x0132]?.toString();
    return PhotoLocationCandidate(
      path: localPath,
      previewBytes: bytes,
      latitude: latitude,
      longitude: longitude,
      recordedAt: _parseExifDate(dateRaw),
    );
  }

  @override
  Future<List<int>?> readPrivateFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<String> writeTextFile(String fileName, String content) async {
    return _writeFile(fileName: fileName, bytes: content.codeUnits);
  }

  @override
  Future<String> writeBinaryFile(String fileName, List<int> bytes) async {
    return _writeFile(fileName: fileName, bytes: bytes);
  }

  Future<String> _writeFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final directory = await _historyDirectory('exports');
    final target = File(p.join(directory.path, fileName));
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    for (final path in paths) {
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<String> _copyIntoPrivateStorage(
    String sourcePath, {
    required String subdirectory,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('travel_history_file_missing', sourcePath);
    }
    final directory = await _historyDirectory(subdirectory);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(sourcePath).toLowerCase()}';
    final target = File(p.join(directory.path, name));
    await source.copy(target.path);
    return target.path;
  }

  Future<Directory> _historyDirectory(String name) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'travel_history', name));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  DateTime? _parseExifDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.replaceFirstMapped(
      RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
      (match) => '${match.group(1)}-${match.group(2)}-${match.group(3)}',
    );
    return DateTime.tryParse(normalized);
  }
}
