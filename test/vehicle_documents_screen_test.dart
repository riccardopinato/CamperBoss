import 'package:camperboss/core/services/document_scan_result.dart';
import 'package:camperboss/core/services/document_scanner_service.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/features/documents/presentation/vehicle_documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVehicleDocumentRepository implements VehicleDocumentRepository {
  final documents = <VehicleDocument>[];

  @override
  Future<void> deleteDocument(int id) async {
    documents.removeWhere((document) => document.id == id);
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

class FakeDocumentScannerService implements DocumentScannerService {
  @override
  Future<DocumentScanResult?> importLocalFile({bool runOcr = false}) async {
    return const DocumentScanResult(
      pagePaths: ['/private/imported.jpg'],
      pdfPath: '/private/imported.pdf',
      source: 'import',
    );
  }

  @override
  Future<DocumentScanResult?> scan({
    int pageLimit = 25,
    bool runOcr = false,
  }) async {
    return DocumentScanResult(
      pagePaths: const ['/private/page-1.jpg', '/private/page-2.jpg'],
      pdfPath: '/private/scan.pdf',
      source: 'mlkit_scan',
      ocrText: runOcr ? 'Insurance expires 2027' : null,
    );
  }
}

void main() {
  testWidgets('documents screen confirms OCR before saving scan metadata',
      (tester) async {
    final repository = FakeVehicleDocumentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleDocumentsScreen(
            repository: repository,
            scannerService: FakeDocumentScannerService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Use extracted text?'), findsOneWidget);
    await tester.tap(find.text('Use text'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Insurance 2026');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Insurance 2026'), findsOneWidget);
    expect(repository.documents.single.ocrText, 'Insurance expires 2027');
    expect(repository.documents.single.pagePaths.length, 2);
    expect(repository.documents.single.pdfPath, '/private/scan.pdf');
  });
}
