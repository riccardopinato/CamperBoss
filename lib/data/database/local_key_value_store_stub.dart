import 'local_key_value_store_base.dart';

LocalKeyValueStore createLocalKeyValueStore() {
  return MemoryKeyValueStore();
}

class MemoryKeyValueStore implements LocalKeyValueStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
