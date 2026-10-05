import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/provider_trust_config.dart';

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

  String get conditionKey {
    if (weatherCode == 0) return 'weather_condition_clear';
    if (weatherCode <= 3) return 'weather_condition_cloudy';
    if (weatherCode <= 67) return 'weather_condition_rain';
    if (weatherCode <= 77) return 'weather_condition_snow';
    if (weatherCode >= 95) return 'weather_condition_storm';
    return 'weather_condition_mixed';
  }
}

class WeatherService {
  const WeatherService({http.Client? client, Uri? endpoint})
      : _client = client,
        _endpoint = endpoint;

  final http.Client? _client;
  final Uri? _endpoint;

  Future<WeatherSnapshot> fetchCurrent({
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    if (latitude == null ||
        longitude == null ||
        location == null ||
        location.trim().isEmpty) {
      throw ArgumentError('A real location is required for live weather.');
    }

    final endpoint = _endpoint ?? ProviderTrustConfig.weatherEndpoint;
    if (endpoint == null) {
      throw StateError(
        'Weather provider is not configured for commercial distribution.',
      );
    }

    final client = _client ?? http.Client();
    final uri = endpoint.replace(
      queryParameters: {
        ...endpoint.queryParameters,
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
        throw StateError('Weather provider responded ${response.statusCode}');
      }
      if (response.bodyBytes.length > 1024 * 1024) {
        throw StateError('Weather response exceeded safety limit');
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
