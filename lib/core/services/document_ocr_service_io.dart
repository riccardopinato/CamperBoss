import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'document_services_models.dart';

abstract interface class DocumentOcrService {
  bool get isSupported;

  Future<OcrResult> recognizeImages(List<String> imagePaths);
}

DocumentOcrService createDocumentOcrService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return MlKitDocumentOcrService();
  }
  return UnsupportedDocumentOcrService();
}

class MlKitDocumentOcrService implements DocumentOcrService {
  @override
  bool get isSupported => true;

  @override
  Future<OcrResult> recognizeImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return const OcrResult(
        status: DocumentOcrStatus.notAvailable,
        language: 'latin',
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final texts = <String>[];
    try {
      for (final path in imagePaths) {
        final recognized = await recognizer.processImage(
          InputImage.fromFilePath(path),
        );
        final text = recognized.text.trim();
        if (text.isNotEmpty) texts.add(text);
      }
    } catch (error) {
      return OcrResult(
        status: DocumentOcrStatus.failed,
        language: 'latin',
        error: error.toString(),
      );
    } finally {
      await recognizer.close();
    }

    if (texts.isEmpty) {
      return const OcrResult(
        status: DocumentOcrStatus.ready,
        text: '',
        language: 'latin',
      );
    }
    return OcrResult(
      status: DocumentOcrStatus.ready,
      text: texts.join('\n\n'),
      language: 'latin',
    );
  }
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
