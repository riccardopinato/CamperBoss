import 'package:camperboss/core/services/travel_history_service.dart';
import 'package:camperboss/data/models/travel_history_models.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/features/trip/presentation/travel_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_localization.dart';

void main() {
  testWidgets(
      'travel history screen renders timeline summary and memory filters', (
    tester,
  ) async {
    await pumpLocalizedHome(
      tester,
      home: Scaffold(
        body: TravelHistoryScreen(
            initialTripId: 1,
            tripRepository: _FakeTripRepository(),
            historyService: _FakeTravelHistoryService(),
            renderMaps: false,
        ),
      ),
    );

    expect(find.text('Travel history'), findsOneWidget);
    expect(find.text('Import GPX'), findsOneWidget);
    expect(find.text('Alps memory'), findsOneWidget);
    expect(find.text('Scenic route'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('From'), findsOneWidget);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
  });
}

class _FakeTripRepository implements TripRepository {
  @override
  Future<void> deleteTrip(int id) async {}

  @override
  Future<List<TripPlan>> listTrips() async => const [
        TripPlan(
          id: 1,
          title: 'Summer trip',
          summary: 'North Italy',
          progress: 0.8,
          stages: ['Verona | 45.4384, 10.9916'],
        ),
      ];

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async => trip;
}

class _FakeTravelHistoryService extends TravelHistoryService {
  @override
  Future<TravelHistoryBundle> load({int? tripId}) async {
    return TravelHistoryBundle(
      tracks: [
        GpxTrack(
          id: 'track-1',
          tripId: 1,
          name: 'Scenic route',
          points: const [
            GeoPoint(latitude: 45.0, longitude: 10.0),
            GeoPoint(latitude: 45.1, longitude: 10.1),
          ],
          distanceMeters: 14500,
          duration: const Duration(minutes: 40),
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
      ],
      memories: [
        TravelMemory(
          id: 'memory-1',
          tripId: 1,
          title: 'Alps memory',
          description: 'Lake view',
          latitude: 45.2,
          longitude: 10.2,
          occurredAt: DateTime(2026, 6, 2),
          tags: {'nature'},
        ),
      ],
      stats: const TravelHistoryStats(
        distanceMeters: 14500,
        trackDays: 2,
        placeCount: 1,
        totalCostMinor: 3200,
        totalFuelLiters: 9,
        duration: Duration(minutes: 40),
        averageSpeedKmh: 21.75,
      ),
    );
  }
}
