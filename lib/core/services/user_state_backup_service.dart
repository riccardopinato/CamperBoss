import '../../data/database/local_key_value_store.dart';

class UserStateMergeResult {
  const UserStateMergeResult({
    required this.restored,
    required this.skipped,
    required this.conflicts,
  });

  final int restored;
  final int skipped;
  final int conflicts;
}

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

  /// Exact restore used by replace-all and safety rollback.
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

  /// Conservative merge: installation-local user state has no timestamps or
  /// portable entity identity, so an existing target value always wins.
  ///
  /// Incoming values are added only when the target key is absent. Missing
  /// incoming keys never delete target state.
  Future<UserStateMergeResult> mergePreservingExisting(
    Map<String, String> incoming,
  ) async {
    var restored = 0;
    var skipped = 0;
    var conflicts = 0;

    for (final key in keys) {
      final incomingValue = incoming[key];
      if (incomingValue == null) continue;

      final currentValue = await _store.read(key);
      if (currentValue == null) {
        await _store.write(key, incomingValue);
        restored++;
        continue;
      }

      skipped++;
      if (currentValue != incomingValue) {
        conflicts++;
      }
    }

    return UserStateMergeResult(
      restored: restored,
      skipped: skipped,
      conflicts: conflicts,
    );
  }
}
