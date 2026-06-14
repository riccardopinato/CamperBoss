import 'package:web/web.dart' as web;

import 'local_key_value_store_base.dart';

LocalKeyValueStore createLocalKeyValueStore() {
  return BrowserLocalKeyValueStore();
}

class BrowserLocalKeyValueStore implements LocalKeyValueStore {
  @override
  Future<String?> read(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<void> remove(String key) async {
    web.window.localStorage.removeItem(key);
  }
}
