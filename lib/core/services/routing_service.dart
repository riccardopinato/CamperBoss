import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../data/models/route_preview.dart';

abstract interface class RoutingService {
  Future<RouteResult> calculateRoute(RouteRequest request);
}

class OpenRouteServiceRoutingService implements RoutingService {
  OpenRouteServiceRoutingService({
    required String apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.baseUri = const String.fromEnvironment(
      'ORS_BASE_URL',
      defaultValue: 'https://api.openrouteservice.org',
    ),
  })  : _apiKey = apiKey.trim(),
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;
  final Duration timeout;
  final String baseUri;

  @override
  Future<RouteResult> calculateRoute(RouteRequest request) async {
    final validation = request.validate();
    if (validation != null) throw validation;
    if (_apiKey.isEmpty) {
      throw const RouteFailure(
        RouteFailureType.missingApiKey,
        'Routing not configured',
      );
    }

    final uri = Uri.parse('$baseUri/v2/directions/${request.profile}/geojson');
    final body = jsonEncode({
      'coordinates': [
        for (final waypoint in request.waypoints)
          [waypoint.longitude, waypoint.latitude],
      ],
      'instructions': false,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              HttpHeaders.authorizationHeader: _apiKey,
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
            },
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode == 429) {
        throw const RouteFailure(
          RouteFailureType.quotaExceeded,
          'OpenRouteService quota exceeded',
        );
      }
      if (response.statusCode >= 500) {
        throw RouteFailure(
          RouteFailureType.serverError,
          'OpenRouteService server error ${response.statusCode}',
        );
      }
      if (response.statusCode >= 400) {
        throw RouteFailure(
          RouteFailureType.clientError,
          'OpenRouteService request failed ${response.statusCode}',
        );
      }

      return mapOpenRouteServiceDirectionsResponse(
        response.body,
        request: request,
        calculatedAt: DateTime.now(),
      );
    } on TimeoutException {
      throw const RouteFailure(RouteFailureType.timeout, 'Routing timed out');
    } on RouteFailure {
      rethrow;
    } on SocketException {
      throw const RouteFailure(
        RouteFailureType.network,
        'Network unavailable',
      );
    } catch (_) {
      throw const RouteFailure(
        RouteFailureType.unknown,
        'Route calculation failed',
      );
    }
  }
}

class FakeRoutingService implements RoutingService {
  const FakeRoutingService({this.result, this.failure});

  final RouteResult? result;
  final RouteFailure? failure;

  @override
  Future<RouteResult> calculateRoute(RouteRequest request) async {
    final validation = request.validate();
    if (validation != null) throw validation;
    final failure = this.failure;
    if (failure != null) throw failure;
    final result = this.result;
    if (result != null) return result;

    return RouteResult(
      tripId: request.tripId,
      waypointFingerprint: request.waypointFingerprint,
      geometry: [for (final waypoint in request.waypoints) waypoint.point],
      totalDistanceMeters: 12000,
      totalDurationSeconds: 1800,
      legs: [
        for (var index = 0; index < request.waypoints.length - 1; index++)
          RouteLeg(
            fromName: request.waypoints[index].name,
            toName: request.waypoints[index + 1].name,
            distanceMeters: 6000,
            durationSeconds: 900,
          ),
      ],
      provider: 'fake',
      calculatedAt: DateTime.now(),
    );
  }
}

RouteResult mapOpenRouteServiceDirectionsResponse(
  String responseBody, {
  required RouteRequest request,
  required DateTime calculatedAt,
}) {
  final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
  final features = decoded['features'] as List<dynamic>? ?? const [];
  if (features.isEmpty) {
    throw const RouteFailure(RouteFailureType.noRoute, 'No route found');
  }

  final feature = features.first as Map<String, dynamic>;
  final geometry = feature['geometry'] as Map<String, dynamic>?;
  final coordinates = geometry?['coordinates'] as List<dynamic>?;
  if (coordinates == null || coordinates.length < 2) {
    throw const RouteFailure(
      RouteFailureType.malformedGeometry,
      'Route geometry is malformed',
    );
  }

  final properties = feature['properties'] as Map<String, dynamic>? ?? {};
  final summary = properties['summary'] as Map<String, dynamic>? ?? {};
  final segments = properties['segments'] as List<dynamic>? ?? const [];

  return RouteResult(
    tripId: request.tripId,
    waypointFingerprint: request.waypointFingerprint,
    geometry: coordinates.map((coordinate) {
      final pair = coordinate as List<dynamic>;
      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList(growable: false),
    totalDistanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
    totalDurationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
    legs: [
      for (final (index, segment) in segments.indexed)
        RouteLeg(
          fromName: request.waypoints[index].name,
          toName: request.waypoints[index + 1].name,
          distanceMeters:
              ((segment as Map<String, dynamic>)['distance'] as num).toDouble(),
          durationSeconds: (segment['duration'] as num).toDouble(),
        ),
    ],
    provider: 'openrouteservice',
    calculatedAt: calculatedAt,
  );
}
