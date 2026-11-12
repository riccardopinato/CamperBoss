import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:camperboss/factory_kits/profile/factory_profile_kit.dart' as kit;

/// X10-026: only tests pure Dart source compatibility on CamperBoss's actual SDK.
/// CamperBoss vehicle persistence and current blocked roadmap are unchanged.
void main() {
  test('pinned profile source has opt-out defaults and a stable JSON round trip', () {
    const selected = kit.ProfilePreferences(
      displayName: 'Guest',
      locale: 'it',
      theme: kit.ProfileTheme.dark,
    );
    final before = jsonEncode(selected.toJson());
    final restored = kit.ProfilePreferences.fromJson(
      jsonDecode(before),
    );
    expect(restored.displayName, 'Guest');
    expect(restored.theme, kit.ProfileTheme.dark);
    expect(restored.analyticsOptIn, isFalse);
    expect(jsonEncode(restored.toJson()), before);
  });

  test('corrupt profile bytes are rejected instead of overwriting app state', () {
    expect(
      () => kit.ProfilePreferences.fromJson(const {'schema_version': 99}),
      throwsFormatException,
    );
    const defaults = kit.ProfilePreferences();
    expect(defaults.analyticsOptIn, isFalse);
    expect(defaults.displayName, isEmpty);
  });
}
