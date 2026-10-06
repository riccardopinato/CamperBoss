import '../database/local_json_collection.dart';
import '../models/poi_catalog_models.dart';

abstract interface class PoiPackageStateRepository {
  Future<List<PoiPackageState>> listStates();
  Future<PoiPackageState?> find(String packageId);
  Future<void> save(PoiPackageState state);
  Future<void> delete(String packageId);
}

class LocalPoiPackageStateRepository implements PoiPackageStateRepository {
  LocalPoiPackageStateRepository({LocalJsonCollection? collection})
      : _collection = collection ??
            LocalJsonCollection('camperboss.poi_package_state');

  final LocalJsonCollection _collection;

  @override
  Future<List<PoiPackageState>> listStates() async {
    final rows = await _collection.listRows();
    final states = rows.map(PoiPackageState.fromMap).toList();
    states.sort((a, b) => a.region.compareTo(b.region));
    return states;
  }

  @override
  Future<PoiPackageState?> find(String packageId) async {
    final states = await listStates();
    for (final state in states) {
      if (state.packageId == packageId) return state;
    }
    return null;
  }

  @override
  Future<void> save(PoiPackageState state) async {
    await _collection.saveRow(state.toMap());
  }

  @override
  Future<void> delete(String packageId) {
    return _collection.deleteRow(packageId);
  }
}
