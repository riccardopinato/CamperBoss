import 'package:camperboss/core/services/local_search_service.dart';
import 'package:camperboss/data/database/local_key_value_store.dart';
import 'package:camperboss/data/models/search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indexes updates removes and filters local documents', () async {
    final index = PersistentLocalSearchIndex(store: _MemoryStore());
    final now = DateTime(2026, 6, 19);

    await index.index(
      SearchDocument(
        id: 'doc:1',
        type: SearchDocumentType.vehicleDocument,
        sourceId: '1',
        title: 'Libretto camper',
        body: 'Carta di circolazione con massa e targa.',
        metadata: const {'category': 'registration'},
        updatedAt: now,
      ),
    );
    await index.index(
      SearchDocument(
        id: 'journal:1',
        type: SearchDocumentType.journal,
        sourceId: '1',
        title: 'Weekend in Liguria',
        body: 'Sosta vicino al mare.',
        metadata: const {},
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    );

    var hits = await index.search('carta di circolazione');
    expect(hits.single.title, 'Libretto camper');

    hits = await index.search(
      'mare',
      types: {SearchDocumentType.vehicleDocument},
    );
    expect(hits, isEmpty);

    await index.remove('journal:1');
    expect(await index.search('mare'), isEmpty);
  });

  test('rebuilds, ranks title matches, expands aliases and creates snippets',
      () async {
    final index = PersistentLocalSearchIndex(
      store: _MemoryStore(),
      documentLoader: () async => [
        SearchDocument(
          id: 'maintenance:1',
          type: SearchDocumentType.maintenance,
          sourceId: '1',
          title: 'Tagliando annuale',
          body: 'Olio, filtri e controllo generale.',
          metadata: const {},
          updatedAt: DateTime(2026, 6, 19),
        ),
        SearchDocument(
          id: 'guide:1',
          type: SearchDocumentType.offlineGuide,
          sourceId: 'guide',
          title: 'Gas in viaggio',
          body: 'La bombola deve essere chiusa durante il traghetto.',
          metadata: const {},
          updatedAt: DateTime(2026, 6, 18),
        ),
      ],
    );

    await index.rebuild();
    final snapshot = await index.snapshot();
    expect(snapshot.status, SearchIndexStatus.ready);
    expect(snapshot.documentCount, 2);

    final maintenance = await index.search('manutenzione programmata');
    expect(maintenance.first.type, SearchDocumentType.maintenance);

    final gas = await index.search('gpl');
    expect(gas.first.snippet, contains('bombola'));
  });

  test('marks corrupted storage and recovers after rebuild', () async {
    final store = _MemoryStore()
      ..values['camperboss.search.documents'] = '{not-json';
    final index = PersistentLocalSearchIndex(
      store: store,
      documentLoader: () async => [
        SearchDocument(
          id: 'trip:1',
          type: SearchDocumentType.trip,
          sourceId: '1',
          title: 'Dolomiti',
          body: 'Passi alpini e campeggio.',
          metadata: const {},
          updatedAt: DateTime(2026, 6, 19),
        ),
      ],
    );

    expect((await index.snapshot()).status, SearchIndexStatus.corrupted);

    await index.rebuild();
    final hits = await index.search('campeggio');
    expect(hits.single.sourceId, '1');
    expect((await index.snapshot()).status, SearchIndexStatus.ready);
  });

  test('disabled assistant never sends local context anywhere', () async {
    const gateway = DisabledKnowledgeAssistantGateway();

    expect(
      () => gateway.ask(question: 'test', localContext: const []),
      throwsA(isA<KnowledgeAssistantUnavailable>()),
    );
  });
}

class _MemoryStore implements LocalKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
