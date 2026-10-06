import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Exports an already-created backup file without buffering it into memory.
///
/// Android/iOS use a native document picker that streams from [sourcePath].
/// Desktop platforms choose a destination directory and copy via dart:io.
class BackupFileExportService {
  const BackupFileExportService();

  static const MethodChannel _channel =
      MethodChannel('com.camperboss/file_export');

  Future<Uri?> exportFile({
    required String sourcePath,
    required String fileName,
    String mimeType = 'application/zip',
    String? dialogTitle,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Backup source file does not exist');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final value = await _channel.invokeMethod<String?>(
        'exportFile',
        <String, Object?>{
          'sourcePath': source.path,
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
      if (value == null || value.isEmpty) return null;
      return Uri.tryParse(value);
    }

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (directory == null || directory.isEmpty) return null;

    final target = await _uniqueTarget(directory, fileName);
    await source.openRead().pipe(target.openWrite());
    return target.uri;
  }

  Future<File> _uniqueTarget(String directory, String fileName) async {
    final base = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    var target = File(p.join(directory, fileName));
    var suffix = 1;
    while (await target.exists()) {
      target = File(p.join(directory, '$base-$suffix$extension'));
      suffix++;
    }
    return target;
  }
}
