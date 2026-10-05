import 'package:camperboss/core/services/routing_service.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/repositories/local_route_preview_repository.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/features/trip/presentation/trip_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_localization.dart';

class FakeTripRepository implements TripRepository {
  FakeTripRepository(this.trips);

  final List<TripPlan> trips;
  var nextId = 20;

  @override
  Future<List<TripPlan>> listTrips() async => [...trips];

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async {
    final saved = trip.id == null ? trip.copyWith(id: nextId++) : trip;
    final index = trips.indexWhere((entry) => entry.id == saved.id);
    if (index == -1) {
      trips.insert(0, saved);
    } else {
      trips[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteTrip(int id) async {
    trips.removeWhere((entry) => entry.id == id);
  }
}

class FakeRoutePreviewRepository implements RoutePreviewRepository {
  RouteResult? route;

  @override
  Future<List<RouteResult>> listRoutes() async =>
      route == null ? const [] : [route!];

  @override
  Future<void> deleteRouteForTrip(int tripId) async {
    if (route?.tripId == tripId) route = null;
  }

  @override
  Future<RouteResult?> loadRouteForTrip(int tripId) async {
    return route?.tripId == tripId ? route : null;
  }

  @override
  Future<RouteResult> saveRoute(RouteResult route) async {
    this.route = route;
    return route;
  }
}

void main() {
  testWidgets('trip planner edits, creates, and deletes saved trips', (
    tester,
  ) async {
    final repository = FakeTripRepository([
      const TripPlan(
        id: 1,
        title: 'Alps loop',
        destination: 'Dolomites',
        summary: 'Three days',
        progress: 0.2,
        stages: ['Stage 1'],
        overnightStop: 'Lake stop',
        estimatedCost: 120,
        notes: 'Carry chains',
      ),
    ]);

    await pumpLocalizedHome(
      tester,
      home: TripPlannerScreen(
          repository: repository,
          routePreviewRepository: FakeRoutePreviewRepository(),
          renderMaps: false,
      ),
    );

    expect(find.text('Alps loop'), findsOneWidget);
    expect(find.textContaining('Dolomites'), findsOneWidget);

    await tester.tap(find.text('Edit trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Updated Alps loop');
    await tester.enterText(find.byType(TextField).at(1), 'Swiss Alps');
    await tester.enterText(find.byType(TextField).at(3), 'Stage 1\nStage 2');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.trips.single.title, 'Updated Alps loop');
    expect(repository.trips.single.destination, 'Swiss Alps');
    expect(repository.trips.single.stages, ['Stage 1', 'Stage 2']);

    await tester.tap(find.byTooltip('Add trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Coast weekend');
    await tester.enterText(find.byType(TextField).at(1), 'Liguria');
    await tester.tap(find.byType(ExpansionTile).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), 'Two nights');
    await tester.enterText(find.byType(TextField).at(3), 'Beach stop');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.trips.length, 2);
    expect(find.text('Coast weekend'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Delete trip'));
    await tester.tap(find.byTooltip('Delete trip'));
    await tester.pumpAndSettle();
    expect(repository.trips.length, 2);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.trips.length, 1);
    expect(find.text('Coast weekend'), findsNothing);
  });

  testWidgets('trip planner calculates and saves route preview', (
    tester,
  ) async {
    final repository = FakeTripRepository([
      const TripPlan(
        id: 2,
        title: 'Garda route',
        destination: 'Lake Garda',
        summary: 'Two stops',
        progress: 0.5,
        stages: [
          'Sirmione | 45.4927, 10.6087',
          'Bardolino | 45.5485, 10.7205',
        ],
      ),
    ]);
    final routeRepository = FakeRoutePreviewRepository();

    await pumpLocalizedHome(
      tester,
      home: TripPlannerScreen(
          repository: repository,
          routePreviewRepository: routeRepository,
          routingService: const FakeRoutingService(),
          isRoutingConfigured: true,
          renderMaps: false,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Route preview'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Route preview'), findsOneWidget);
    expect(find.text('Calculate route'), findsOneWidget);
    await tester.ensureVisible(find.text('Calculate route'));
    await tester.tap(find.text('Calculate route'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(routeRepository.route, isNotNull);
    expect(find.text('12 km'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.textContaining('Sirmione -> Bardolino'), findsOneWidget);
  });

  testWidgets('trip planner disables routing when API key is absent', (
    tester,
  ) async {
    final repository = FakeTripRepository([
      const TripPlan(
        id: 3,
        title: 'Offline route',
        summary: 'Two stops',
        progress: 0.5,
        stages: [
          'Verona | 45.4384, 10.9916',
          'Molveno | 46.1427, 10.9630',
        ],
      ),
    ]);

    await pumpLocalizedHome(
      tester,
      home: TripPlannerScreen(
          repository: repository,
          routePreviewRepository: FakeRoutePreviewRepository(),
          routingService: const FakeRoutingService(),
          isRoutingConfigured: false,
          renderMaps: false,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Route preview'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Calculate route'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Routing not configured'), findsOneWidget);
  });
}
