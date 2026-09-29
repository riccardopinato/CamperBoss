import '../../data/database/local_key_value_store.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/guide_models.dart';
import '../../data/repositories/local_checklist_repository.dart';
import '../../data/repositories/local_vehicle_profile_repository.dart';
import 'location_service.dart';
import 'offline_guides_service.dart';
import 'reminder_coordinator.dart';

abstract interface class OnboardingService {
  Future<OnboardingProgress> loadProgress();
  Future<void> saveProgress(OnboardingProgress progress);
  Future<void> completeStep(String stepId);
  Future<void> skipStep(String stepId);
  Future<bool> requestLocationAccess();
  Future<bool> requestNotificationAccess();
  Future<void> saveVehicleDraft({
    required String vehicleType,
    required double length,
    required double width,
    required double height,
    required double maxMass,
    required double mileage,
  });
  Future<void> finalize(OnboardingProgress progress);
}

class LocalOnboardingService implements OnboardingService {
  LocalOnboardingService({
    LocalKeyValueStore? store,
    VehicleProfileRepository? profileRepository,
    ChecklistRepository? checklistRepository,
    OfflineGuidesService? guidesService,
    LocationService? locationService,
    ReminderCoordinator? reminderCoordinator,
    Future<bool> Function()? locationPermissionRequest,
    Future<bool> Function()? notificationPermissionRequest,
  })  : _store = store ?? createLocalKeyValueStore(),
        _profileRepository =
            profileRepository ?? LocalVehicleProfileRepository(),
        _checklistRepository =
            checklistRepository ?? LocalChecklistRepository(),
        _guidesService = guidesService ?? LocalOfflineGuidesService(),
        _locationService = locationService ?? const LocationService(),
        _reminderCoordinator = reminderCoordinator ?? ReminderCoordinator(),
        _locationPermissionRequest = locationPermissionRequest,
        _notificationPermissionRequest = notificationPermissionRequest;

  static const progressKey = 'camperboss.onboardingProgress';

  final LocalKeyValueStore _store;
  final VehicleProfileRepository _profileRepository;
  final ChecklistRepository _checklistRepository;
  final OfflineGuidesService _guidesService;
  final LocationService _locationService;
  final ReminderCoordinator _reminderCoordinator;
  final Future<bool> Function()? _locationPermissionRequest;
  final Future<bool> Function()? _notificationPermissionRequest;

  @override
  Future<OnboardingProgress> loadProgress() async {
    final raw = await _store.read(progressKey);
    if (raw == null || raw.isEmpty) return OnboardingProgress.empty;
    return OnboardingProgress.fromJson(raw);
  }

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    await _store.write(progressKey, progress.toJson());
  }

  @override
  Future<void> completeStep(String stepId) async {
    final progress = await loadProgress();
    await saveProgress(
      progress.copyWith(
        completedStepIds: {...progress.completedStepIds, stepId},
        skippedStepIds: {...progress.skippedStepIds}..remove(stepId),
        currentStepId: stepId,
      ),
    );
  }

  @override
  Future<void> skipStep(String stepId) async {
    final progress = await loadProgress();
    await saveProgress(
      progress.copyWith(
        skippedStepIds: {...progress.skippedStepIds, stepId},
        currentStepId: stepId,
      ),
    );
  }

  @override
  Future<bool> requestLocationAccess() async {
    final requester = _locationPermissionRequest;
    if (requester != null) return requester();
    try {
      await _locationService.currentLocation();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationAccess() {
    final requester = _notificationPermissionRequest;
    if (requester != null) return requester();
    return _reminderCoordinator.requestPermission();
  }

  @override
  Future<void> saveVehicleDraft({
    required String vehicleType,
    required double length,
    required double width,
    required double height,
    required double maxMass,
    required double mileage,
  }) async {
    final existing = await _profileRepository.loadProfile();
    if (existing == null) return;
    await _profileRepository.saveProfile(
      existing.copyWith(
        vehicleType: vehicleType,
        length: length,
        width: width,
        height: height,
        maxMass: maxMass,
        mileage: mileage,
      ),
    );
  }

  @override
  Future<void> finalize(OnboardingProgress progress) async {
    if (progress.selectedGuidePackageIds.contains(
      LocalOfflineGuidesService.bundledPackageId,
    )) {
      final installed = await _guidesService.isBundledPackageInstalled();
      if (!installed) {
        await _guidesService.installBundledPackage();
      }
    }
    if (progress.installChecklist) {
      final existing = await _checklistRepository.listItems();
      if (existing.isEmpty) {
        for (final item in _defaultChecklist) {
          await _checklistRepository.saveItem(item);
        }
      }
    }
    await saveProgress(
      progress.copyWith(
        completed: true,
        clearCurrentStepId: true,
      ),
    );
  }
}

const _defaultChecklist = [
  CamperChecklistItem(
    title: 'Check documents and insurance',
    checked: false,
    listName: 'Departure',
    category: 'Essentials',
    position: 0,
  ),
  CamperChecklistItem(
    title: 'Secure loose objects',
    checked: false,
    listName: 'Departure',
    category: 'Safety',
    position: 1,
  ),
  CamperChecklistItem(
    title: 'Set fridge to travel mode',
    checked: false,
    listName: 'Departure',
    category: 'Cabin',
    position: 2,
  ),
];
