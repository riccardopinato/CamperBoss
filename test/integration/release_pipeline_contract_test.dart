import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release identity is monotonic and matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final ledger = jsonDecode(
      File('release/release_identity.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(match!.group(1), ledger['versionName']);
    expect(int.parse(match.group(2)!), ledger['versionCode']);
    expect(
      ledger['versionCode'] as int,
      greaterThan(ledger['previousVersionCode'] as int),
    );
  });

  test('Play delivery builds once then downloads the immutable AAB', () {
    final workflow = File(
      '.github/workflows/android-internal-delivery.yml',
    ).readAsStringSync();

    expect(
      RegExp('flutter build appbundle --release').allMatches(workflow).length,
      1,
    );
    expect(workflow, contains('actions/download-artifact@'));
    expect(workflow, contains('expected_sha256'));
    expect(workflow, contains('aab_sha256'));
    expect(workflow, contains('working-directory: android'));
  });

  test('Fastlane only uploads an existing AAB and verifies its hash', () {
    final fastfile = File('android/fastlane/Fastfile').readAsStringSync();

    expect(fastfile, contains('Digest::SHA256.file'));
    expect(fastfile, contains('expected_sha256'));
    expect(fastfile, contains('dry_run'));
    expect(fastfile, isNot(contains('gradle(')));
    expect(fastfile, isNot(contains('flutter build')));
  });

  test('release signing hard-fail is wired for Play builds', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('requireReleaseSigning'));
    expect(gradle, contains('GradleException'));
    expect(gradle, contains('signingConfigs.getByName("debug")'));
  });
}
