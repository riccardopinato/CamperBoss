import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _localizationInitialized = false;

Future<void> _ensureTestLocalization() async {
  if (_localizationInitialized) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  _localizationInitialized = true;
}

class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return Future<Map<String, dynamic>?>.value(decoded);
  }
}

Future<void> pumpLocalizedHome(
  WidgetTester tester, {
  required Widget home,
}) async {
  await _ensureTestLocalization();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: false,
      assetLoader: const _FileAssetLoader(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: home,
          );
        },
      ),
    ),
  );

  // The loader returns a completed Future backed by the real JSON file, so
  // one extra frame is enough to publish the localized MaterialApp.
  await tester.pump();
  await tester.pumpAndSettle();
}
