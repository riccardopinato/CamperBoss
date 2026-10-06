import 'dart:convert';

import 'package:camperboss/core/config/provider_trust_config.dart';
import 'package:camperboss/core/services/geocoding_service.dart';
import 'package:camperboss/core/services/routing_service.dart';
import 'package:camperboss/core/services/weather_service.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('provider trust policy', () {
    test('accepts only absolute HTTPS provider URLs', () {
      expect(
        ProviderTrustPolicy.parseHttpsUrl('https://example.com/api'),
        Uri.parse('https://example.com/api'),
      );
      expect(ProviderTrustPolicy.parseHttpsUrl('http://example.com'), isNull);
      expect(ProviderTrustPolicy.parseHttpsUrl('/relative'), isNull);
      expect(ProviderTrustPolicy.parseHttpsUrl(''), isNull);
    });

    test('blocks public tile hosts from bulk offline configuration', () {
      expect(
        ProviderTrustPolicy.parseApprovedOfflineStyleUrl(
          'https://tiles.openfreemap.org/styles/liberty',
        ),
        isNull,
      );
      expect(
        ProviderTrustPolicy.parseApprovedOfflineStyleUrl(
          'https://tile.openstreetmap.org/style.json',
        ),
        isNull,
      );
      expect(
        ProviderTrustPolicy.parseApprovedOfflineStyleUrl(
          'https://maps.example.com/styles/camperboss.json',
        ),
        Uri.parse('https://maps.example.com/styles/camperboss.json'),
      );
    });
  });

  group('routing boundary', () {
    const request = RouteRequest(
      tripId: 1,
      waypoints: [
        RouteWaypoint(name: 'A', latitude: 45, longitude: 11),
        RouteWaypoint(name: 'B', latitude: 46, longitude: 12),
      ],
    );

    test('proxy mode does not require or send a client API key', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(_routeFixture, 200);
      });
      final service = OpenRouteServiceRoutingService(
        apiKey: '',
        requireApiKey: false,
        baseUri: 'https://routing.example.com',
        client: client,
      );

      final result = await service.calculateRoute(request);

      expect(result.provider, 'openrouteservice');
      expect(captured.url.toString(),
          'https://routing.example.com/v2/directions/driving-car/geojson');
      expect(captured.headers.containsKey('authorization'), isFalse);
    });

    test('rejects non-HTTPS routing endpoints', () async {
      final service = OpenRouteServiceRoutingService(
        apiKey: '',
        requireApiKey: false,
        baseUri: 'http://routing.example.com',
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        service.calculateRoute(request),
        throwsA(
          isA<RouteFailure>().having(
            (failure) => failure.type,
            'type',
            RouteFailureType.clientError,
          ),
        ),
      );
    });
  });

  test('weather supports an injected trusted endpoint', () async {
    late Uri requested;
    final service = WeatherService(
      endpoint: Uri.parse('https://weather.example.com/v1/forecast'),
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 21.5,
              'apparent_temperature': 21.0,
              'relative_humidity_2m': 55,
              'precipitation': 0,
              'weather_code': 1,
              'wind_speed_10m': 8,
              'wind_gusts_10m': 13,
              'time': '2026-10-05T12:00',
            },
          }),
          200,
        );
      }),
    );

    final snapshot = await service.fetchCurrent(
      latitude: 45,
      longitude: 11,
      location: 'Test',
    );

    expect(snapshot.temperature, 21.5);
    expect(requested.scheme, 'https');
    expect(requested.queryParameters['latitude'], '45.0');
  });

  test('geocoding supports an injected trusted endpoint and locale', () async {
    late Uri requested;
    final service = GeocodingService(
      endpoint: Uri.parse('https://geo.example.com/v1/search'),
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Padova',
                'latitude': 45.4064,
                'longitude': 11.8768,
                'country': 'Italia',
                'admin1': 'Veneto',
              },
            ],
          }),
          200,
        );
      }),
    );

    final results = await service.search('Padova', language: 'it');

    expect(results.single.name, 'Padova');
    expect(requested.queryParameters['language'], 'it');
  });
}

const _routeFixture = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "summary": {"distance": 1000, "duration": 120},
        "segments": [{"distance": 1000, "duration": 120}]
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [[11,45],[12,46]]
      }
    }
  ]
}
''';
