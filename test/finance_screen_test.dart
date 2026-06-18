import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/core/services/reminder_coordinator.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/route_preview.dart';
import 'package:camperboss/data/models/trip_plan.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_finance_repository.dart';
import 'package:camperboss/data/repositories/local_route_preview_repository.dart';
import 'package:camperboss/data/repositories/local_trip_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:camperboss/features/finance/presentation/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository({
    required this.expenses,
    required this.fuelEntries,
    required this.bookings,
    this.budget,
  });

  final List<Expense> expenses;
  final List<FuelEntry> fuelEntries;
  final List<TripBooking> bookings;
  TripBudget? budget;

  @override
  Future<void> deleteBooking(String id) async {}

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<void> deleteFuelEntry(String id) async {}

  @override
  Future<void> deleteTripBudget(int tripId) async {}

  @override
  Future<List<TripBooking>> listBookings() async => bookings;

  @override
  Future<List<Expense>> listExpenses() async => expenses;

  @override
  Future<List<FuelEntry>> listFuelEntries() async => fuelEntries;

  @override
  Future<TripBudget?> loadTripBudget(int tripId) async => budget;

  @override
  Future<TripBooking> saveBooking(TripBooking booking) async => booking;

  @override
  Future<Expense> saveExpense(Expense expense) async => expense;

  @override
  Future<FuelEntry> saveFuelEntry(FuelEntry entry) async => entry;

  @override
  Future<void> saveTripBudget(TripBudget budget) async {
    this.budget = budget;
  }
}

class FakeTripRepository implements TripRepository {
  FakeTripRepository(this.trips);

  final List<TripPlan> trips;

  @override
  Future<void> deleteTrip(int id) async {}

  @override
  Future<List<TripPlan>> listTrips() async => trips;

  @override
  Future<TripPlan> saveTrip(TripPlan trip) async => trip;
}

class FakeRoutePreviewRepository implements RoutePreviewRepository {
  FakeRoutePreviewRepository(this.route);

  final RouteResult? route;

  @override
  Future<void> deleteRouteForTrip(int tripId) async {}

  @override
  Future<RouteResult?> loadRouteForTrip(int tripId) async => route;

  @override
  Future<RouteResult> saveRoute(RouteResult route) async => route;
}

class FakeVehicleProfileStore implements VehicleProfileStore {
  FakeVehicleProfileStore(this.profile);

  final VehicleProfile? profile;

  @override
  Future<void> deleteProfile() async {}

  @override
  Future<VehicleProfile?> loadProfile() async => profile;

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile vehicleProfile) async =>
      vehicleProfile;
}

class FakeDocumentRepository implements VehicleDocumentRepository {
  FakeDocumentRepository(this.documents);

  final List<VehicleDocument> documents;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {}

  @override
  Future<List<VehicleDocument>> listDocuments() async => documents;

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async =>
      document;
}

class FakeReminderService implements ReminderSyncService {
  @override
  Future<void> deleteBookingReminders(String sourceId) async {}

  @override
  Future<void> deleteDocumentReminders(String sourceId) async {}

  @override
  Future<void> deleteMaintenanceReminders(String sourceId) async {}

  @override
  Future<void> syncBooking(TripBooking booking) async {}

  @override
  Future<void> syncDocument(VehicleDocument document) async {}

  @override
  Future<void> syncMaintenance(record) async {}
}

void main() {
  testWidgets('finance screen shows local summaries and bookings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinanceScreen(
            financeRepository: FakeFinanceRepository(
              expenses: [
                Expense(
                  id: 'e1',
                  scope: ExpenseScope.trip,
                  tripId: 9,
                  category: ExpenseCategory.food,
                  amountMinor: 2500,
                  currencyCode: 'EUR',
                  occurredAt: DateTime(2026, 8, 1),
                  title: 'Groceries',
                  documentId: 101,
                ),
              ],
              fuelEntries: [
                FuelEntry(
                  id: 'f1',
                  vehicleId: 1,
                  tripId: 9,
                  date: DateTime(2026, 8, 2),
                  odometerKm: 12000,
                  volumeMilliLitres: 40000,
                  totalCostMinor: 7200,
                  currencyCode: 'EUR',
                  fullTank: true,
                  station: 'Station A',
                ),
              ],
              bookings: [
                TripBooking(
                  id: 'b1',
                  tripId: 9,
                  type: BookingType.campsite,
                  status: BookingStatus.confirmed,
                  title: 'Lake Camp',
                  startsAt: DateTime(2026, 8, 3),
                  costMinor: 10000,
                  currencyCode: 'EUR',
                  address: 'Via Lago 1',
                  documentId: 101,
                ),
              ],
              budget: const TripBudget(
                tripId: 9,
                plannedAmountMinor: 30000,
                currencyCode: 'EUR',
              ),
            ),
            tripRepository: FakeTripRepository([
              TripPlan(
                id: 9,
                title: 'August trip',
                summary: 'Weekend',
                progress: 0.5,
                startDate: DateTime(2026, 8, 1),
                endDate: DateTime(2026, 8, 3),
              ),
            ]),
            routePreviewRepository: FakeRoutePreviewRepository(
              RouteResult(
                tripId: 9,
                waypointFingerprint: 'route-9',
                geometry: [],
                totalDistanceMeters: 100000,
                totalDurationSeconds: 7200,
                legs: [],
                provider: 'test',
                calculatedAt: DateTime(2026, 8, 1),
              ),
            ),
            profileRepository: LocalVehicleProfileRepository(
              store: FakeVehicleProfileStore(
                const VehicleProfile(
                  id: 1,
                  vehicleType: 'Motorhome',
                  brand: 'Fiat',
                  model: 'Ducato',
                  year: 2023,
                  length: 7.0,
                  width: 2.3,
                  height: 3.0,
                  weight: 3100,
                  maxMass: 3500,
                  seats: 4,
                  fuelType: 'Diesel',
                  mileage: 12000,
                ),
              ),
            ),
            documentRepository: FakeDocumentRepository([
              VehicleDocument(
                id: 101,
                category: 'invoice',
                title: 'Camping invoice',
                localFilePath: '/private/camping.pdf',
                mimeType: 'application/pdf',
                ocrStatus: DocumentOcrStatus.notRequested,
              ),
            ]),
            reminderService: FakeReminderService(),
            initialTripId: 9,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add fuel'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Add booking'), findsOneWidget);
  });
}
