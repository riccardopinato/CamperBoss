import 'dart:async';
import 'dart:convert';

import 'local_key_value_store.dart';

class LocalJsonCollection {
  LocalJsonCollection(
    this.key, {
    LocalKeyValueStore? store,
  }) : _store = store ?? createLocalKeyValueStore();

  static final Map<String, Future<void>> _writeTails = {};

  final String key;
  final LocalKeyValueStore _store;

  Future<List<Map<String, Object?>>> listRows() async {
    final raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<Map<String, Object?>> saveRow(Map<String, Object?> row) {
    return _serializedMutation(() async {
      final rows = await listRows();
      final id = row['id'] ?? _nextId(rows);
      final saved = {...row, 'id': id};
      final index = rows.indexWhere((item) => item['id'] == id);

      if (index == -1) {
        rows.add(saved);
      } else {
        rows[index] = saved;
      }

      await _writeRows(rows);
      return saved;
    });
  }

  Future<void> deleteRow(Object? id) {
    return _serializedMutation(() async {
      final rows = await listRows();
      rows.removeWhere((item) => item['id'] == id);
      await _writeRows(rows);
    });
  }

  Future<T> _serializedMutation<T>(Future<T> Function() mutation) async {
    final previous = _writeTails[key] ?? Future<void>.value();
    final gate = Completer<void>();
    final gateFuture = gate.future;
    _writeTails[key] = gateFuture;

    try {
      try {
        await previous;
      } catch (_) {
        // A failed previous mutation must not permanently block later writes.
      }
      return await mutation();
    } finally {
      gate.complete();
      if (identical(_writeTails[key], gateFuture)) {
        _writeTails.remove(key);
      }
    }
  }

  Future<void> _writeRows(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) {
      await _store.remove(key);
    } else {
      await _store.write(key, jsonEncode(rows));
    }
  }

  int _nextId(List<Map<String, Object?>> rows) {
    final ids = rows.map((item) => item['id']).whereType<int>();
    if (ids.isEmpty) return 1;
    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }
}
