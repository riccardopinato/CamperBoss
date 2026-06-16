import 'package:camperboss/core/services/document_capture_service.dart';
import 'package:camperboss/core/services/document_ocr_service.dart';
import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/features/documents/presentation/vehicle_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVehicleDocumentRepository implements VehicleDocumentRepository {
  final documents = <VehicleDocument>[];
  final deletedFiles = <String>[];

  @override
  Future<void> deleteDocument(VehicleDocument document) async {
    deletedFiles.addAll(document.filePaths);
    documents.removeWhere((item) => item.id == document.id);
  }

  @override
  Future<List<VehicleDocument>> listDocuments() async => documents;

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async {
    final saved = document.copyWith(id: document.id ?? documents.length + 1);
    final index = documents.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      documents.add(saved);
    } else {
      documents[index] = saved;
    }
    return saved;
  }
}

class FakeDocumentCaptureService implements DocumentCaptureService {
  FakeDocumentCaptureService({this.canScanDocuments = true});

  @override
  final bool canScanDocuments;

  @override
  Future<DocumentCaptureResult?> importImages() async {
    return const DocumentCaptureResult(
      imagePaths: ['/private/imported.jpg'],
      thumbnailPath: '/private/imported.jpg',
      source: DocumentCaptureSource.imageImport,
      pageCount: 1,
    );
  }

  @override
  Future<DocumentCaptureResult?> importPdf() async {
    return const DocumentCaptureResult(
      imagePaths: [],
      pdfPath: '/private/imported.pdf',
      source: DocumentCaptureSource.pdfImport,
      pageCount: 1,
      mimeType: 'application/pdf',
    );
  }

  @override
  Future<DocumentCaptureResult?> scanDocument() async {
    return const DocumentCaptureResult(
      imagePaths: ['/private/page-1.jpg', '/private/page-2.jpg'],
      pdfPath: '/private/scan.pdf',
      thumbnailPath: '/private/page-1.jpg',
      source: DocumentCaptureSource.androidScanner,
      pageCount: 2,
    );
  }
}

class FakeDocumentOcrService implements DocumentOcrService {
  FakeDocumentOcrService({
    this.isSupported = true,
    this.status = DocumentOcrStatus.ready,
  });

  @override
  final bool isSupported;

  final DocumentOcrStatus status;

  @override
  Future<OcrResult> recognizeImages(List<String> imagePaths) async {
    return OcrResult(
      status: status,
      text: status == DocumentOcrStatus.ready ? 'Insurance expires 2027' : null,
      language: 'latin',
      error: status == DocumentOcrStatus.failed ? 'OCR failed' : null,
    );
  }
}

void main() {
  testWidgets('documents screen saves scan metadata and OCR text',
      (tester) async {
    final repository = FakeVehicleDocumentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleDocumentsScreen(
            repository: repository,
            captureService: FakeDocumentCaptureService(),
            ocrService: FakeDocumentOcrService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('document_add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('document_action_scan'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Insurance 2026');
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(find.text('Insurance 2026'), findsOneWidget);
    expect(repository.documents.single.extractedText, 'Insurance expires 2027');
    expect(repository.documents.single.ocrStatus, DocumentOcrStatus.ready);
    expect(repository.documents.single.pageCount, 2);
    expect(repository.documents.single.pdfPath, '/private/scan.pdf');
  });

  testWidgets('documents screen disables scanner when unsupported',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleDocumentsScreen(
            repository: FakeVehicleDocumentRepository(),
            captureService: FakeDocumentCaptureService(canScanDocuments: false),
            ocrService: FakeDocumentOcrService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('document_add'));
    await tester.pumpAndSettle();

    final scanTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'document_action_scan'),
    );
    expect(scanTile.enabled, isFalse);
    expect(find.text('document_scan_unavailable'), findsOneWidget);
  });
}
