import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../data/models/travel_history_models.dart';

class GpxImportBundle {
  const GpxImportBundle({
    required this.tracks,
    required this.memories,
  });

  final List<GpxTrack> tracks;
  final List<TravelMemory> memories;
}

class GpxValidationException implements Exception {
  const GpxValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GpxService {
  static const maxCharacters = 5 * 1024 * 1024;
  static const maxPoints = 10000;
  static const simplifyThreshold = 2000;

  const GpxService();

  Future<GpxImportBundle> parse(
    String content, {
    int? tripId,
    String? fallbackName,
  }) async {
    if (content.length > maxCharacters) {
      throw const GpxValidationException('GPX file too large');
    }
    final payload = _GpxParsePayload(
      content: content,
      tripId: tripId,
      fallbackName: fallbackName,
    );
    if (content.length > 250000) {
      return compute(_parsePayload, payload);
    }
    return _parsePayload(payload);
  }

  String exportTrack(
    GpxTrack track, {
    List<TravelMemory> memories = const [],
  }) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="CamperBoss">')
      ..writeln('  <trk>')
      ..writeln('    <name>${_escape(track.name)}</name>')
      ..writeln('    <trkseg>');

    for (final point in track.points) {
      buffer.write(
        '      <trkpt lat="${point.latitude}" lon="${point.longitude}">',
      );
      if (point.elevation != null) {
        buffer.write('<ele>${point.elevation}</ele>');
      }
      if (point.recordedAt != null) {
        buffer.write(
            '<time>${point.recordedAt!.toUtc().toIso8601String()}</time>');
      }
      buffer.writeln('</trkpt>');
    }

    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>');

    for (final memory in memories) {
      buffer.writeln(
        '  <wpt lat="${memory.latitude}" lon="${memory.longitude}">',
      );
      buffer.writeln('    <name>${_escape(memory.title)}</name>');
      if (memory.description != null && memory.description!.isNotEmpty) {
        buffer.writeln('    <desc>${_escape(memory.description!)}</desc>');
      }
      buffer.writeln(
          '    <time>${memory.occurredAt.toUtc().toIso8601String()}</time>');
      buffer.writeln('  </wpt>');
    }

    buffer.writeln('</gpx>');
    return buffer.toString();
  }
}

GpxImportBundle _parsePayload(_GpxParsePayload payload) {
  try {
    final document = XmlDocument.parse(payload.content);
    final root = document.rootElement;
    if (root.name.local.toLowerCase() != 'gpx') {
      throw const GpxValidationException('Invalid GPX root element');
    }

    final tracks = <GpxTrack>[];
    final memories = <TravelMemory>[];

    for (final trackElement in root.findElements('trk')) {
      final points = <GeoPoint>[];
      final name = _childText(trackElement, 'name') ??
          payload.fallbackName ??
          'Imported track';
      for (final segment in trackElement.findElements('trkseg')) {
        for (final pointElement in segment.findElements('trkpt')) {
          points.add(_parsePoint(pointElement));
        }
      }
      if (points.isEmpty) continue;
      tracks
          .add(_buildTrack(points: points, name: name, tripId: payload.tripId));
    }

    for (final routeElement in root.findElements('rte')) {
      final points = <GeoPoint>[];
      final name = _childText(routeElement, 'name') ??
          payload.fallbackName ??
          'Imported route';
      for (final pointElement in routeElement.findElements('rtept')) {
        points.add(_parsePoint(pointElement));
      }
      if (points.isEmpty) continue;
      tracks
          .add(_buildTrack(points: points, name: name, tripId: payload.tripId));
    }

    for (final waypoint in root.findElements('wpt')) {
      final point = _parsePoint(waypoint);
      memories.add(
        TravelMemory(
          id: _id('memory'),
          tripId: payload.tripId,
          title: _childText(waypoint, 'name') ?? 'Waypoint',
          description: _childText(waypoint, 'desc'),
          latitude: point.latitude,
          longitude: point.longitude,
          occurredAt: point.recordedAt ?? DateTime.now(),
        ),
      );
    }

    if (tracks.isEmpty && memories.isEmpty) {
      throw const GpxValidationException('GPX does not contain supported data');
    }
    return GpxImportBundle(tracks: tracks, memories: memories);
  } on XmlException {
    throw const GpxValidationException('GPX XML is malformed');
  }
}

