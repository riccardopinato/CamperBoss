import 'dart:convert';
import 'dart:io';

import 'package:camperboss/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('Web metadata is branded, responsive and deep-link capable', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(index, contains('<title>CamperBoss</title>'));
    expect(index, isNot(contains('A new Flutter project')));
    expect(manifest['name'], 'CamperBoss');
    expect(manifest['short_name'], 'CamperBoss');
    expect(manifest.containsKey('orientation'), isFalse);

    for (final route in ['/', '/map', '/trips', '/camper', '/more']) {
      expect(router, contains("'$route'"));
    }
    expect(main, contains('routes: camperBossRoutes()'));
    expect(main, contains('onUnknownRoute:'));
    expect(main, isNot(contains('usePathUrlStrategy')));
    expect(
      File('README.md').readAsStringSync(),
      contains('/CamperBoss/#/map'),
    );
  });

  test('native capability Product Truth stays explicit', () {
    final capture =
        File('lib/core/services/document_capture_service_io.dart')
            .readAsStringSync();
    final ocr =
        File('lib/core/services/document_ocr_service_io.dart')
            .readAsStringSync();
    final documents =
        File('lib/features/documents/presentation/vehicle_documents_screen.dart')
            .readAsStringSync();
    final notifications =
        File('lib/core/services/local_notification_service_io.dart')
            .readAsStringSync();

    expect(capture, contains('if (Platform.isAndroid)'));
    expect(capture, contains('FallbackDocumentCaptureService'));
    expect(capture, isNot(contains('Platform.isIOS) {\n    return AndroidDocumentCaptureService')));
    expect(ocr, contains('Platform.isAndroid || Platform.isIOS'));
    expect(documents, contains('document_scan_unavailable'));
    expect(notifications, contains('checkPermissions()'));
    expect(notifications, contains('NotificationTimezoneState.utcFallback'));
  });

  test('geocoding callers pass the selected application locale', () {
    final map =
        File('lib/features/map/presentation/map_screen.dart').readAsStringSync();
    final trip = File(
      'lib/features/trip/presentation/trip_planner_screen.dart',
    ).readAsStringSync();

    expect(map, contains('language: language'));
    expect(trip, contains('language: context.locale.languageCode'));
  });

  test('search index covers the approved local data scope', () {
    final models =
        File('lib/data/models/search_models.dart').readAsStringSync();
    final source =
        File('lib/core/services/local_search_service.dart').readAsStringSync();

    for (final type in [
      'expense',
      'fuel',
      'checklist',
      'gpxTrack',
      'memory',
    ]) {
      expect(models, contains(type));
    }
    for (final loader in [
      '_expenses()',
      '_fuel()',
      '_checklist()',
      '_travelHistory()',
    ]) {
      expect(source, contains(loader));
    }
    expect(source, contains('loadTripBudget'));
  });

  test('accessibility baseline does not clamp scaling and meets text contrast', () {
    final theme =
        File('lib/core/theme/app_theme.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final map =
        File('lib/features/map/presentation/map_screen.dart').readAsStringSync();

    expect(theme, contains('MaterialTapTargetSize.padded'));
    expect(main, isNot(contains('textScaleFactor')));
    expect(main, isNot(contains('TextScaler.linear(')));
    expect(map, contains("label: 'map_semantics_interactive'.tr()"));

    expect(_contrastRatio(AppColors.text, AppColors.surface), greaterThan(4.5));
    expect(
      _contrastRatio(AppColors.muted, AppColors.surface),
      greaterThan(4.5),
    );
    expect(
      _contrastRatio(AppColors.dayText, AppColors.daySurface),
      greaterThan(4.5),
    );
    expect(
      _contrastRatio(AppColors.dayMuted, AppColors.daySurface),
      greaterThan(4.5),
    );
  });
}
