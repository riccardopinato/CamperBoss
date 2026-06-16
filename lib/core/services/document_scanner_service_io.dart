import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'
    as mlkit;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'document_scan_result.dart';

abstract interface class DocumentScannerService {
  Future<DocumentScanResult?> scan({
    int pageLimit = 25,
    bool runOcr = false,
  });

  Future<DocumentScanResult?> importLocalFile({bool runOcr = false});
}

DocumentScannerService createDocumentScannerService() {
  return NativeDocumentScannerService();
}

class NativeDocumentScannerService implements DocumentScannerService {
  @override
  Future<DocumentScanResult?> scan({
    int pageLimit = 25,
    bool runOcr = false,
  }) async {
    if (Platform.isAndroid) {
      return _scanAndroid(pageLimit: pageLimit, runOcr: runOcr);
    }
    if (Platform.isIOS) {
      return _scanIos(pageLimit: pageLimit, runOcr: runOcr);
    }
    throw UnsupportedError('Document scanning is available on Android and iOS');
  }

  @override
  Future<DocumentScanResult?> importLocalFile({bool runOcr = false}) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (picked == null || picked.files.isEmpty) return null;

    final pages = <String>[];
    String? pdfPath;
    for (final file in picked.files) {
      final path = file.path;
      if (path == null) continue;
      final extension = p.extension(path).toLowerCase();
      final stored = await _copyToPrivateDocuments(File(path));
      if (extension == '.pdf') {
        pdfPath ??= stored;
      } else {
        pages.add(stored);
      }
    }

    final ocrText = runOcr ? await _recognizePages(pages) : null;
    return DocumentScanResult(
      pagePaths: pages,
      pdfPath: pdfPath,
      source: 'import',
      ocrText: ocrText,
    );
  }

  Future<DocumentScanResult?> _scanAndroid({
    required int pageLimit,
    required bool runOcr,
  }) async {
    final scanner = mlkit.DocumentScanner(
      options: mlkit.DocumentScannerOptions(
        documentFormats: const {
          mlkit.DocumentFormat.jpeg,
          mlkit.DocumentFormat.pdf,
        },
        pageLimit: pageLimit,
        mode: mlkit.ScannerMode.full,
        isGalleryImport: true,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      final pages = <String>[];
      for (final imagePath in result.images ?? const <String>[]) {
        pages.add(await _copyPathOrUriToPrivateDocuments(imagePath));
      }
      final pdfPath = result.pdf?.uri == null
          ? null
          : await _copyPathOrUriToPrivateDocuments(result.pdf!.uri);
      final ocrText = runOcr ? await _recognizePages(pages) : null;
      return DocumentScanResult(
        pagePaths: pages,
        pdfPath: pdfPath,
        source: 'mlkit_scan',
        ocrText: ocrText,
      );
    } finally {
      await scanner.close();
    }
  }

  Future<DocumentScanResult?> _scanIos({
    required int pageLimit,
    required bool runOcr,
  }) async {
    final images = await CunningDocumentScanner.getPictures(
      noOfPages: pageLimit,
      iosScannerOptions: const IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.9,
      ),
    );
    if (images == null || images.isEmpty) return null;

    final pages = <String>[];
    for (final imagePath in images) {
      pages.add(await _copyPathOrUriToPrivateDocuments(imagePath));
    }
    final pdfPath = await _createPdfFromImages(pages);
    final ocrText = runOcr ? await _recognizePages(pages) : null;
    return DocumentScanResult(
      pagePaths: pages,
      pdfPath: pdfPath,
      source: 'visionkit_scan',
      ocrText: ocrText,
    );
  }

  Future<String> _copyToPrivateDocuments(File file) async {
    final directory = await _documentDirectory();
    final extension = p.extension(file.path).toLowerCase();
    final name = 'doc_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(directory.path, name));
    await file.copy(target.path);
    return target.path;
  }

  Future<String> _copyPathOrUriToPrivateDocuments(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return _copyToPrivateDocuments(File(uri.toFilePath()));
    }
    return _copyToPrivateDocuments(File(value));
  }

  Future<String> _createPdfFromImages(List<String> pagePaths) async {
    final directory = await _documentDirectory();
    final pdf = pw.Document();
    for (final path in pagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(child: pw.Image(image)),
        ),
      );
    }
    final target = File(
      p.join(
        directory.path,
        'scan_${DateTime.now().microsecondsSinceEpoch}.pdf',
      ),
    );
    await target.writeAsBytes(await pdf.save());
    return target.path;
  }

  Future<String?> _recognizePages(List<String> pagePaths) async {
    if (pagePaths.isEmpty) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final texts = <String>[];
    try {
      for (final path in pagePaths) {
        final inputImage = InputImage.fromFilePath(path);
        final recognized = await recognizer.processImage(inputImage);
        final text = recognized.text.trim();
        if (text.isNotEmpty) texts.add(text);
      }
    } finally {
      await recognizer.close();
    }
    if (texts.isEmpty) return null;
    return texts.join('\n\n');
  }

  Future<Directory> _documentDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'vehicle_documents'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
