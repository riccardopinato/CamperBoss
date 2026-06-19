enum SearchDocumentType {
  vehicleDocument,
  maintenance,
  journal,
  trip,
  booking,
  offlineGuide,
  vehicleNote,
}

enum SearchIndexStatus {
  empty,
  ready,
  rebuilding,
  corrupted,
}

const camperSearchAliases = {
  'libretto': ['carta di circolazione'],
  'tagliando': ['manutenzione programmata'],
  'bombola': ['gas', 'gpl'],
  'acque grigie': ['serbatoio scarico'],
};

class SearchDocument {
  const SearchDocument({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.metadata,
    required this.updatedAt,
  });

  final String id;
  final SearchDocumentType type;
  final String sourceId;
  final String title;
  final String body;
  final Map<String, String> metadata;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.name,
      'sourceId': sourceId,
      'title': title,
      'body': body,
      'metadata': metadata,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SearchDocument.fromMap(Map<String, Object?> map) {
    return SearchDocument(
      id: map['id'] as String,
      type: SearchDocumentType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => SearchDocumentType.journal,
      ),
      sourceId: map['sourceId'] as String,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      metadata: Map<String, String>.from(map['metadata'] as Map? ?? const {}),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class SearchHit {
  const SearchHit({
    required this.sourceId,
    required this.type,
    required this.title,
    required this.snippet,
    required this.score,
    required this.updatedAt,
    this.metadata = const {},
  });

  final String sourceId;
  final SearchDocumentType type;
  final String title;
  final String snippet;
  final double score;
  final DateTime updatedAt;
  final Map<String, String> metadata;
}

class SearchIndexSnapshot {
  const SearchIndexSnapshot({
    required this.status,
    required this.version,
    required this.documentCount,
    this.lastRebuiltAt,
    this.lastError,
  });

  final SearchIndexStatus status;
  final int version;
  final int documentCount;
  final DateTime? lastRebuiltAt;
  final String? lastError;
}

class KnowledgeCitation {
  const KnowledgeCitation({
    required this.sourceId,
    required this.title,
    required this.excerpt,
  });

  final String sourceId;
  final String title;
  final String excerpt;
}

class KnowledgeAnswer {
  const KnowledgeAnswer({
    required this.text,
    required this.citations,
  });

  final String text;
  final List<KnowledgeCitation> citations;
}

class KnowledgeAssistantUnavailable implements Exception {
  const KnowledgeAssistantUnavailable();
}
