import '../../data/models/maintenance_record.dart';
import '../../data/models/trip_plan.dart';
import '../../data/models/vehicle_profile.dart';
import '../../data/repositories/local_checklist_repository.dart';
import '../../data/repositories/local_maintenance_repository.dart';
import '../../data/repositories/local_trip_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';
import '../../data/repositories/local_vehicle_profile_repository.dart';

class HomeCockpitSnapshot {
  const HomeCockpitSnapshot({
    required this.vehicle,
    required this.checklistTotal,
    required this.checklistCompleted,
    required this.documentCount,
    required this.expiredDocuments,
    required this.documentsDueSoon,
    required this.maintenanceCount,
    required this.overdueMaintenance,
    required this.maintenanceDueSoon,
    required this.activeTrip,
    required this.readinessScore,
    required this.readinessCoverage,
    required this.actions,
  });

  final VehicleProfile? vehicle;
  final int checklistTotal;
  final int checklistCompleted;
  final int documentCount;
  final int expiredDocuments;
  final int documentsDueSoon;
  final int maintenanceCount;
  final int overdueMaintenance;
  final int maintenanceDueSoon;
  final TripPlan? activeTrip;
  final int? readinessScore;
  final int readinessCoverage;
  final List<HomeCockpitAction> actions;

  int get checklistOpen => checklistTotal - checklistCompleted;
}

enum HomeCockpitActionType {
  vehicle,
  checklist,
  documents,
  maintenance,
  trip,
}

class HomeCockpitAction {
  const HomeCockpitAction({
    required this.type,
    required this.title,
    required this.detail,
    required this.priority,
  });

  final HomeCockpitActionType type;
  final String title;
  final String detail;
  final int priority;
}

class HomeCockpitService {
  HomeCockpitService({
    VehicleProfileRepository? vehicleRepository,
    ChecklistRepository? checklistRepository,
    VehicleDocumentRepository? documentRepository,
    MaintenanceRepository? maintenanceRepository,
    TripRepository? tripRepository,
    DateTime Function()? clock,
  })  : _vehicleRepository =
            vehicleRepository ?? LocalVehicleProfileRepository(),
        _checklistRepository =
            checklistRepository ?? LocalChecklistRepository(),
        _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? LocalMaintenanceRepository(),
        _tripRepository = tripRepository ?? LocalTripRepository(),
        _clock = clock ?? DateTime.now;

  final VehicleProfileRepository _vehicleRepository;
  final ChecklistRepository _checklistRepository;
  final VehicleDocumentRepository _documentRepository;
  final MaintenanceRepository _maintenanceRepository;
  final TripRepository _tripRepository;
  final DateTime Function() _clock;

  Future<HomeCockpitSnapshot> load() async {
    final vehicle = await _vehicleRepository.loadProfile();
    final checklist = await _checklistRepository.listItems();
    final documents = await _documentRepository.listDocuments();
    final maintenance = await _maintenanceRepository.listRecords();
    final trips = await _tripRepository.listTrips();
    final now = _clock();

    final checklistCompleted =
        checklist.where((item) => item.checked).length;

    var expiredDocuments = 0;
    var documentsDueSoon = 0;
    for (final document in documents) {
      final expiryDate = document.expiryDate;
      if (expiryDate == null) continue;
      if (!expiryDate.isAfter(now)) {
        expiredDocuments++;
      } else if (expiryDate.difference(now).inDays <= 30) {
        documentsDueSoon++;
      }
    }

    var overdueMaintenance = 0;
    var maintenanceDueSoon = 0;
    for (final record in maintenance) {
      final status = record.status(
        now: now,
        currentMileage: vehicle?.mileage,
      );
      switch (status) {
        case MaintenanceStatus.overdue:
          overdueMaintenance++;
        case MaintenanceStatus.dueSoon:
          maintenanceDueSoon++;
        case MaintenanceStatus.regular:
          break;
      }
    }

    final activeTrip = _selectActiveTrip(trips, now);
    final readiness = _calculateReadiness(
      hasVehicle: vehicle != null,
      checklistTotal: checklist.length,
      checklistCompleted: checklistCompleted,
      documentCount: documents.length,
      expiredDocuments: expiredDocuments,
      documentsDueSoon: documentsDueSoon,
      maintenanceCount: maintenance.length,
      overdueMaintenance: overdueMaintenance,
      maintenanceDueSoon: maintenanceDueSoon,
      activeTrip: activeTrip,
    );

    final actions = _buildActions(
      hasVehicle: vehicle != null,
      checklistTotal: checklist.length,
      checklistCompleted: checklistCompleted,
      documentCount: documents.length,
      expiredDocuments: expiredDocuments,
      documentsDueSoon: documentsDueSoon,
      maintenanceCount: maintenance.length,
      overdueMaintenance: overdueMaintenance,
      maintenanceDueSoon: maintenanceDueSoon,
      activeTrip: activeTrip,
    )..sort((a, b) => b.priority.compareTo(a.priority));

    return HomeCockpitSnapshot(
      vehicle: vehicle,
      checklistTotal: checklist.length,
      checklistCompleted: checklistCompleted,
      documentCount: documents.length,
      expiredDocuments: expiredDocuments,
      documentsDueSoon: documentsDueSoon,
      maintenanceCount: maintenance.length,
      overdueMaintenance: overdueMaintenance,
      maintenanceDueSoon: maintenanceDueSoon,
      activeTrip: activeTrip,
      readinessScore: readiness.score,
      readinessCoverage: readiness.coverage,
      actions: actions.take(4).toList(growable: false),
    );
  }

