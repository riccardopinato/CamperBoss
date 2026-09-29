import 'package:shared_preferences/shared_preferences.dart';

import 'local_key_value_store_base.dart';

LocalKeyValueStore createLocalKeyValueStore() {
  return SharedPreferencesKeyValueStore();
}

class SharedPreferencesKeyValueStore implements LocalKeyValueStore {
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async {
    final preferences = await _preferences;
    return preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final preferences = await _preferences;
    await preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final preferences = await _preferences;
    await preferences.remove(key);
  }
}
