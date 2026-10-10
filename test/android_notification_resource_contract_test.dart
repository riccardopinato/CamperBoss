import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification icon exists and is protected from resource shrinking', () {
    final icon =
        File('android/app/src/main/res/drawable/app_notification.xml');
    final keep = File('android/app/src/main/res/raw/keep.xml');

    expect(
      icon.existsSync(),
      isTrue,
      reason: 'app_notification drawable must exist for local notifications.',
    );
    expect(
      keep.existsSync(),
      isTrue,
      reason: 'Resource shrinker keep contract must exist for release builds.',
    );

    final keepContents = keep.readAsStringSync();
    expect(keepContents, contains('@drawable/app_notification'));
  });

  test('notification service uses the protected Android icon', () {
    final service =
        File('lib/core/services/local_notification_service_io.dart');

    expect(service.existsSync(), isTrue);
    final contents = service.readAsStringSync();

    expect(
      contents,
      contains("AndroidInitializationSettings('app_notification')"),
    );
    expect(contents, contains("icon: 'app_notification'"));
  });
}
