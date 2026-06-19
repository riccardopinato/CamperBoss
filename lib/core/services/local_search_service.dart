import 'dart:convert';

import '../../data/database/local_key_value_store.dart';
import '../../data/models/search_models.dart';
import '../../data/models/vehicle_profile.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_journal_repository.dart';
import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_trip_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import '../../data/repositories/local_vehicle_profile_repository.dart';
import 'offline_guides_service.dart';

abstract interface class LocalSearchIndex {
  Future<void> index(SearchDocument document);
  Future<void> remove(String id);
  Future<void> rebuild();
  Future<List<SearchHit>> search(
    String query, {
    Set<SearchDocumentType>? types,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    int limit = 50,
  });
  Future<SearchIndexSnapshot> snapshot();
}

abstract interface class KnowledgeAssistantGateway {
  Future<KnowledgeAnswer> ask({
    required String question,
    required List<SearchHit> localContext,
  });
}

class DisabledKnowledgeAssistantGateway implements KnowledgeAssistantGateway {
  const DisabledKnowledgeAssistantGateway();

  @override
  Future<KnowledgeAnswer> ask({
    required String question,
    required List<SearchHit> localContext,
  }) {
    throw const KnowledgeAssistantUnavailable();
  }
}

class LocalSearchService implements LocalSearchIndex {
  LocalSearchService({
    LocalSearchIndex? index,
    LocalSearchDocumentSource? source,
  }) : _source = source ?? LocalSearchDocumentSource() {
    _index =
        index ?? PersistentLocalSearchIndex(documentLoader: _source.loadAll);
  }

  late final LocalSearchIndex _index;
  final LocalSearchDocumentSource _source;

  @override
  Future<void> index(SearchDocument document) => _index.index(document);

  @override
  Future<void> remove(String id) => _index.remove(id);

  @override
  Future<void> rebuild() => _index.rebuild();

  Future<void> rebuildFromSources() async {
    await PersistentLocalSearchIndex(
      documentLoader: _source.loadAll,
    ).rebuild();
    await _index.rebuild();
  }

  @override
  Future<List<SearchHit>> search(
    String query, {
    Set<SearchDocumentType>? types,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    int limit = 50,
  }) {
    return _index.search(
      query,
      types: types,
      updatedAfter: updatedAfter,
      updatedBefore: updatedBefore,
      limit: limit,
    );
  }

  @override
  Future<SearchIndexSnapshot> snapshot() => _index.snapshot();
}

class PersistentLocalSearchIndex implements LocalSearchIndex {
  PersistentLocalSearchIndex({
    LocalKeyValueStore? store,
    Future<List<SearchDocument>> Function()? documentLoader,
    int version = 1,
  })  : _store = store ?? createLocalKeyValueStore(),
        _documentLoader = documentLoader,
        _version = version;

  static const _documentsKey = 'camperboss.search.documents';
  static const _statusKey = 'camperboss.search.status';

  final LocalKeyValueStore _store;
  final Future<List<SearchDocument>> Function()? _documentLoader;
  final int _version;
  Map<String, SearchDocument>? _documents;
  SearchIndexStatus _status = SearchIndexStatus.empty;
  String? _lastError;
  DateTime? _lastRebuiltAt;

  @override
  Future<void> index(SearchDocument document) async {
    final documents = await _loadDocuments();
    documents[document.id] = document;
    _status = SearchIndexStatus.ready;
    await _persist();
  }

  @override
  Future<void> remove(String id) async {
    final documents = await _loadDocuments();
    documents.remove(id);
    _status =
        documents.isEmpty ? SearchIndexStatus.empty : SearchIndexStatus.ready;
    await _persist();
  }

