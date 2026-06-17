import 'package:camperboss/data/models/route_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const waypoints = [
    RouteWaypoint(name: 'Verona', latitude: 45.4384, longitude: 10.9916),
    RouteWaypoint(name: 'Molveno', latitude: 46.1427, longitude: 10.9630),
  ];

  test('validates route waypoints', () {
    final invalid = RouteRequest(tripId: 1, waypoints: [waypoints.first]);
    expect(invalid.validate()?.type, RouteFailureType.invalidWaypoints);

    const valid = RouteRequest(tripId: 1, waypoints: waypoints);
    expect(valid.validate(), isNull);
  });

  test('fingerprint changes when waypoint order or profile changes', () {
    const first = RouteRequest(tripId: 1, waypoints: waypoints);
    final reversed = RouteRequest(
      tripId: 1,
      waypoints: [waypoints.last, waypoints.first],
    );
    const cycling = RouteRequest(
      tripId: 1,
      waypoints: waypoints,
      profile: 'cycling-regular',
    );

    expect(first.waypointFingerprint, isNot(reversed.waypointFingerprint));
    expect(first.waypointFingerprint, isNot(cycling.waypointFingerprint));
  });

  test('parses geolocated stages from ordered trip text', () {
    final parsed = parseRouteWaypoints([
      'Verona | 45.4384, 10.9916',
      'Molveno (46.1427, 10.9630)',
      'No coordinates here',
    ]);

    expect(parsed, hasLength(2));
    expect(parsed.first.name, 'Verona');
    expect(parsed.last.latitude, 46.1427);
  });

  test('route cache can be current or obsolete', () {
    const request = RouteRequest(tripId: 7, waypoints: waypoints);
    final result = RouteResult(
      tripId: 7,
      waypointFingerprint: request.waypointFingerprint,
      geometry: const [LatLng(45.4384, 10.9916), LatLng(46.1427, 10.9630)],
      totalDistanceMeters: 10000,
      totalDurationSeconds: 1200,
      legs: const [
        RouteLeg(
          fromName: 'Verona',
          toName: 'Molveno',
          distanceMeters: 10000,
          durationSeconds: 1200,
        ),
      ],
      provider: 'openrouteservice',
      calculatedAt: DateTime(2026),
    );

    const changed = RouteRequest(
      tripId: 7,
      waypoints: [
        RouteWaypoint(name: 'Verona', latitude: 45.4384, longitude: 10.9916),
        RouteWaypoint(name: 'Trento', latitude: 46.0700, longitude: 11.1200),
      ],
    );

    expect(result.matches(request), isTrue);
    expect(result.matches(changed), isFalse);
  });

  test('serializes and restores distance and duration', () {
    const request = RouteRequest(tripId: 7, waypoints: waypoints);
    final result = RouteResult(
      tripId: 7,
      waypointFingerprint: request.waypointFingerprint,
      geometry: const [LatLng(45.4384, 10.9916), LatLng(46.1427, 10.9630)],
      totalDistanceMeters: 12345,
      totalDurationSeconds: 2345,
      legs: const [
        RouteLeg(
          fromName: 'Verona',
          toName: 'Molveno',
          distanceMeters: 12345,
          durationSeconds: 2345,
        ),
      ],
      provider: 'openrouteservice',
      calculatedAt: DateTime(2026),
    );

    final restored = RouteResult.fromMap(result.toMap());

    expect(restored.totalDistanceMeters, 12345);
    expect(restored.totalDurationSeconds, 2345);
    expect(restored.geometry, hasLength(2));
    expect(restored.legs.single.fromName, 'Verona');
  });
}
