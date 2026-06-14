import 'package:camperboss/data/database/local_json_collection.dart';
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
}
