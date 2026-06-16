import 'document_services_models.dart';

abstract interface class DocumentOcrService {
  bool get isSupported;

  Future<OcrResult> recognizeImages(List<String> imagePaths);
}

DocumentOcrService createDocumentOcrService() {
  return UnsupportedDocumentOcrService();
}

class UnsupportedDocumentOcrService implements DocumentOcrService {
  @override
  bool get isSupported => false;

  @override
  Future<OcrResult> recognizeImages(List<String> imagePaths) async {
    return const OcrResult(
      status: DocumentOcrStatus.notAvailable,
      language: 'latin',
    );
  }
}
