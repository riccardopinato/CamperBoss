enum DocumentCaptureSource {
  androidScanner,
  imageImport,
  pdfImport;

  String get storageValue {
    return switch (this) {
      DocumentCaptureSource.androidScanner => 'android_scanner',
      DocumentCaptureSource.imageImport => 'image_import',
      DocumentCaptureSource.pdfImport => 'pdf_import',
    };
  }
}

enum DocumentOcrStatus {
  notRequested,
  processing,
  ready,
  failed,
  notAvailable;

  String get storageValue {
    return switch (this) {
      DocumentOcrStatus.notRequested => 'notRequested',
      DocumentOcrStatus.processing => 'processing',
      DocumentOcrStatus.ready => 'ready',
      DocumentOcrStatus.failed => 'failed',
      DocumentOcrStatus.notAvailable => 'notAvailable',
    };
  }

  static DocumentOcrStatus fromStorage(String? value) {
    return switch (value) {
      'processing' => DocumentOcrStatus.processing,
      'ready' => DocumentOcrStatus.ready,
      'failed' => DocumentOcrStatus.failed,
      'notAvailable' => DocumentOcrStatus.notAvailable,
      _ => DocumentOcrStatus.notRequested,
    };
  }
}

class DocumentCaptureResult {
  const DocumentCaptureResult({
    required this.imagePaths,
    required this.source,
    this.pdfPath,
    this.thumbnailPath,
    this.mimeType,
    this.pageCount,
    this.fileSize,
  });

  final List<String> imagePaths;
  final String? pdfPath;
  final String? thumbnailPath;
  final String? mimeType;
  final DocumentCaptureSource source;
  final int? pageCount;
  final int? fileSize;

  String? get primaryFilePath {
    if (pdfPath != null) return pdfPath;
    if (imagePaths.isNotEmpty) return imagePaths.first;
    return null;
  }
}

class OcrResult {
  const OcrResult({
    required this.status,
    required this.language,
    this.text,
    this.error,
  });

  final DocumentOcrStatus status;
  final String language;
  final String? text;
  final String? error;
}
