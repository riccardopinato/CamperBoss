import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['en', 'it', 'de', 'fr', 'es', 'pt'];

Set<String> _placeholders(String value) {
  return RegExp(r'\{([A-Za-z0-9_]+)\}')
      .allMatches(value)
      .map((match) => match.group(1)!)
      .toSet();
}

void main() {
  test('all six translation catalogs have identical keys and placeholders', () {
    final catalogs = <String, Map<String, dynamic>>{
      for (final language in _languages)
        language: jsonDecode(
          File('assets/translations/$language.json').readAsStringSync(),
        ) as Map<String, dynamic>,
    };

    final reference = catalogs['en']!;
    for (final language in _languages.skip(1)) {
      final catalog = catalogs[language]!;
      expect(
        catalog.keys.toSet(),
        reference.keys.toSet(),
        reason: '$language translation key set drifted from English',
      );
      for (final key in reference.keys) {
        final referenceValue = reference[key];
        final translatedValue = catalog[key];
        expect(translatedValue, isA<String>(), reason: '$language:$key');
        expect(
          (translatedValue as String).trim(),
          isNotEmpty,
          reason: '$language:$key is empty',
        );
        expect(
          _placeholders(translatedValue),
          _placeholders(referenceValue as String),
          reason: '$language:$key placeholder drift',
        );
      }
    }
  });

  test('core localized surfaces reference existing translation keys', () {
    final catalog = jsonDecode(
      File('assets/translations/en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    const paths = [
      'lib/features/map/presentation/map_screen.dart',
      'lib/features/map/presentation/map_engine_v2_preview_screen.dart',
      'lib/features/finance/presentation/finance_screen.dart',
      'lib/features/trip/presentation/trip_planner_screen.dart',
      'lib/features/trip/presentation/travel_history_screen.dart',
      'lib/features/checklist/presentation/checklist_screen.dart',
      'lib/features/offline/presentation/offline_guides_screen.dart',
      'lib/features/search/presentation/local_search_screen.dart',
      'lib/features/settings/presentation/notification_settings_screen.dart',
      'lib/shared/widgets/place_card.dart',
    ];

    final keyPattern = RegExp(r'''['"]([A-Za-z0-9_]+)['"]\.tr(?:\(|\(\))''');
    final missing = <String>[];

    for (final path in paths) {
      final lines = File(path).readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        for (final match in keyPattern.allMatches(lines[index])) {
          final key = match.group(1)!;
          if (!catalog.containsKey(key)) {
            missing.add('$path:${index + 1}: $key');
          }
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Code references missing localization keys:\n'
          '${missing.join('\n')}',
    );
  });

  test('core localized surfaces contain no fixed user-facing literals', () {
    const paths = [
      'lib/features/map/presentation/map_screen.dart',
      'lib/features/map/presentation/map_engine_v2_preview_screen.dart',
      'lib/features/finance/presentation/finance_screen.dart',
      'lib/features/trip/presentation/trip_planner_screen.dart',
      'lib/features/trip/presentation/travel_history_screen.dart',
      'lib/features/checklist/presentation/checklist_screen.dart',
      'lib/features/offline/presentation/offline_guides_screen.dart',
      'lib/features/search/presentation/local_search_screen.dart',
      'lib/shared/widgets/place_card.dart',
    ];

    final textPattern = RegExp(
      r'''(?:Text|SelectableText)\(\s*['"]([^'"]*[A-Za-zÀ-ÿ][^'"]*)['"]''',
    );
    final propertyPattern = RegExp(
      r'''(?:tooltip|labelText|hintText|title|subtitle|message|label|detail)\s*:\s*['"]([^'"]*[A-Za-zÀ-ÿ][^'"]*)['"]''',
    );

    const allowed = <String>{
      'CamperBoss Essential',
    };

    final findings = <String>[];
    for (final path in paths) {
      final content = File(path).readAsStringSync();
      final lines = content.split('\n');
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('.tr(') || line.contains('.tr()')) continue;

        for (final pattern in [textPattern, propertyPattern]) {
          for (final match in pattern.allMatches(line)) {
            final literal = match.group(1)!.trim();
            if (literal.contains(r'$') ||
                literal.startsWith('#') ||
                allowed.contains(literal)) {
              continue;
            }
            findings.add('$path:${index + 1}: $literal');
          }
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: 'User-facing literals must use localization keys:\n'
          '${findings.join('\n')}',
    );
  });
}
