import 'package:camperboss/core/services/camper_routing_profile_resolver.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const waypoints = [
    RouteWaypoint(name: 'A', latitude: 45, longitude: 11),
    RouteWaypoint(name: 'B', latitude: 46, longitude: 12),
  ];

  test('uses standard car routing when vehicle profile is missing', () {
    const resolver = CamperRoutingProfileResolver();

    final request = resolver.applyVehicleProfile(
      tripId: 1,
      waypoints: waypoints,
      vehicle: null,
    );

    expect(request.profile, 'driving-car');
    expect(request.restrictions, isNull);
    expect(request.isCamperAware, isFalse);
  });

  test('converts saved camper dimensions and max mass to ORS restrictions', () {
    const resolver = CamperRoutingProfileResolver();
    const vehicle = VehicleProfile(
      vehicleType: 'Camper',
      brand: 'Test',
      model: 'One',
      year: 2026,
      length: 6.99,
      width: 2.32,
      height: 2.95,
      weight: 3120,
      maxMass: 3500,
      seats: 4,
      fuelType: 'Diesel',
      mileage: 12000,
    );

    final request = resolver.applyVehicleProfile(
      tripId: 1,
      waypoints: waypoints,
      vehicle: vehicle,
    );

    expect(request.profile, 'driving-hgv');
    expect(request.vehicleType, 'hgv');
    expect(request.isCamperAware, isTrue);
    expect(request.restrictions?.lengthMeters, 6.99);
    expect(request.restrictions?.widthMeters, 2.32);
    expect(request.restrictions?.heightMeters, 2.95);
    expect(request.restrictions?.weightTons, 3.5);
  });

  test('vehicle restrictions are part of route cache fingerprint', () {
    const resolver = CamperRoutingProfileResolver();
    const base = VehicleProfile(
      vehicleType: 'Camper',
      brand: 'Test',
      model: 'One',
      year: 2026,
      length: 6.99,
      width: 2.32,
      height: 2.95,
      weight: 3120,
      maxMass: 3500,
      seats: 4,
      fuelType: 'Diesel',
      mileage: 12000,
    );

    final first = resolver.applyVehicleProfile(
      tripId: 1,
      waypoints: waypoints,
      vehicle: base,
    );
    final second = resolver.applyVehicleProfile(
      tripId: 1,
      waypoints: waypoints,
      vehicle: base.copyWith(height: 3.15),
    );

    expect(first.waypointFingerprint, isNot(second.waypointFingerprint));
  });
}
