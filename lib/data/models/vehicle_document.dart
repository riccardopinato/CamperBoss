import 'dart:convert';

import '../../core/services/document_services_models.dart';

class VehicleDocument {
  const VehicleDocument({
    required this.category,
    required this.title,
    required this.localFilePath,
    required this.mimeType,
    required this.ocrStatus,
    this.id,
    this.vehicleId,
    this.thumbnailPath,
    this.pagePaths = const [],
    this.pdfPath,
    this.pageCount = 1,
    this.fileSize,
    this.extractedText,
    this.ocrLanguage,
    this.processingError,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? vehicleId;
  final String category;
  final String title;
  final String localFilePath;
  final String? thumbnailPath;
  final List<String> pagePaths;
  final String? pdfPath;
  final String mimeType;
  final int pageCount;
  final int? fileSize;
  final String? extractedText;
  final String? ocrLanguage;
  final DocumentOcrStatus ocrStatus;
  final String? processingError;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get name => title;
  String? get ocrText => extractedText;
  String get source => mimeType == 'application/pdf' ? 'pdf_import' : 'image';

  VehicleDocument copyWith({
    int? id,
    int? vehicleId,
    String? category,
    String? title,
    String? localFilePath,
    String? thumbnailPath,
    List<String>? pagePaths,
    String? pdfPath,
    String? mimeType,
    int? pageCount,
    int? fileSize,
    String? extractedText,
    String? ocrLanguage,
    DocumentOcrStatus? ocrStatus,
    String? processingError,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      category: category ?? this.category,
      title: title ?? this.title,
      localFilePath: localFilePath ?? this.localFilePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pagePaths: pagePaths ?? this.pagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      mimeType: mimeType ?? this.mimeType,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      extractedText: extractedText ?? this.extractedText,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      processingError: processingError ?? this.processingError,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get filePaths {
    return {
      localFilePath,
      if (thumbnailPath != null) thumbnailPath!,
      if (pdfPath != null) pdfPath!,
      ...pagePaths,
    }.toList();
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return title.toLowerCase().contains(normalized) ||
        category.toLowerCase().contains(normalized) ||
        (notes ?? '').toLowerCase().contains(normalized) ||
        (extractedText ?? '').toLowerCase().contains(normalized);
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'category': category,
      'name': title,
      'title': title,
      'local_file_path': localFilePath,
      'thumbnail_path': thumbnailPath,
      'page_paths': jsonEncode(pagePaths),
      'pdf_path': pdfPath,
      'mime_type': mimeType,
      'page_count': pageCount,
      'file_size': fileSize,
      'ocr_text': extractedText,
      'extracted_text': extractedText,
      'ocr_language': ocrLanguage,
      'ocr_status': ocrStatus.storageValue,
      'processing_error': processingError,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'source': source,
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': (updatedAt ?? now).toIso8601String(),
    };
  }

  factory VehicleDocument.fromMap(Map<String, Object?> map) {
    final pagePaths = _decodePaths(map['page_paths']);
    final pdfPath = map['pdf_path'] as String?;
    final localFilePath = map['local_file_path'] as String? ??
        pdfPath ??
        (pagePaths.isEmpty ? '' : pagePaths.first);
    final title = map['title'] as String? ?? map['name'] as String;
    final extractedText =
        map['extracted_text'] as String? ?? map['ocr_text'] as String?;

    return VehicleDocument(
      id: map['id'] as int?,
      vehicleId: (map['vehicle_id'] as num?)?.toInt(),
      category: map['category'] as String,
      title: title,
      localFilePath: localFilePath,
      thumbnailPath: map['thumbnail_path'] as String?,
      pagePaths: pagePaths,
      pdfPath: pdfPath,
      mimeType: map['mime_type'] as String? ??
          (pdfPath == null ? 'image/jpeg' : 'application/pdf'),
      pageCount: (map['page_count'] as num?)?.toInt() ??
          (pagePaths.isEmpty ? 1 : pagePaths.length),
      fileSize: (map['file_size'] as num?)?.toInt(),
      extractedText: extractedText,
      ocrLanguage: map['ocr_language'] as String?,
      ocrStatus: DocumentOcrStatus.fromStorage(map['ocr_status'] as String?),
      processingError: map['processing_error'] as String?,
      issueDate: DateTime.tryParse(map['issue_date'] as String? ?? ''),
      expiryDate: DateTime.tryParse(map['expiry_date'] as String? ?? ''),
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static List<String> _decodePaths(Object? value) {
    if (value == null) return const [];
    if (value is List) return value.whereType<String>().toList();
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.whereType<String>().toList();
  }
}
