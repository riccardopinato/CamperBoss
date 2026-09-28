import '../../data/models/route_preview.dart';
import '../../data/models/vehicle_profile.dart';

class CamperRoutingProfileResolver {
  const CamperRoutingProfileResolver();

  RouteRequest applyVehicleProfile({
    required int tripId,
    required List<RouteWaypoint> waypoints,
    required VehicleProfile? vehicle,
  }) {
    final restrictions = _restrictionsFor(vehicle);
    if (restrictions == null) {
      return RouteRequest(
        tripId: tripId,
        waypoints: waypoints,
      );
    }

    return RouteRequest(
      tripId: tripId,
      waypoints: waypoints,
      profile: 'driving-hgv',
      vehicleType: 'hgv',
      restrictions: restrictions,
    );
  }

  RouteVehicleRestrictions? _restrictionsFor(VehicleProfile? vehicle) {
    if (vehicle == null) return null;

    final length = _positive(vehicle.length);
    final width = _positive(vehicle.width);
    final height = _positive(vehicle.height);
    final maxMassKg = _positive(vehicle.maxMass) ?? _positive(vehicle.weight);

    if (length == null ||
        width == null ||
        height == null ||
        maxMassKg == null) {
      return null;
    }

    return RouteVehicleRestrictions(
      lengthMeters: length,
      widthMeters: width,
      heightMeters: height,
      weightTons: maxMassKg / 1000,
    );
  }

  double? _positive(double value) {
    if (!value.isFinite || value <= 0) return null;
    return value;
  }
}
