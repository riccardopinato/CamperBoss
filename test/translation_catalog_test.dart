import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all translation catalogs expose the same key set', () {
    const locales = ['en', 'it', 'de', 'fr', 'es', 'pt'];
    final catalogs = <String, Map<String, dynamic>>{
      for (final locale in locales)
        locale: jsonDecode(
          File('assets/translations/$locale.json').readAsStringSync(),
        ) as Map<String, dynamic>,
    };

    final canonical = catalogs['en']!.keys.toSet();

    for (final entry in catalogs.entries) {
      expect(
        entry.value.keys.toSet(),
        canonical,
        reason: 'Translation keys differ for ${entry.key}',
      );
      expect(
        entry.value.values
            .whereType<String>()
            .every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Empty translation in ${entry.key}',
      );
    }
  });
}
