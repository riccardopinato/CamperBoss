import 'package:camperboss/core/services/routing_service.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const request = RouteRequest(
    tripId: 4,
    waypoints: [
      RouteWaypoint(name: 'Verona', latitude: 45.4384, longitude: 10.9916),
      RouteWaypoint(name: 'Molveno', latitude: 46.1427, longitude: 10.9630),
    ],
  );

  test('maps OpenRouteService response to RouteResult', () {
    final result = mapOpenRouteServiceDirectionsResponse(
      _orsFixture,
      request: request,
      calculatedAt: DateTime(2026),
    );

    expect(result.provider, 'openrouteservice');
    expect(result.totalDistanceMeters, 88412.4);
    expect(result.totalDurationSeconds, 6120.5);
    expect(result.legs.single.distanceMeters, 88412.4);
    expect(result.geometry.first.latitude, 45.4384);
  });

  test('camper-aware request sends ORS heavy vehicle restrictions', () {
    const camperRequest = RouteRequest(
      tripId: 4,
      profile: 'driving-hgv',
      vehicleType: 'hgv',
      restrictions: RouteVehicleRestrictions(
        lengthMeters: 6.99,
        widthMeters: 2.32,
        heightMeters: 2.95,
        weightTons: 3.5,
      ),
      waypoints: [
        RouteWaypoint(
          name: 'Verona',
          latitude: 45.4384,
          longitude: 10.9916,
        ),
        RouteWaypoint(
          name: 'Molveno',
          latitude: 46.1427,
          longitude: 10.9630,
        ),
      ],
    );

    final body = buildOpenRouteServiceRequestBody(camperRequest);
    final options = body['options'] as Map<String, Object?>;
    final profileParams =
        options['profile_params'] as Map<String, Object?>;
    final restrictions =
        profileParams['restrictions'] as Map<String, Object>;

    expect(options['vehicle_type'], 'hgv');
    expect(restrictions['length'], 6.99);
    expect(restrictions['width'], 2.32);
    expect(restrictions['height'], 2.95);
    expect(restrictions['weight'], 3.5);
  });

  test('standard car request does not send heavy vehicle options', () {
    final body = buildOpenRouteServiceRequestBody(request);
    expect(body.containsKey('options'), isFalse);
  });

  test('missing API key fails before network request', () async {
    final service = OpenRouteServiceRoutingService(
      apiKey: '',
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    await expectLater(
      service.calculateRoute(request),
      throwsA(
        isA<RouteFailure>().having(
          (failure) => failure.type,
          'type',
          RouteFailureType.missingApiKey,
        ),
      ),
    );
  });

  test('timeout maps to route failure', () async {
    final service = OpenRouteServiceRoutingService(
      apiKey: 'test-key',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(_orsFixture, 200);
      }),
    );

    await expectLater(
      service.calculateRoute(request),
      throwsA(isA<RouteFailure>().having(
        (failure) => failure.type,
        'type',
        RouteFailureType.timeout,
      )),
    );
  });

  test('API quota failure maps without logging secrets', () async {
    final service = OpenRouteServiceRoutingService(
      apiKey: 'test-key',
      client: MockClient((request) async => http.Response('{}', 429)),
    );

    await expectLater(
      service.calculateRoute(request),
      throwsA(isA<RouteFailure>().having(
        (failure) => failure.type,
        'type',
        RouteFailureType.quotaExceeded,
      )),
    );
  });
}

const _orsFixture = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "summary": {
          "distance": 88412.4,
          "duration": 6120.5
        },
        "segments": [
          {
            "distance": 88412.4,
            "duration": 6120.5
          }
        ]
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [10.9916, 45.4384],
          [10.9630, 46.1427]
        ]
      }
    }
  ]
}
''';
