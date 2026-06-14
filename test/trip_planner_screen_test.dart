import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/features/trip/presentation/trip_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets('trip planner edits, creates, and deletes saved trips', (
    tester,
  ) async {
    final repository = FakeTripRepository([
      const TripPlan(
        id: 1,
        title: 'Alps loop',
        summary: 'Three days',
        progress: 0.2,
        stages: ['Stage 1'],
        overnightStop: 'Lake stop',
        estimatedCost: 120,
        notes: 'Carry chains',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: TripPlannerScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alps loop'), findsOneWidget);
    expect(find.text('EUR 120'), findsOneWidget);

    await tester.tap(find.text('Edit trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Updated Alps loop');
    await tester.enterText(find.byType(TextField).at(2), 'Stage 1\nStage 2');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.trips.single.title, 'Updated Alps loop');
    expect(repository.trips.single.stages, ['Stage 1', 'Stage 2']);

    await tester.tap(find.byTooltip('Add trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Coast weekend');
    await tester.enterText(find.byType(TextField).at(1), 'Two nights');
    await tester.enterText(find.byType(TextField).at(2), 'Beach stop');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.trips.length, 2);
    expect(find.text('Coast weekend'), findsWidgets);

    await tester.tap(find.byTooltip('Delete trip'));
    await tester.pumpAndSettle();

    expect(repository.trips.length, 1);
    expect(find.text('Coast weekend'), findsNothing);
  });
}
