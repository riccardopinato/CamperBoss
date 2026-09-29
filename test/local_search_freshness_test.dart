import 'package:camperboss/core/services/local_search_service.dart';
import 'package:camperboss/data/database/data_revision_store.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/models/search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search rebuilds automatically after source revision changes', () async {
    final revision = DataRevisionStore.isolated();
    final store = _MemoryStore();
    var documents = <SearchDocument>[
      SearchDocument(
        id: 'trip:1',
        type: SearchDocumentType.trip,
        sourceId: '1',
        title: 'Dolomiti',
        body: 'Prima versione',
        metadata: const {},
        updatedAt: DateTime(2026, 9, 29),
      ),
    ];

    final index = PersistentLocalSearchIndex(
      store: store,
      documentLoader: () async => documents,
    );
    final service = LocalSearchService(
      index: index,
      revisionStore: revision,
    );

    expect((await service.search('Dolomiti')).single.title, 'Dolomiti');

    documents = [
      SearchDocument(
        id: 'trip:2',
        type: SearchDocumentType.trip,
        sourceId: '2',
        title: 'Valle Aurina',
        body: 'Seconda versione',
        metadata: const {},
        updatedAt: DateTime(2026, 9, 29),
      ),
    ];
    revision.bump();

    expect(await service.search('Dolomiti'), isEmpty);
    expect((await service.search('Valle Aurina')).single.sourceId, '2');
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