GpxTrack _buildTrack({
  required List<GeoPoint> points,
  required String name,
  required int? tripId,
}) {
  if (points.length > GpxService.maxPoints) {
    throw const GpxValidationException('GPX track has too many points');
  }
  final simplified = points.length > GpxService.simplifyThreshold
      ? _simplify(points, toleranceMeters: 20)
      : points;
  final distance = const Distance();
  var distanceMeters = 0.0;
  var elevationGain = 0.0;
  for (var i = 1; i < simplified.length; i++) {
    final previous = simplified[i - 1];
    final current = simplified[i];
    distanceMeters += distance.as(
      LengthUnit.Meter,
      LatLng(previous.latitude, previous.longitude),
      LatLng(current.latitude, current.longitude),
    );
    final deltaElevation = (current.elevation ?? 0) - (previous.elevation ?? 0);
    if (deltaElevation > 0) elevationGain += deltaElevation;
  }

  final timed = simplified.where((point) => point.recordedAt != null).toList();
  Duration? duration;
  if (timed.length >= 2) {
    final start = timed.first.recordedAt!;
    final end = timed.last.recordedAt!;
    if (!end.isBefore(start)) duration = end.difference(start);
  }

  return GpxTrack(
    id: _id('track'),
    tripId: tripId,
    name: name,
    points: simplified,
    distanceMeters: distanceMeters,
    duration: duration,
    elevationGainMeters: elevationGain <= 0 ? null : elevationGain,
    originalPointCount: points.length,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

GeoPoint _parsePoint(XmlElement element) {
  final latitude = double.tryParse(element.getAttribute('lat') ?? '');
  final longitude = double.tryParse(element.getAttribute('lon') ?? '');
  if (latitude == null ||
      longitude == null ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    throw const GpxValidationException('GPX contains invalid coordinates');
  }
  final timestamp = _childText(element, 'time');
  final recordedAt = timestamp == null ? null : DateTime.tryParse(timestamp);
  return GeoPoint(
    latitude: latitude,
    longitude: longitude,
    elevation: double.tryParse(_childText(element, 'ele') ?? ''),
    recordedAt: recordedAt,
  );
}

List<GeoPoint> _simplify(List<GeoPoint> points,
    {required double toleranceMeters}) {
  if (points.length < 3) return points;
  final squaredTolerance = toleranceMeters * toleranceMeters;
  final result = <GeoPoint>[points.first];
  _simplifySection(points, 0, points.length - 1, squaredTolerance, result);
  result.add(points.last);
  return result;
}

void _simplifySection(
  List<GeoPoint> points,
  int first,
  int last,
  double squaredTolerance,
  List<GeoPoint> output,
) {
  var index = -1;
  var maxDistance = 0.0;

  for (var i = first + 1; i < last; i++) {
    final distance =
        _segmentDistanceSquared(points[i], points[first], points[last]);
    if (distance > maxDistance) {
      maxDistance = distance;
      index = i;
    }
  }

  if (index != -1 && maxDistance > squaredTolerance) {
    if (index - first > 1) {
      _simplifySection(points, first, index, squaredTolerance, output);
    }
    output.add(points[index]);
    if (last - index > 1) {
      _simplifySection(points, index, last, squaredTolerance, output);
    }
  }
}

double _segmentDistanceSquared(GeoPoint point, GeoPoint start, GeoPoint end) {
  final px = point.longitude;
  final py = point.latitude;
  final sx = start.longitude;
  final sy = start.latitude;
  final ex = end.longitude;
  final ey = end.latitude;

  var dx = ex - sx;
  var dy = ey - sy;
  if (dx != 0 || dy != 0) {
    final t = ((px - sx) * dx + (py - sy) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      dx = px - ex;
      dy = py - ey;
    } else if (t > 0) {
      final projX = sx + dx * t;
      final projY = sy + dy * t;
      dx = px - projX;
      dy = py - projY;
    } else {
      dx = px - sx;
      dy = py - sy;
    }
  } else {
    dx = px - sx;
    dy = py - sy;
  }

  const metersPerDegree = 111320.0;
  final xMeters = dx * metersPerDegree * math.cos(py * math.pi / 180);
  final yMeters = dy * metersPerDegree;
  return xMeters * xMeters + yMeters * yMeters;
}

String? _childText(XmlElement element, String name) {
  final matches = element.findElements(name);
  if (matches.isEmpty) return null;
  final text = matches.first.innerText.trim();
  return text.isEmpty ? null : text;
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

class _GpxParsePayload {
  const _GpxParsePayload({
    required this.content,
    required this.tripId,
    required this.fallbackName,
  });

  final String content;
  final int? tripId;
  final String? fallbackName;
}
