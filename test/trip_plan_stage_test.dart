import 'dart:convert';

import 'package:camperboss/data/models/trip_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy text stages remain readable', () {
    final trip = TripPlan.fromMap({
      'id': 1,
      'title': 'Legacy',
      'summary': 'Old data',
      'progress': 0.5,
      'stages': jsonEncode([
        'Verona | 45.4384, 10.9916',
        'Molveno',
      ]),
      'updated_at': DateTime(2026, 9, 29).toIso8601String(),
    });

    expect(trip.stages, hasLength(2));
    expect(trip.resolvedStages.first.isGeocoded, isTrue);
    expect(trip.resolvedStages.last.isGeocoded, isFalse);
  });

  test('structured stages round-trip without losing coordinates', () {
    const trip = TripPlan(
      id: 7,
      title: 'Dolomites',
      summary: 'Route',
      progress: 0.4,
      stageDetails: [
        TripStage(name: 'Verona', latitude: 45.4384, longitude: 10.9916),
        TripStage(name: 'Molveno', latitude: 46.1427, longitude: 10.9630),
      ],
    );

    final restored = TripPlan.fromMap(trip.toMap());
    expect(restored.resolvedStages, hasLength(2));
    expect(restored.resolvedStages.first.name, 'Verona');
    expect(restored.resolvedStages.first.latitude, closeTo(45.4384, 0.000001));
    expect(restored.stages.first, contains('45.438400'));
  });
}
