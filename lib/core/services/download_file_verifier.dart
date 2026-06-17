import 'dart:io';

import 'package:crypto/crypto.dart';

class DownloadFileVerifier {
  const DownloadFileVerifier();

  Future<String> sha256ForFile(File file) async {
    final input = file.openRead();
    final digest = await sha256.bind(input).first;
    return digest.toString();
  }

  Future<DownloadVerificationResult> verify({
    required File file,
    required int expectedBytes,
    required String expectedSha256,
  }) async {
    if (!await file.exists()) {
      return const DownloadVerificationResult(
        valid: false,
        error: 'Downloaded file is missing',
      );
    }

    final size = await file.length();
    if (expectedBytes > 0 && size != expectedBytes) {
      return DownloadVerificationResult(
        valid: false,
        error: 'Downloaded file has unexpected size',
        actualSha256: expectedSha256.isEmpty ? null : await sha256ForFile(file),
      );
    }

    if (expectedSha256.isEmpty) {
      return const DownloadVerificationResult(valid: true);
    }

    final actual = await sha256ForFile(file);
    return DownloadVerificationResult(
      valid: actual.toLowerCase() == expectedSha256.toLowerCase(),
      actualSha256: actual,
      error: actual.toLowerCase() == expectedSha256.toLowerCase()
          ? null
          : 'Downloaded file hash does not match',
    );
  }
}

class DownloadVerificationResult {
  const DownloadVerificationResult({
    required this.valid,
    this.actualSha256,
    this.error,
  });

  final bool valid;
  final String? actualSha256;
  final String? error;
}
