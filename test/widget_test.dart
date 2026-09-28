import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    double latitude = 45.6049,
    double longitude = 10.6351,
    String location = 'Lake Garda basecamp',
  }) async {
    return const WeatherSnapshot(
      location: 'Lake Garda basecamp',
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
  testWidgets('CamperBoss opens the home dashboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          weatherService: const FakeWeatherService(),
          cockpitService: FakeHomeCockpitService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Camper cockpit'), findsOneWidget);
    expect(find.text('Boss Readiness'), findsOneWidget);
    expect(find.text('Mileage'), findsOneWidget);
    expect(find.text('Fresh water'), findsNothing);
  });
}
