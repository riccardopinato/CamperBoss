import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('checklist items serialize database fields', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 12);
    final item = CamperChecklistItem(
      id: 7,
      title: 'Check water',
      subtitle: 'Before departure',
      category: 'Departure',
      checked: true,
      position: 2,
      updatedAt: updatedAt,
    );

    final restored = CamperChecklistItem.fromMap(item.toMap());

    expect(restored.id, 7);
    expect(restored.title, 'Check water');
    expect(restored.checked, isTrue);
    expect(restored.category, 'Departure');
    expect(restored.position, 2);
    expect(restored.updatedAt, updatedAt);
  });

  test('trip plans serialize optional planning fields', () {
    final startDate = DateTime.utc(2026, 7, 1);
    final endDate = DateTime.utc(2026, 7, 5);
    final trip = TripPlan(
      id: 3,
      title: 'Alps loop',
      summary: 'Five days',
      progress: 0.4,
      startDate: startDate,
      endDate: endDate,
      notes: 'Avoid tolls',
    );

    final restored = TripPlan.fromMap(trip.toMap());

    expect(restored.id, 3);
    expect(restored.progress, 0.4);
    expect(restored.startDate, startDate);
    expect(restored.endDate, endDate);
    expect(restored.notes, 'Avoid tolls');
  });

  test('journal entries serialize location and dates', () {
    final createdAt = DateTime.utc(2026, 8, 10, 18);
    final entry = JournalEntry(
      id: 5,
      title: 'Lake stop',
      summary: 'Quiet evening',
      createdAt: createdAt,
      latitude: 45.6,
      longitude: 10.7,
    );

    final restored = JournalEntry.fromMap(entry.toMap());

    expect(restored.id, 5);
    expect(restored.createdAt, createdAt);
    expect(restored.latitude, 45.6);
    expect(restored.longitude, 10.7);
  });
}
