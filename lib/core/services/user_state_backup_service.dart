import '../../data/database/local_key_value_store.dart';

class UserStateBackupService {
  UserStateBackupService({LocalKeyValueStore? store})
      : _store = store ?? createLocalKeyValueStore();

  static const keys = <String>[
    'camperboss.onboardingProgress',
    'camperboss.guideFavorites',
    'camperboss.guideProgress',
    'camperboss.map.camera.v2',
    'camperboss.map.offline_regions.v2',
  ];

  final LocalKeyValueStore _store;

  Future<Map<String, String>> capture() async {
    final snapshot = <String, String>{};
    for (final key in keys) {
      final value = await _store.read(key);
      if (value != null) snapshot[key] = value;
    }
    return snapshot;
  }

  Future<void> restore(Map<String, String> snapshot) async {
    for (final key in keys) {
      final value = snapshot[key];
      if (value == null) {
        await _store.remove(key);
      } else {
        await _store.write(key, value);
      }
    }
  }
}
