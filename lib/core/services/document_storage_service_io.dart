import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class DocumentStorageService {
  Future<String> copyIntoPrivateDocuments(String pathOrUri);
  Future<void> deleteFiles(Iterable<String?> paths);
}

DocumentStorageService createDocumentStorageService() {
  return LocalDocumentStorageService();
}

class LocalDocumentStorageService implements DocumentStorageService {
  static const _privacyChannel = MethodChannel('com.camperboss/privacy');

  @override
  Future<String> copyIntoPrivateDocuments(String pathOrUri) async {
    final source = _fileFromPathOrUri(pathOrUri);
    if (!source.existsSync()) {
      throw FileSystemException('document_error_file_missing', source.path);
    }
    final directory = await _documentsDirectory();
    final extension = p.extension(source.path).toLowerCase();
    final name = 'doc_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(directory.path, name));
    await source.copy(target.path);
    if (Platform.isIOS) {
      try {
        await _privacyChannel.invokeMethod<void>(
          'excludeFromBackup',
          {'path': target.path},
        );
      } catch (_) {
        if (target.existsSync()) {
          await target.delete();
        }
        rethrow;
      }
    }
    return target.path;
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    for (final path in paths) {
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  File _fileFromPathOrUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return File(uri.toFilePath());
    }
    return File(value);
  }

  Future<Directory> _documentsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'vehicle_documents'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
