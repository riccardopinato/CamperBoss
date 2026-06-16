import 'document_scan_result.dart';

abstract interface class DocumentScannerService {
  Future<DocumentScanResult?> scan({
    int pageLimit = 25,
    bool runOcr = false,
  });

  Future<DocumentScanResult?> importLocalFile({bool runOcr = false});
}

DocumentScannerService createDocumentScannerService() {
  return UnsupportedDocumentScannerService();
}

class UnsupportedDocumentScannerService implements DocumentScannerService {
  @override
  Future<DocumentScanResult?> importLocalFile({bool runOcr = false}) {
    throw UnsupportedError('Document import is not available on this platform');
  }

  @override
  Future<DocumentScanResult?> scan({
    int pageLimit = 25,
    bool runOcr = false,
  }) {
    throw UnsupportedError(
        'Document scanning is not available on this platform');
  }
}
