import 'dart:convert';

class VehicleDocument {
  const VehicleDocument({
    required this.category,
    required this.name,
    required this.pagePaths,
    required this.source,
    this.id,
    this.pdfPath,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.ocrText,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String category;
  final String name;
  final List<String> pagePaths;
  final String? pdfPath;
  final String source;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final String? ocrText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocument copyWith({
    int? id,
    String? category,
    String? name,
    List<String>? pagePaths,
    String? pdfPath,
    String? source,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    String? ocrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      pagePaths: pagePaths ?? this.pagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      source: source ?? this.source,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'category': category,
      'name': name,
      'page_paths': jsonEncode(pagePaths),
      'pdf_path': pdfPath,
      'source': source,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'ocr_text': ocrText,
      'created_at': (createdAt ?? now).toIso8601String(),
      'updated_at': (updatedAt ?? now).toIso8601String(),
    };
  }

  factory VehicleDocument.fromMap(Map<String, Object?> map) {
    return VehicleDocument(
      id: map['id'] as int?,
      category: map['category'] as String,
      name: map['name'] as String,
      pagePaths: _decodePaths(map['page_paths']),
      pdfPath: map['pdf_path'] as String?,
      source: map['source'] as String? ?? 'manual',
      issueDate: DateTime.tryParse(map['issue_date'] as String? ?? ''),
      expiryDate: DateTime.tryParse(map['expiry_date'] as String? ?? ''),
      notes: map['notes'] as String?,
      ocrText: map['ocr_text'] as String?,
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
