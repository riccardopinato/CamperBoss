import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:camperboss/core/services/home_cockpit_service.dart';
import 'package:camperboss/core/services/weather_service.dart';
import 'package:camperboss/features/home/presentation/home_screen.dart';

class FakeHomeCockpitService extends HomeCockpitService {
  @override
  Future<HomeCockpitSnapshot> load() async {
    return const HomeCockpitSnapshot(
      vehicle: null,
      checklistTotal: 0,
      checklistCompleted: 0,
      documentCount: 0,
      expiredDocuments: 0,
      documentsDueSoon: 0,
      maintenanceCount: 0,
      overdueMaintenance: 0,
      maintenanceDueSoon: 0,
      activeTrip: null,
      readinessScore: null,
      readinessCoverage: 0,
      actions: [],
    );
  }
}

class FakeWeatherService extends WeatherService {
  const FakeWeatherService();

  @override
  Future<WeatherSnapshot> fetchCurrent({
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    return WeatherSnapshot(
      location: location ?? 'Test location',
      temperature: 22,
      apparentTemperature: 23,
      humidity: 61,
      windSpeed: 8,
      windGusts: 18,
      precipitation: 0,
      weatherCode: 1,
      time: '2026-06-13T12:00',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('CamperBoss opens the home dashboard', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: HomeScreen(
                weatherService: const FakeWeatherService(),
                cockpitService: FakeHomeCockpitService(),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Camper cockpit'), findsOneWidget);
    expect(find.text('Guided setup'), findsWidgets);
    expect(find.text('Boss Readiness'), findsNothing);
    expect(find.text('Fresh water'), findsNothing);
  });
}