  @override
  Future<void> rebuild() async {
    final loader = _documentLoader;
    if (loader == null) return;
    _status = SearchIndexStatus.rebuilding;
    _lastError = null;
    await _persistStatus();
    try {
      final loaded = await loader();
      _documents = {for (final document in loaded) document.id: document};
      _status =
          loaded.isEmpty ? SearchIndexStatus.empty : SearchIndexStatus.ready;
      _lastRebuiltAt = DateTime.now();
      await _persist();
    } catch (error) {
      _status = SearchIndexStatus.corrupted;
      _lastError = 'Search index rebuild failed';
      await _persistStatus();
      rethrow;
    }
  }

  @override
  Future<List<SearchHit>> search(
    String query, {
    Set<SearchDocumentType>? types,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    int limit = 50,
  }) async {
    final terms = _expandQuery(query);
    final documents = (await _loadDocuments()).values.where((document) {
      if (types != null && !types.contains(document.type)) return false;
      if (updatedAfter != null && document.updatedAt.isBefore(updatedAfter)) {
        return false;
      }
      if (updatedBefore != null && document.updatedAt.isAfter(updatedBefore)) {
        return false;
      }
      return true;
    });

    final hits = <SearchHit>[];
    for (final document in documents) {
      final score = terms.isEmpty ? 0.1 : _score(document, terms);
      if (score <= 0) continue;
      hits.add(
        SearchHit(
          sourceId: document.sourceId,
          type: document.type,
          title: document.title,
          snippet: _snippet(document, terms),
          score: score,
          updatedAt: document.updatedAt,
          metadata: document.metadata,
        ),
      );
    }
    hits.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return hits.take(limit).toList(growable: false);
  }

  @override
  Future<SearchIndexSnapshot> snapshot() async {
    final documents = await _loadDocuments();
    return SearchIndexSnapshot(
      status: _status,
      version: _version,
      documentCount: documents.length,
      lastRebuiltAt: _lastRebuiltAt,
      lastError: _lastError,
    );
  }

  Future<Map<String, SearchDocument>> _loadDocuments() async {
    final existing = _documents;
    if (existing != null) return existing;

    try {
      final raw = await _store.read(_documentsKey);
      final statusRaw = await _store.read(_statusKey);
      if (statusRaw != null && statusRaw.isNotEmpty) {
        final status = Map<String, Object?>.from(jsonDecode(statusRaw) as Map);
        _status = SearchIndexStatus.values.firstWhere(
          (value) => value.name == status['status'],
          orElse: () => SearchIndexStatus.empty,
        );
        _lastError = status['lastError'] as String?;
        _lastRebuiltAt =
            DateTime.tryParse(status['lastRebuiltAt'] as String? ?? '');
      }
      if (raw == null || raw.isEmpty) return _documents = {};
      final decoded = jsonDecode(raw) as List<dynamic>;
      final documents = decoded.map((item) {
        return SearchDocument.fromMap(Map<String, Object?>.from(item as Map));
      });
      return _documents = {
        for (final document in documents) document.id: document
      };
    } catch (_) {
      _documents = {};
      _status = SearchIndexStatus.corrupted;
      _lastError = 'Search index storage is corrupted';
      await _persistStatus();
      return _documents!;
    }
  }

  Future<void> _persist() async {
    final documents = _documents ?? {};
    if (documents.isEmpty) {
      await _store.remove(_documentsKey);
    } else {
      await _store.write(
        _documentsKey,
        jsonEncode(documents.values.map((item) => item.toMap()).toList()),
      );
    }
    await _persistStatus();
  }

  Future<void> _persistStatus() async {
    await _store.write(
      _statusKey,
      jsonEncode({
        'status': _status.name,
        'version': _version,
        'lastRebuiltAt': _lastRebuiltAt?.toIso8601String(),
        'lastError': _lastError,
      }),
    );
  }

  Set<String> _expandQuery(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return {};
    final terms = <String>{normalized, ...normalized.split(' ')};
    for (final entry in camperSearchAliases.entries) {
      if (normalized.contains(entry.key)) terms.addAll(entry.value);
      for (final alias in entry.value) {
        if (normalized.contains(alias)) terms.add(entry.key);
      }
    }
    terms.removeWhere((item) => item.trim().isEmpty);
    return terms;
  }

