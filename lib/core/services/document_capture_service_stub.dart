import 'document_services_models.dart';

abstract interface class DocumentCaptureService {
  bool get canScanDocuments;

  Future<DocumentCaptureResult?> scanDocument();
  Future<DocumentCaptureResult?> importImages();
  Future<DocumentCaptureResult?> importPdf();
}

DocumentCaptureService createDocumentCaptureService() {
  return FallbackDocumentCaptureService();
}

class FallbackDocumentCaptureService implements DocumentCaptureService {
  @override
  bool get canScanDocuments => false;

  @override
  Future<DocumentCaptureResult?> importImages() async {
    throw UnsupportedError('document_error_platform_unsupported');
  }

  @override
  Future<DocumentCaptureResult?> importPdf() async {
    throw UnsupportedError('document_error_platform_unsupported');
  }

  @override
  Future<DocumentCaptureResult?> scanDocument() async {
    throw UnsupportedError('document_error_platform_unsupported');
  }
}
