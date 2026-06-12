import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:camperboss/core/services/weather_service.dart';
import 'package:camperboss/features/home/presentation/home_screen.dart';

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
      const MaterialApp(
        home: HomeScreen(weatherService: FakeWeatherService()),
      ),
    );

    expect(find.text('Camper cockpit'), findsOneWidget);
    expect(find.text('Boss Score'), findsOneWidget);
    expect(find.text('Fresh water'), findsOneWidget);
  });
}