  double _score(SearchDocument document, Set<String> terms) {
    final title = _normalize(document.title);
    final body = _normalize(document.body);
    final metadata = _normalize(document.metadata.values.join(' '));
    var score = 0.0;
    for (final term in terms) {
      if (title == term) score += 12;
      if (title.contains(term)) score += 8;
      if (metadata.contains(term)) score += 3;
      if (body.contains(term)) score += 2;
    }
    return score;
  }

  String _snippet(SearchDocument document, Set<String> terms) {
    final text = '${document.title}. ${document.body}'.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (terms.isEmpty) return _truncate(text);
    final lower = _normalize(text);
    final term = terms.firstWhere(
      (item) => lower.contains(item),
      orElse: () => '',
    );
    if (term.isEmpty) return _truncate(text);
    final index = lower.indexOf(term);
    final start = (index - 48).clamp(0, text.length);
    final end = (index + term.length + 96).clamp(0, text.length);
    final snippet = text.substring(start, end).trim();
    return '${start > 0 ? '...' : ''}$snippet${end < text.length ? '...' : ''}';
  }

  String _truncate(String value) {
    if (value.length <= 160) return value;
    return '${value.substring(0, 157)}...';
  }

  String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class LocalSearchDocumentSource {
  LocalSearchDocumentSource({
    VehicleDocumentRepository? documentRepository,
    MaintenanceRepository? maintenanceRepository,
    JournalRepository? journalRepository,
    TripRepository? tripRepository,
    FinanceRepository? financeRepository,
    VehicleProfileRepository? vehicleProfileRepository,
    OfflineGuidesService? guidesService,
  })  : _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _journalRepository = journalRepository ?? LocalJournalRepository(),
        _tripRepository = tripRepository ?? LocalTripRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository(),
        _vehicleProfileRepository =
            vehicleProfileRepository ?? LocalVehicleProfileRepository(),
        _guidesService = guidesService ?? LocalOfflineGuidesService();

  final VehicleDocumentRepository _documentRepository;
  final MaintenanceRepository _maintenanceRepository;
  final JournalRepository _journalRepository;
  final TripRepository _tripRepository;
  final FinanceRepository _financeRepository;
  final VehicleProfileRepository _vehicleProfileRepository;
  final OfflineGuidesService _guidesService;

  Future<List<SearchDocument>> loadAll() async {
    final results = <SearchDocument>[];
    results.addAll(await _vehicleDocuments());
    results.addAll(await _maintenance());
    results.addAll(await _journal());
    results.addAll(await _trips());
    results.addAll(await _bookings());
    results.addAll(await _guides());
    final profile = await _vehicleProfile();
    if (profile != null) results.add(profile);
    return results;
  }

  Future<List<SearchDocument>> _vehicleDocuments() async {
    final documents = await _documentRepository.listDocuments();
    return [
      for (final document in documents)
        SearchDocument(
          id: 'vehicleDocument:${document.id}',
          type: SearchDocumentType.vehicleDocument,
          sourceId: (document.id ?? document.localFilePath).toString(),
          title: document.title,
          body: [
            document.category,
            document.notes,
            document.extractedText,
            document.ocrLanguage,
          ].nonNulls.join('\n'),
          metadata: {
            'category': document.category,
            'mimeType': document.mimeType,
            if (document.expiryDate != null)
              'expiryDate': document.expiryDate!.toIso8601String(),
          },
          updatedAt: document.updatedAt ?? document.createdAt ?? DateTime.now(),
        ),
    ];
  }

  Future<List<SearchDocument>> _maintenance() async {
    final records = await _maintenanceRepository.listRecords();
    return [
      for (final record in records)
        SearchDocument(
          id: 'maintenance:${record.id}',
          type: SearchDocumentType.maintenance,
          sourceId: (record.id ?? record.title).toString(),
          title: record.title,
          body: [
            record.category,
            record.provider,
            record.notes,
            record.status().label,
          ].nonNulls.join('\n'),
          metadata: {'category': record.category},
          updatedAt: record.updatedAt ?? record.createdAt ?? record.date,
        ),
    ];
  }

  Future<List<SearchDocument>> _journal() async {
    final entries = await _journalRepository.listEntries();
    return [
      for (final entry in entries)
        SearchDocument(
          id: 'journal:${entry.id}',
          type: SearchDocumentType.journal,
          sourceId: (entry.id ?? entry.title).toString(),
          title: entry.title,
          body: [entry.summary, entry.place].nonNulls.join('\n'),
          metadata: {if (entry.place != null) 'place': entry.place!},
          updatedAt: entry.updatedAt ?? entry.createdAt ?? DateTime.now(),
        ),
    ];
  }

  Future<List<SearchDocument>> _trips() async {
    final trips = await _tripRepository.listTrips();
    return [
      for (final trip in trips)
        SearchDocument(
          id: 'trip:${trip.id}',
          type: SearchDocumentType.trip,
          sourceId: (trip.id ?? trip.title).toString(),
          title: trip.title,
          body: [
            trip.summary,
            trip.destination,
            trip.overnightStop,
            trip.notes,
            ...trip.stages,
          ].nonNulls.join('\n'),
          metadata: {
            if (trip.destination != null) 'destination': trip.destination!,
          },
          updatedAt: trip.updatedAt ?? DateTime.now(),
        ),
    ];
  }

  Future<List<SearchDocument>> _bookings() async {
    final bookings = await _financeRepository.listBookings();
    return [
      for (final booking in bookings)
        SearchDocument(
          id: 'booking:${booking.id}',
          type: SearchDocumentType.booking,
          sourceId: booking.id,
          title: booking.title,
          body: [
            booking.type.name,
            booking.status.name,
            booking.address,
            booking.bookingCode,
            booking.contact,
            booking.notes,
          ].nonNulls.join('\n'),
          metadata: {
            'type': booking.type.name,
            'status': booking.status.name,
            'tripId': booking.tripId.toString(),
          },
          updatedAt: booking.startsAt ?? booking.endsAt ?? DateTime.now(),
        ),
    ];
  }

  Future<List<SearchDocument>> _guides() async {
    final packages = await _guidesService.listInstalledPackages();
    final documents = <SearchDocument>[];
    for (final package in packages) {
      for (final entry in package.entries) {
        final document =
            await _guidesService.loadDocument(package.id, entry.id);
        documents.add(
          SearchDocument(
            id: 'offlineGuide:${package.id}:${entry.id}',
            type: SearchDocumentType.offlineGuide,
            sourceId: '${package.id}:${entry.id}',
            title: document.title,
            body: _plainText(document.content),
            metadata: {
              'packageId': package.id,
              'packageTitle': package.title,
              'contentType': document.contentType.name,
              'attribution': document.attribution,
            },
            updatedAt: package.updatedAt,
          ),
        );
      }
    }
    return documents;
  }

  Future<SearchDocument?> _vehicleProfile() async {
    final profile = await _vehicleProfileRepository.loadProfile();
    if (profile == null) return null;
    return SearchDocument(
      id: 'vehicleNote:${profile.id ?? 'current'}',
      type: SearchDocumentType.vehicleNote,
      sourceId: (profile.id ?? 'current').toString(),
      title: '${profile.brand} ${profile.model}',
      body: _vehicleProfileBody(profile),
      metadata: {'vehicleType': profile.vehicleType},
      updatedAt: profile.updatedAt ?? DateTime.now(),
    );
  }

  String _vehicleProfileBody(VehicleProfile profile) {
    return [
      profile.vehicleType,
      profile.fuelType,
      profile.plate,
      profile.notes,
      '${profile.length}m x ${profile.width}m x ${profile.height}m',
      '${profile.maxMass}kg',
      '${profile.mileage}km',
    ].nonNulls.join('\n');
  }

  String _plainText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'[#*_`\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
