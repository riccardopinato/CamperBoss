import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryVehicleProfileStore implements VehicleProfileStore {
  VehicleProfile? profile;

  @override
  Future<void> deleteProfile() async {
    profile = null;
  }

  @override
  Future<VehicleProfile?> loadProfile() async => profile;

  @override
  Future<VehicleProfile> saveProfile(VehicleProfile vehicleProfile) async {
    profile = vehicleProfile.copyWith(id: profile?.id ?? 1);
    return profile!;
  }
}

void main() {
  test('vehicle profile repository saves, loads, and deletes locally',
      () async {
    final store = MemoryVehicleProfileStore();
    final repository = LocalVehicleProfileRepository(store: store);

    final saved = await repository.saveProfile(
      const VehicleProfile(
        vehicleType: 'Motorhome',
        brand: 'Fiat',
        model: 'Ducato',
        year: 2022,
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
      ),
    );

    expect(saved.id, 1);
    expect((await repository.loadProfile())?.brand, 'Fiat');

    await repository.saveProfile(saved.copyWith(model: 'Ducato XL'));
    expect((await repository.loadProfile())?.model, 'Ducato XL');

    await repository.deleteProfile();
    expect(await repository.loadProfile(), isNull);
  });
}
