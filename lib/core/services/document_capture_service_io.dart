import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'
    as mlkit;
import 'package:path/path.dart' as p;

import 'document_services_models.dart';
import 'document_storage_service.dart';

abstract interface class DocumentCaptureService {
  bool get canScanDocuments;

  Future<DocumentCaptureResult?> scanDocument();
  Future<DocumentCaptureResult?> importImages();
  Future<DocumentCaptureResult?> importPdf();
}

DocumentCaptureService createDocumentCaptureService({
  DocumentStorageService? storageService,
}) {
  final storage = storageService ?? createDocumentStorageService();
  if (Platform.isAndroid) {
    return AndroidDocumentCaptureService(storageService: storage);
  }
  return FallbackDocumentCaptureService(storageService: storage);
}

class AndroidDocumentCaptureService implements DocumentCaptureService {
  AndroidDocumentCaptureService(
      {required DocumentStorageService storageService})
      : _storageService = storageService;

  final DocumentStorageService _storageService;

  @override
  bool get canScanDocuments => true;

  @override
  Future<DocumentCaptureResult?> scanDocument() async {
    final scanner = mlkit.DocumentScanner(
      options: mlkit.DocumentScannerOptions(
        documentFormats: const {
          mlkit.DocumentFormat.jpeg,
          mlkit.DocumentFormat.pdf,
        },
        pageLimit: 20,
        mode: mlkit.ScannerMode.full,
        isGalleryImport: true,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      final pages = <String>[];
      String? pdfPath;
      try {
        for (final path in result.images ?? const <String>[]) {
          pages.add(await _storageService.copyIntoPrivateDocuments(path));
        }
        if (result.pdf?.uri != null) {
          pdfPath = await _storageService.copyIntoPrivateDocuments(
            result.pdf!.uri,
          );
        }
        if (pages.isEmpty && pdfPath == null) return null;
        return DocumentCaptureResult(
          imagePaths: pages,
          pdfPath: pdfPath,
          thumbnailPath: pages.isEmpty ? null : pages.first,
          source: DocumentCaptureSource.androidScanner,
          pageCount: result.pdf?.pageCount ?? pages.length,
        );
      } catch (_) {
        await _storageService
            .deleteFiles([...pages, if (pdfPath != null) pdfPath]);
        rethrow;
      }
    } finally {
      await scanner.close();
    }
  }

  @override
  Future<DocumentCaptureResult?> importImages() {
    return _importImages(_storageService);
  }

  @override
  Future<DocumentCaptureResult?> importPdf() {
    return _importPdf(_storageService);
  }
}

class FallbackDocumentCaptureService implements DocumentCaptureService {
  FallbackDocumentCaptureService(
      {required DocumentStorageService storageService})
      : _storageService = storageService;

  final DocumentStorageService _storageService;

  @override
  bool get canScanDocuments => false;

  @override
  Future<DocumentCaptureResult?> importImages() {
    return _importImages(_storageService);
  }

  @override
  Future<DocumentCaptureResult?> importPdf() {
    return _importPdf(_storageService);
  }

  @override
  Future<DocumentCaptureResult?> scanDocument() async {
    throw UnsupportedError('document_error_platform_unsupported');
  }
}

Future<DocumentCaptureResult?> _importImages(
  DocumentStorageService storageService,
) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png'],
  );
  if (picked == null || picked.files.isEmpty) return null;

  final pages = <String>[];
  try {
    for (final file in picked.files) {
      final path = file.path;
      if (path == null) continue;
      pages.add(await storageService.copyIntoPrivateDocuments(path));
    }
    if (pages.isEmpty) return null;
    return DocumentCaptureResult(
      imagePaths: pages,
      thumbnailPath: pages.first,
      source: DocumentCaptureSource.imageImport,
      pageCount: pages.length,
    );
  } catch (_) {
    await storageService.deleteFiles(pages);
    rethrow;
  }
}

Future<DocumentCaptureResult?> _importPdf(
  DocumentStorageService storageService,
) async {
  final picked = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  final path = picked?.path;
  if (path == null) return null;

  final pdfPath = await storageService.copyIntoPrivateDocuments(path);
  return DocumentCaptureResult(
    imagePaths: const [],
    pdfPath: pdfPath,
    thumbnailPath: null,
    source: DocumentCaptureSource.pdfImport,
    pageCount: 1,
    fileSize: await File(pdfPath).length(),
    mimeType: _mimeType(pdfPath),
  );
}

String _mimeType(String path) {
  final extension = p.extension(path).toLowerCase();
  if (extension == '.pdf') return 'application/pdf';
  if (extension == '.png') return 'image/png';
  return 'image/jpeg';
}
