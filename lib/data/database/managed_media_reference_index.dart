import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Canonical reference index for user-owned local media.
///
/// Physical deletion is allowed only after a path is no longer referenced by
/// documents, maintenance, GPX history or travel memories.
class ManagedMediaReferenceIndex {
  ManagedMediaReferenceIndex({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Set<String>> listReferencedPaths() async {
    if (kIsWeb) return const <String>{};

    final db = await _database.database;
    final referenced = <String>{};

    final documents = await db.query(
      AppDatabase.vehicleDocumentsTable,
      columns: const [
        'local_file_path',
        'thumbnail_path',
        'page_paths',
        'pdf_path',
      ],
    );
    for (final row in documents) {
      _addPath(referenced, row['local_file_path']);
      _addPath(referenced, row['thumbnail_path']);
      _addPaths(referenced, row['page_paths']);
      _addPath(referenced, row['pdf_path']);
    }

    final maintenance = await db.query(
      AppDatabase.maintenanceRecordsTable,
      columns: const ['attachment_paths'],
    );
    for (final row in maintenance) {
      _addPaths(referenced, row['attachment_paths']);
    }

    final tracks = await db.query(
      AppDatabase.gpxTracksTable,
      columns: const ['local_file_path'],
    );
    for (final row in tracks) {
      _addPath(referenced, row['local_file_path']);
    }

    final memories = await db.query(
      AppDatabase.travelMemoriesTable,
      columns: const ['local_photo_paths'],
    );
    for (final row in memories) {
      _addPaths(referenced, row['local_photo_paths']);
    }

    return referenced;
  }

  void _addPath(Set<String> output, Object? raw) {
    final path = raw?.toString().trim() ?? '';
    if (path.isNotEmpty) output.add(path);
  }

  void _addPaths(Set<String> output, Object? raw) {
    if (raw == null) return;
    if (raw is List) {
      for (final item in raw) {
        _addPath(output, item);
      }
      return;
    }
    final value = raw.toString().trim();
    if (value.isEmpty) return;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        for (final item in decoded) {
          _addPath(output, item);
        }
        return;
      }
    } catch (_) {
      // Legacy single-path values remain valid references.
    }
    _addPath(output, value);
  }
}
