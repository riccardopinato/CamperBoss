import 'package:camperboss/data/database/local_json_collection.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/database/local_key_value_store_stub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local json collection persists CRUD rows in the shared store',
      () async {
    final store = MemoryKeyValueStore();
    final collection = LocalJsonCollection('test.rows', store: store);

    final created = await collection.saveRow({
      'title': 'First row',
      'checked': 0,
    });
    expect(created['id'], 1);

    final reread = LocalJsonCollection('test.rows', store: store);
    expect(await reread.listRows(), [created]);

    final updated = await reread.saveRow({
      ...created,
      'checked': 1,
    });
    expect(updated['checked'], 1);
    expect(await collection.listRows(), [updated]);

    await collection.deleteRow(1);
    expect(await reread.listRows(), isEmpty);
  });

  test('failed storage write preserves old data and later writes recover',
      () async {
    final store = _FailOnceStore();
    final collection = LocalJsonCollection('test.quota', store: store);

    final original = await collection.saveRow({'title': 'original'});
    store.failNextWrite = true;

    await expectLater(
      collection.saveRow({'title': 'must-not-commit'}),
      throwsA(isA<StateError>()),
    );

    expect(await collection.listRows(), [original]);

    final recovered = await collection.saveRow({'title': 'recovered'});
    expect(recovered['title'], 'recovered');
    final rows = await collection.listRows();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row['title']), containsAll(['original', 'recovered']));
  });

  test('serializes concurrent read-modify-write mutations across instances',
      () async {
    final store = MemoryKeyValueStore();
    final a = LocalJsonCollection('test.concurrent', store: store);
    final b = LocalJsonCollection('test.concurrent', store: store);

    await Future.wait([
      for (var index = 0; index < 20; index++)
        (index.isEven ? a : b).saveRow({'value': index}),
    ]);

    final rows = await a.listRows();
    expect(rows, hasLength(20));
    expect(rows.map((row) => row['id']).toSet(), hasLength(20));
  });
}


class _FailOnceStore implements LocalKeyValueStore {
  final _values = <String, String>{};
  bool failNextWrite = false;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated browser quota failure');
    }
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
