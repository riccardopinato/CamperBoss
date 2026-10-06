import 'dart:async';

import 'package:camperboss/core/services/app_download_manager.dart';
import 'package:camperboss/core/services/maplibre_offline_region_manager.dart';
import 'package:camperboss/core/services/offline_guides_service.dart';
import 'package:camperboss/core/services/offline_system_coordinator.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/models/guide_models.dart';
import 'package:camperboss/data/repositories/map_view_state_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline ready requires complete region plus saved viewport', () async {
    final store = _MemoryStore();
    final state = MapViewStateRepository(store: store);
    await state.saveRegion(
      const OfflineRegionViewport(
        id: 'north',
        name: 'North',
        centerLatitude: 45,
        centerLongitude: 11,
        zoom: 10,
        south: 44,
        west: 10,
        north: 46,
        east: 12,
      ),
    );

    final coordinator = OfflineSystemCoordinator(
      downloadManager: FakeDownloadManager(),
      mapManager: _FakeMapManager([
        const MapLibreOfflineRegionSnapshot(
          id: 'north',
          name: 'North',
          downloadedBytes: 1024,
          isComplete: true,
          progress: 1,
        ),
        const MapLibreOfflineRegionSnapshot(
          id: 'broken',
          name: 'Broken',
          downloadedBytes: 100,
          isComplete: true,
          progress: 1,
        ),
      ]),
      mapStateRepository: state,
      guidesService: _FakeGuidesService(),
    );

    final snapshot = await coordinator.snapshot();

    expect(snapshot.openableMapRegionCount, 1);
    expect(await coordinator.canOpenMapRegion('north'), isTrue);
    expect(await coordinator.canOpenMapRegion('broken'), isFalse);
  });
}

class _FakeMapManager implements MapLibreOfflineRegionManager {
  _FakeMapManager(this.regions);

  final List<MapLibreOfflineRegionSnapshot> regions;

  @override
  bool get isSupported => true;

  @override
  Future<void> clearAmbientCache() async {}

  @override
  Future<void> delete(String regionId) async {}

  @override
  Stream<MapLibreOfflineRegionSnapshot> download(
    MapLibreOfflineRegionRequest request,
  ) =>
      const Stream.empty();

  @override
  Future<List<MapLibreOfflineRegionSnapshot>> listRegions() async => regions;
}

class _FakeGuidesService implements OfflineGuidesService {
  @override
  GuideCollectionState collectionState(
    ContentCollection collection,
    List<ContentCollection> collections,
    Set<String> installedPackageIds, {
    Set<String> updatablePackageIds = const {},
  }) =>
      GuideCollectionState.notInstalled;

  @override
  Future<void> installBundledPackage() async {}

  @override
  Future<bool> isBundledPackageInstalled() async => false;

  @override
  Future<Set<String>> loadFavorites() async => {};

  @override
  Future<GuideDocument> loadDocument(String packageId, String entryId) {
    throw UnimplementedError();
  }

  @override
  Future<GuideReadingProgress?> loadReadingProgress(String entryId) async =>
      null;

  @override
  Future<List<GuidePackage>> listInstalledPackages() async => const [];

  @override
  Future<void> saveReadingProgress(GuideReadingProgress progress) async {}

  @override
  String sanitizeHtml(String html) => html;

  @override
  Future<List<GuideEntrySearchResult>> search(String query) async => const [];

  @override
  Future<void> toggleFavorite(String entryId) async {}
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
