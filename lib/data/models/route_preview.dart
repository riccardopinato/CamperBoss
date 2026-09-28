import 'dart:convert';

import 'package:latlong2/latlong.dart';

class RouteWaypoint {
  const RouteWaypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);

  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String get fingerprintPart {
    return '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory RouteWaypoint.fromMap(Map<String, Object?> map) {
    return RouteWaypoint(
      name: map['name'] as String? ?? 'Stop',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}

class RouteVehicleRestrictions {
  const RouteVehicleRestrictions({
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.weightTons,
  });

  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final double weightTons;

  bool get isValid {
    return lengthMeters.isFinite &&
        widthMeters.isFinite &&
        heightMeters.isFinite &&
        weightTons.isFinite &&
        lengthMeters > 0 &&
        widthMeters > 0 &&
        heightMeters > 0 &&
        weightTons > 0;
  }

  String get fingerprintPart {
    return [
      lengthMeters.toStringAsFixed(3),
      widthMeters.toStringAsFixed(3),
      heightMeters.toStringAsFixed(3),
      weightTons.toStringAsFixed(3),
    ].join(',');
  }

  Map<String, Object> toOpenRouteServiceMap() {
    return {
      'length': lengthMeters,
      'width': widthMeters,
      'height': heightMeters,
      'weight': weightTons,
    };
  }
}

class RouteRequest {
  const RouteRequest({
    required this.tripId,
    required this.waypoints,
    this.profile = 'driving-car',
    this.vehicleType,
    this.restrictions,
  });

  final int tripId;
  final List<RouteWaypoint> waypoints;
  final String profile;
  final String? vehicleType;
  final RouteVehicleRestrictions? restrictions;

  bool get isCamperAware {
    return profile == 'driving-hgv' &&
        vehicleType != null &&
        restrictions?.isValid == true;
  }

  String get waypointFingerprint {
    final points = waypoints.map((waypoint) => waypoint.fingerprintPart);
    final restrictionPart = restrictions?.fingerprintPart ?? 'none';
    return [
      profile,
      vehicleType ?? 'none',
      restrictionPart,
      ...points,
    ].join('|');
  }

  RouteFailure? validate() {
    if (waypoints.length < 2) {
      return const RouteFailure(
        RouteFailureType.invalidWaypoints,
        'At least two geolocated stages are required',
      );
    }
    if (waypoints.any((waypoint) => !waypoint.isValid)) {
      return const RouteFailure(
        RouteFailureType.invalidWaypoints,
        'One or more stage coordinates are invalid',
      );
    }
    if (restrictions != null && restrictions?.isValid != true) {
      return const RouteFailure(
        RouteFailureType.invalidVehicleProfile,
        'Vehicle routing restrictions are invalid',
      );
    }
    if (restrictions != null && profile != 'driving-hgv') {
      return const RouteFailure(
        RouteFailureType.invalidVehicleProfile,
        'Vehicle restrictions require the driving-hgv profile',
      );
    }
    return null;
  }
}

class RouteLeg {
  const RouteLeg({
    required this.fromName,
    required this.toName,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final String fromName;
  final String toName;
  final double distanceMeters;
  final double durationSeconds;

  Map<String, Object?> toMap() {
    return {
      'fromName': fromName,
      'toName': toName,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  factory RouteLeg.fromMap(Map<String, Object?> map) {
    return RouteLeg(
      fromName: map['fromName'] as String? ?? 'Start',
      toName: map['toName'] as String? ?? 'Stop',
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      durationSeconds: (map['durationSeconds'] as num).toDouble(),
    );
  }
}

class RouteResult {
  const RouteResult({
    required this.tripId,
    required this.waypointFingerprint,
    required this.geometry,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.legs,
    required this.provider,
    required this.calculatedAt,
  });

  final int tripId;
  final String waypointFingerprint;
  final List<LatLng> geometry;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final List<RouteLeg> legs;
  final String provider;
  final DateTime calculatedAt;

  bool matches(RouteRequest request) {
    return tripId == request.tripId &&
        waypointFingerprint == request.waypointFingerprint;
  }

  Map<String, Object?> toMap() {
    return {
      'trip_id': tripId,
      'waypoint_fingerprint': waypointFingerprint,
      'geometry': jsonEncode(
        geometry
            .map(
              (point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              },
            )
            .toList(),
      ),
      'distance_meters': totalDistanceMeters,
      'duration_seconds': totalDurationSeconds,
      'legs': jsonEncode(legs.map((leg) => leg.toMap()).toList()),
      'provider': provider,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory RouteResult.fromMap(Map<String, Object?> map) {
    return RouteResult(
      tripId: map['trip_id'] as int,
      waypointFingerprint: map['waypoint_fingerprint'] as String,
      geometry: _decodeGeometry(map['geometry'] as String?),
      totalDistanceMeters: (map['distance_meters'] as num).toDouble(),
      totalDurationSeconds: (map['duration_seconds'] as num).toDouble(),
      legs: _decodeLegs(map['legs'] as String?),
      provider: map['provider'] as String,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
    );
  }

  static List<LatLng> _decodeGeometry(String? value) {
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.map((item) {
      final map = Map<String, Object?>.from(item as Map);
      return LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  static List<RouteLeg> _decodeLegs(String? value) {
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((item) => RouteLeg.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();
  }
}

enum RouteFailureType {
  missingApiKey,
  invalidWaypoints,
  invalidVehicleProfile,
  network,
  timeout,
  quotaExceeded,
  clientError,
  serverError,
  noRoute,
  malformedGeometry,
  staleTrip,
  unknown,
}

class RouteFailure implements Exception {
  const RouteFailure(this.type, this.message);

  final RouteFailureType type;
  final String message;

  @override
  String toString() => message;
}

List<RouteWaypoint> parseRouteWaypoints(List<String> stages) {
  return stages
      .map(_parseRouteWaypoint)
      .whereType<RouteWaypoint>()
      .toList(growable: false);
}

RouteWaypoint? _parseRouteWaypoint(String stage) {
  final match = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
  ).firstMatch(stage);
  if (match == null) return null;

  final latitude = double.tryParse(match.group(1)!);
  final longitude = double.tryParse(match.group(2)!);
  if (latitude == null || longitude == null) return null;

  final name = stage
      .replaceFirst(match.group(0)!, '')
      .replaceAll(RegExp(r'[\|\-\(\)]'), ' ')
      .trim();

  return RouteWaypoint(
    name: name.isEmpty ? 'Stop ${latitude.toStringAsFixed(3)}' : name,
    latitude: latitude,
    longitude: longitude,
  );
}
