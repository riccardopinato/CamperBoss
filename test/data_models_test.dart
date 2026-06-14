import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('checklist items serialize database fields', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 12);
    final item = CamperChecklistItem(
      id: 7,
      title: 'Check water',
      subtitle: 'Before departure',
      listName: 'Departure list',
      category: 'Departure',
      checked: true,
      position: 2,
      updatedAt: updatedAt,
    );

    final restored = CamperChecklistItem.fromMap(item.toMap());

    expect(restored.id, 7);
    expect(restored.title, 'Check water');
    expect(restored.checked, isTrue);
    expect(restored.listName, 'Departure list');
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
      destination: 'Dolomites',
      summary: 'Five days',
      progress: 0.4,
      startDate: startDate,
      endDate: endDate,
      notes: 'Avoid tolls',
    );

    final restored = TripPlan.fromMap(trip.toMap());

    expect(restored.id, 3);
    expect(restored.destination, 'Dolomites');
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
      place: 'Lake Garda',
      kilometers: 120,
      cost: 45,
      latitude: 45.6,
      longitude: 10.7,
    );

    final restored = JournalEntry.fromMap(entry.toMap());

    expect(restored.id, 5);
    expect(restored.createdAt, createdAt);
    expect(restored.place, 'Lake Garda');
    expect(restored.kilometers, 120);
    expect(restored.cost, 45);
    expect(restored.latitude, 45.6);
    expect(restored.longitude, 10.7);
  });

  test('vehicle profiles serialize size, tanks, and mileage fields', () {
    final updatedAt = DateTime.utc(2026, 9, 1, 9);
    final profile = VehicleProfile(
      id: 8,
      vehicleType: 'Motorhome',
      brand: 'Fiat',
      model: 'Ducato',
      year: 2022,
      plate: 'AB123CD',
      length: 7.2,
      width: 2.35,
      height: 3.05,
      weight: 3100,
      maxMass: 3500,
      seats: 4,
      fuelType: 'Diesel',
      mileage: 18400,
      fuelCapacity: 90,
      waterCapacity: 120,
      gasCapacity: 11,
      electricRange: 65,
      notes: 'Keep payload margin for bikes.',
      updatedAt: updatedAt,
    );

    final restored = VehicleProfile.fromMap(profile.toMap());

    expect(restored.id, 8);
    expect(restored.vehicleType, 'Motorhome');
    expect(restored.brand, 'Fiat');
    expect(restored.model, 'Ducato');
    expect(restored.plate, 'AB123CD');
    expect(restored.length, 7.2);
    expect(restored.maxMass, 3500);
    expect(restored.fuelType, 'Diesel');
    expect(restored.fuelCapacity, 90);
    expect(restored.notes, 'Keep payload margin for bikes.');
    expect(restored.updatedAt, updatedAt);
  });
}
