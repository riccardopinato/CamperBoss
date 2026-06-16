class DocumentScanResult {
  const DocumentScanResult({
    required this.pagePaths,
    required this.source,
    this.pdfPath,
    this.ocrText,
  });

  final List<String> pagePaths;
  final String? pdfPath;
  final String source;
  final String? ocrText;

  bool get hasFiles => pagePaths.isNotEmpty || pdfPath != null;
}
