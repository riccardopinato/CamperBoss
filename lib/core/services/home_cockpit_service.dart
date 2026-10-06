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
    required this.titleKey,
    required this.detailKey,
    required this.priority,
    this.args = const {},
  });

  final HomeCockpitActionType type;
  final String titleKey;
  final String detailKey;
  final int priority;
  final Map<String, String> args;
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
          break;
        case MaintenanceStatus.dueSoon:
          maintenanceDueSoon++;
          break;
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
      score: ((earnedWeight / availableWeight) * 100)
          .round()
          .clamp(0, 100)
          .toInt(),
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
          titleKey: 'home_action_vehicle_title',
          detailKey: 'home_action_vehicle_detail',
          priority: 100,
        ),
      );
    }

    if (checklistTotal == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.checklist,
          titleKey: 'home_action_checklist_create_title',
          detailKey: 'home_action_checklist_create_detail',
          priority: 70,
        ),
      );
    } else if (checklistCompleted < checklistTotal) {
      final openCount = checklistTotal - checklistCompleted;
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.checklist,
          titleKey: 'home_action_checklist_open_title',
          detailKey: 'home_action_checklist_open_detail',
          args: {
            'open': openCount.toString(),
            'completed': checklistCompleted.toString(),
            'total': checklistTotal.toString(),
          },
          priority: 85,
        ),
      );
    }

    if (expiredDocuments > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          titleKey: 'home_action_documents_expired_title',
          detailKey: 'home_action_documents_expired_detail',
          args: {'count': expiredDocuments.toString()},
          priority: 95,
        ),
      );
    } else if (documentsDueSoon > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          titleKey: 'home_action_documents_due_title',
          detailKey: 'home_action_documents_due_detail',
          args: {'count': documentsDueSoon.toString()},
          priority: 80,
        ),
      );
    } else if (documentCount == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.documents,
          titleKey: 'home_action_documents_empty_title',
          detailKey: 'home_action_documents_empty_detail',
          priority: 35,
        ),
      );
    }

    if (overdueMaintenance > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          titleKey: 'home_action_maintenance_overdue_title',
          detailKey: 'home_action_maintenance_overdue_detail',
          args: {'count': overdueMaintenance.toString()},
          priority: 95,
        ),
      );
    } else if (maintenanceDueSoon > 0) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          titleKey: 'home_action_maintenance_due_title',
          detailKey: 'home_action_maintenance_due_detail',
          args: {'count': maintenanceDueSoon.toString()},
          priority: 80,
        ),
      );
    } else if (maintenanceCount == 0) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.maintenance,
          titleKey: 'home_action_maintenance_empty_title',
          detailKey: 'home_action_maintenance_empty_detail',
          priority: 30,
        ),
      );
    }

    if (activeTrip == null) {
      actions.add(
        const HomeCockpitAction(
          type: HomeCockpitActionType.trip,
          titleKey: 'home_action_trip_empty_title',
          detailKey: 'home_action_trip_empty_detail',
          priority: 25,
        ),
      );
    } else if (activeTrip.stages.length < 2) {
      actions.add(
        HomeCockpitAction(
          type: HomeCockpitActionType.trip,
          titleKey: 'home_action_trip_incomplete_title',
          detailKey: 'home_action_trip_incomplete_detail',
          args: {'trip': activeTrip.title},
          priority: 65,
        ),
      );
    }

    return actions;
  }
}
