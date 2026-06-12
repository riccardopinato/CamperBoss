import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.location,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windGusts,
    required this.precipitation,
    required this.weatherCode,
    required this.time,
  });

  final String location;
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final double windGusts;
  final double precipitation;
  final int weatherCode;
  final String time;

  String get condition {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Cloudy';
    if (weatherCode <= 67) return 'Rain risk';
    if (weatherCode <= 77) return 'Snow risk';
    if (weatherCode >= 95) return 'Storm risk';
    return 'Mixed';
  }
}

class WeatherService {
  const WeatherService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherSnapshot> fetchCurrent({
    double latitude = 45.6049,
    double longitude = 10.6351,
    String location = 'Lake Garda basecamp',
  }) async {
    final client = _client ?? http.Client();
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'precipitation',
          'weather_code',
          'wind_speed_10m',
          'wind_gusts_10m',
        ].join(','),
        'timezone': 'auto',
      },
    );

    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw StateError('Open-Meteo responded ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;

      return WeatherSnapshot(
        location: location,
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature:
            (current['apparent_temperature'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).round(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        windGusts: (current['wind_gusts_10m'] as num).toDouble(),
        precipitation: (current['precipitation'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).round(),
        time: current['time'] as String,
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
