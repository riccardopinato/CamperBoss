// STEP 16Q final release-candidate localization regression gate.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _catalog(String locale) {
  return jsonDecode(
    File('assets/translations/$locale.json').readAsStringSync(),
  ) as Map<String, dynamic>;
}

void main() {
  test('localized catalogs do not ship long English fallback copy', () {
    final english = _catalog('en');

    for (final locale in const ['it', 'de', 'fr', 'es', 'pt']) {
      final localized = _catalog(locale);
      final violations = <String>[];

      for (final entry in english.entries) {
        final englishValue = entry.value;
        final localizedValue = localized[entry.key];
        if (englishValue is! String || localizedValue is! String) continue;

        final normalized = englishValue.trim();
        if (normalized.length < 18) continue;

        if (localizedValue == englishValue) {
          violations.add('${entry.key} = "$englishValue"');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Locale $locale still contains long user-facing English copy:\n'
            '${violations.join('\n')}',
      );
    }
  });
}