  TripPlan? _selectActiveTrip(List<TripPlan> trips, DateTime now) {
    if (trips.isEmpty) return null;

    final upcoming = trips.where((trip) {
      final end = trip.endDate;
      return end == null || !end.isBefore(DateTime(now.year, now.month, now.day));
    }).toList()
      ..sort((a, b) {
        final aDate = a.startDate ?? DateTime(2100);
        final bDate = b.startDate ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

    return upcoming.isNotEmpty ? upcoming.first : trips.first;
  }

  ({int? score, int coverage}) _calculateReadiness({
    required bool hasVehicle,
    required int checklistTotal,
    required int checklistCompleted,
    required int documentCount,
    required int expiredDocuments,
    required int documentsDueSoon,
    required int maintenanceCount,
    required int overdueMaintenance,
    required int maintenanceDueSoon,
    required TripPlan? activeTrip,
  }) {
    var availableWeight = 0.0;
    var earnedWeight = 0.0;

    if (hasVehicle) {
      availableWeight += 20;
      earnedWeight += 20;
    }

    if (checklistTotal > 0) {
      availableWeight += 30;
      earnedWeight += 30 * (checklistCompleted / checklistTotal);
    }

    if (documentCount > 0) {
      availableWeight += 20;
      if (expiredDocuments == 0 && documentsDueSoon == 0) {
        earnedWeight += 20;
      } else if (expiredDocuments == 0) {
        earnedWeight += 10;
      }
    }

    if (maintenanceCount > 0) {
      availableWeight += 20;
      if (overdueMaintenance == 0 && maintenanceDueSoon == 0) {
        earnedWeight += 20;
      } else if (overdueMaintenance == 0) {
        earnedWeight += 10;
      }
    }

    if (activeTrip != null) {
      availableWeight += 10;
      earnedWeight += activeTrip.stages.length >= 2 ? 10 : 5;
    }

    final coverage = availableWeight.round();
    if (availableWeight < 50) {
      return (score: null, coverage: coverage);
    }

    return (
      score: ((earnedWeight / availableWeight) * 100).round().clamp(0, 100),
      coverage: coverage,
    );
  }

  List<HomeCockpitAction> _buildActions({
    required bool hasVehicle,
    required int checklistTotal,
    required int checklistCompleted,
    required int documentCount,
    required int expiredDocuments,
    required int documentsDueSoon,
    required int maintenanceCount,
    required int overdueMaintenance,
    required int maintenanceDueSoon,
    required TripPlan? activeTrip,
  }) {
    final actions = <HomeCockpitAction>[];

    if (!hasVehicle) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.vehicle,
          title: 'Set up your camper',
          detail: 'Add dimensions, mass and mileage before route planning.',
          priority: 100,
        ),
      );
    }

    if (checklistTotal == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.checklist,
          title: 'Create a departure checklist',
          detail: 'Readiness stays honest until you define your real routine.',
          priority: 70,
        ),
      );
    } else if (checklistCompleted < checklistTotal) {
      final openCount = checklistTotal - checklistCompleted;
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.checklist,
          title: '$openCount checklist item${openCount == 1 ? '' : 's'} open',
          detail: '$checklistCompleted of $checklistTotal checks completed.',
          priority: 85,
        ),
      );
    }

    if (expiredDocuments > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          title: '$expiredDocuments document${expiredDocuments == 1 ? '' : 's'} expired',
          detail: 'Review vehicle documents before departure.',
          priority: 95,
        ),
      );
    } else if (documentsDueSoon > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          title: '$documentsDueSoon document${documentsDueSoon == 1 ? '' : 's'} due soon',
          detail: 'Expiry is within the next 30 days.',
          priority: 80,
        ),
      );
    } else if (documentCount == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          title: 'Document archive not configured',
          detail: 'Add insurance, registration or other documents when useful.',
          priority: 35,
        ),
      );
    }

    if (overdueMaintenance > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          title: '$overdueMaintenance maintenance item${overdueMaintenance == 1 ? '' : 's'} overdue',
          detail: 'Review date or mileage based maintenance.',
          priority: 95,
        ),
      );
    } else if (maintenanceDueSoon > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          title: '$maintenanceDueSoon maintenance item${maintenanceDueSoon == 1 ? '' : 's'} due soon',
          detail: 'Due within 30 days or 1,000 km.',
          priority: 80,
        ),
      );
    } else if (maintenanceCount == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          title: 'Maintenance history not configured',
          detail: 'Add your first service record when available.',
          priority: 30,
        ),
      );
    }

    if (activeTrip == null) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.trip,
          title: 'No upcoming trip',
          detail: 'Create a real itinerary when you are ready to travel.',
          priority: 25,
        ),
      );
    } else if (activeTrip.stages.length < 2) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.trip,
          title: 'Complete ${activeTrip.title}',
          detail: 'Add at least two geolocated stages for routing.',
          priority: 65,
        ),
      );
    }

    return actions;
  }
}
