import 'package:camperboss/core/services/offline_guides_service.dart';
import 'package:camperboss/core/services/onboarding_service.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/models/guide_models.dart';
import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_checklist_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists and resumes onboarding progress', () async {
    final store = _MemoryStore();
    final service = LocalOnboardingService(
      store: store,
      profileRepository: _MemoryProfileRepository(),
      checklistRepository: _MemoryChecklistRepository(),
      guidesService: _FakeGuidesService(),
      locationPermissionRequest: () async => true,
      notificationPermissionRequest: () async => true,
    );

    await service.saveProgress(
      OnboardingProgress.empty.copyWith(
        currentStepId: 'vehicle',
        localeCode: 'it',
        countryCode: 'IT',
      ),
    );
    await service.completeStep('locale');
    await service.skipStep('vehicle');

    final progress = await service.loadProgress();
    expect(progress.completedStepIds, contains('locale'));
    expect(progress.skippedStepIds, contains('vehicle'));
    expect(progress.currentStepId, 'vehicle');
  });

  test('handles denied permissions without forcing completion', () async {
    final service = LocalOnboardingService(
      store: _MemoryStore(),
      profileRepository: _MemoryProfileRepository(),
      checklistRepository: _MemoryChecklistRepository(),
      guidesService: _FakeGuidesService(),
      locationPermissionRequest: () async => false,
      notificationPermissionRequest: () async => false,
    );

    expect(await service.requestLocationAccess(), isFalse);
    expect(await service.requestNotificationAccess(), isFalse);
  });

  test('saves vehicle draft and finalizes selected setup only on confirmation',
      () async {
    final profileRepository = _MemoryProfileRepository();
    final checklistRepository = _MemoryChecklistRepository();
    final guidesService = _FakeGuidesService();
    final service = LocalOnboardingService(
      store: _MemoryStore(),
      profileRepository: profileRepository,
      checklistRepository: checklistRepository,
      guidesService: guidesService,
      locationPermissionRequest: () async => true,
      notificationPermissionRequest: () async => true,
    );

    await service.saveVehicleDraft(
      vehicleType: 'Motorhome',
      length: 7.1,
      width: 2.3,
      height: 3.0,
      maxMass: 3500,
      mileage: 15000,
    );

    expect(guidesService.installed, isFalse);
    expect(checklistRepository.items, isEmpty);

    await service.finalize(
      OnboardingProgress.empty.copyWith(
        selectedGuidePackageIds: {LocalOfflineGuidesService.bundledPackageId},
        installChecklist: true,
        completed: true,
      ),
    );

    expect(profileRepository.profile?.vehicleType, 'Motorhome');
    expect(guidesService.installed, isTrue);
    expect(checklistRepository.items, isNotEmpty);
  });
}

class _MemoryStore implements LocalKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _MemoryProfileRepository implements VehicleProfileRepository {
  VehicleProfile? profile;

  @override
  Future<void> deleteProfile() async {
    profile = null;
  }

  @override
  Future<VehicleProfile?> loadProfile() async => profile;

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile value) async {
    profile = value.copyWith(id: value.id ?? 1);
    return profile!;
  }
}

class _MemoryChecklistRepository implements ChecklistRepository {
  final items = <CamperChecklistItem>[];

  @override
  Future<void> deleteItem(int id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<CamperChecklistItem>> listItems() async => [...items];

  @override
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async {
    items.add(item);
    return item;
  }
}

class _FakeGuidesService implements OfflineGuidesService {
  var installed = false;
  final favorites = <String>{};
  final progress = <String, GuideReadingProgress>{};

  @override
  GuideCollectionState collectionState(
    ContentCollection collection,
    List<ContentCollection> collections,
    Set<String> installedPackageIds, {
    Set<String> updatablePackageIds = const {},
  }) {
    return installedPackageIds
            .contains(LocalOfflineGuidesService.bundledPackageId)
        ? GuideCollectionState.installed
        : GuideCollectionState.notInstalled;
  }

  @override
  Future<void> installBundledPackage() async {
    installed = true;
  }

  @override
  Future<bool> isBundledPackageInstalled() async => installed;

  @override
  Future<GuideDocument> loadDocument(String packageId, String entryId) async {
    return const GuideDocument(
      packageId: 'camperboss-essential',
      entryId: 'entry',
      title: 'Guide',
      contentType: GuideContentType.markdown,
      content: '# Guide',
      attribution: 'Test',
    );
  }

  @override
  Future<Set<String>> loadFavorites() async => {...favorites};

  @override
  Future<GuideReadingProgress?> loadReadingProgress(String entryId) async =>
      progress[entryId];

  @override
  Future<List<GuidePackage>> listInstalledPackages() async => const [];

  @override
  String sanitizeHtml(String html) => html;

  @override
  Future<List<GuideEntrySearchResult>> search(String query) async => const [];

  @override
  Future<void> saveReadingProgress(GuideReadingProgress value) async {
    progress[value.entryId] = value;
  }

  @override
  Future<void> toggleFavorite(String entryId) async {
    if (!favorites.add(entryId)) {
      favorites.remove(entryId);
    }
  }
}
