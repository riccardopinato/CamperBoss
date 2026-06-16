import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/models/maintenance_record.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
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

  test('vehicle documents serialize metadata and private file paths', () {
    final issueDate = DateTime.utc(2026, 1, 1);
    final expiryDate = DateTime.utc(2027, 1, 1);
    final document = VehicleDocument(
      id: 9,
      vehicleId: 1,
      category: 'Insurance',
      title: 'Policy 2026',
      localFilePath: '/private/policy.pdf',
      pagePaths: const ['/private/page-1.jpg', '/private/page-2.jpg'],
      pdfPath: '/private/policy.pdf',
      thumbnailPath: '/private/page-1.jpg',
      mimeType: 'application/pdf',
      pageCount: 2,
      fileSize: 2048,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: 'Confirmed fields only.',
      extractedText: 'Policy number 123',
      ocrLanguage: 'latin',
      ocrStatus: DocumentOcrStatus.ready,
    );

    final restored = VehicleDocument.fromMap(document.toMap());

    expect(restored.id, 9);
    expect(restored.vehicleId, 1);
    expect(restored.category, 'Insurance');
    expect(restored.title, 'Policy 2026');
    expect(restored.localFilePath, '/private/policy.pdf');
    expect(restored.pagePaths, ['/private/page-1.jpg', '/private/page-2.jpg']);
    expect(restored.pdfPath, '/private/policy.pdf');
    expect(restored.thumbnailPath, '/private/page-1.jpg');
    expect(restored.mimeType, 'application/pdf');
    expect(restored.pageCount, 2);
    expect(restored.fileSize, 2048);
    expect(restored.issueDate, issueDate);
    expect(restored.expiryDate, expiryDate);
    expect(restored.notes, 'Confirmed fields only.');
    expect(restored.extractedText, 'Policy number 123');
    expect(restored.ocrLanguage, 'latin');
    expect(restored.ocrStatus, DocumentOcrStatus.ready);
    expect(restored.matches('policy number'), isTrue);
  });

  test('maintenance records serialize intervals and calculate status', () {
    final record = MaintenanceRecord(
      id: 12,
      category: 'Oil',
      title: 'Oil and filter',
      date: DateTime.utc(2026, 1, 10),
      mileage: 20000,
      cost: 180,
      provider: 'Garage Rossi',
      notes: 'Use approved oil.',
      intervalMonths: 12,
      intervalKilometers: 15000,
      nextDueDate: DateTime.utc(2026, 7, 1),
      nextDueMileage: 35000,
      attachmentPaths: const ['/private/invoice.pdf'],
    );

    final restored = MaintenanceRecord.fromMap(record.toMap());

    expect(restored.id, 12);
    expect(restored.category, 'Oil');
    expect(restored.title, 'Oil and filter');
    expect(restored.mileage, 20000);
    expect(restored.provider, 'Garage Rossi');
    expect(restored.intervalMonths, 12);
    expect(restored.intervalKilometers, 15000);
    expect(restored.nextDueMileage, 35000);
    expect(restored.attachmentPaths, ['/private/invoice.pdf']);
    expect(
      restored.status(now: DateTime.utc(2026, 6, 10)),
      MaintenanceStatus.dueSoon,
    );
    expect(
      restored.status(now: DateTime.utc(2026, 7, 2)),
      MaintenanceStatus.overdue,
    );
  });
}
