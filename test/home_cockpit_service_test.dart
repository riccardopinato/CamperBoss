import 'package:camperboss/core/services/home_cockpit_service.dart';
import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/models/maintenance_record.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_checklist_repository.dart';
import 'package:camperboss/data/repositories/local_maintenance_repository.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28);

  test('does not invent readiness when too little real data exists', () async {
    final service = HomeCockpitService(
      vehicleRepository: _VehicleRepo(null),
      checklistRepository: _ChecklistRepo(const []),
      documentRepository: _DocumentRepo(const []),
      maintenanceRepository: _MaintenanceRepo(const []),
      tripRepository: _TripRepo(const []),
      clock: () => now,
    );

    final snapshot = await service.load();

    expect(snapshot.readinessScore, isNull);
    expect(snapshot.readinessCoverage, 0);
    expect(
      snapshot.actions.any(
        (action) => action.type == HomeCockpitActionType.vehicle,
      ),
      isTrue,
    );
  });

  test('calculates readiness only from configured local signals', () async {
    final service = HomeCockpitService(
      vehicleRepository: _VehicleRepo(
        VehicleProfile(
          vehicleType: 'Camper',
          brand: 'Test',
          model: 'One',
          year: 2024,
          length: 6,
          width: 2.2,
          height: 2.8,
          weight: 3000,
          maxMass: 3500,
          seats: 4,
          fuelType: 'Diesel',
          mileage: 42000,
        ),
      ),
      checklistRepository: _ChecklistRepo(
        const [
          CamperChecklistItem(title: 'Tyres', checked: true),
          CamperChecklistItem(title: 'Fridge', checked: true),
        ],
      ),
      documentRepository: _DocumentRepo(const []),
      maintenanceRepository: _MaintenanceRepo(
        [
          MaintenanceRecord(
            category: 'Service',
            title: 'Oil',
            date: DateTime(2026, 6, 1),
            mileage: 40000,
            nextDueDate: DateTime(2027, 6, 1),
            nextDueMileage: 55000,
          ),
        ],
      ),
      tripRepository: _TripRepo(
        const [
          TripPlan(
            title: 'Weekend',
            summary: 'Real trip',
            progress: 0.5,
            stages: [
              'Start | 45.0, 11.0',
              'Stop | 46.0, 12.0',
            ],
          ),
        ],
      ),
      clock: () => now,
    );

    final snapshot = await service.load();

    expect(snapshot.readinessCoverage, 80);
    expect(snapshot.readinessScore, 100);
    expect(snapshot.checklistOpen, 0);
    expect(snapshot.overdueMaintenance, 0);
  });
}

class _VehicleRepo implements VehicleProfileRepository {
  _VehicleRepo(this.value);

  final VehicleProfile? value;

  @override
  Future<void> deleteProfile() async {}

  @override
  Future<VehicleProfile?> loadProfile() async => value;

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile profile) async => profile;
}

class _ChecklistRepo implements ChecklistRepository {
  _ChecklistRepo(this.items);

  final List<CamperChecklistItem> items;

  @override
  Future<void> deleteItem(int id) async {}

  @override
  Future<List<CamperChecklistItem>> listItems() async => items;

  @override
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async => item;
}

class _DocumentRepo implements VehicleDocumentRepository {
  _DocumentRepo(this.items);

  final List<VehicleDocument> items;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {}

  @override
  Future<List<VehicleDocument>> listDocuments() async => items;

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async =>
      document;
}

class _MaintenanceRepo implements MaintenanceRepository {
  _MaintenanceRepo(this.items);

  final List<MaintenanceRecord> items;

  @override
  Future<void> deleteRecord(int id) async {}

  @override
  Future<List<MaintenanceRecord>> listRecords() async => items;

  @override
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record) async =>
      record;
}

class _TripRepo implements TripRepository {
  _TripRepo(this.items);

  final List<TripPlan> items;

  @override
  Future<void> deleteTrip(int id) async {}

  @override
  Future<List<TripPlan>> listTrips() async => items;

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async => trip;
}
