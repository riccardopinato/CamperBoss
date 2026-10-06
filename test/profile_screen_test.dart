import 'package:camperboss/data/models/vehicle_profile.dart';
import 'package:camperboss/data/repositories/local_vehicle_profile_repository.dart';
import 'package:camperboss/features/profile/presentation/profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVehicleProfileStore implements VehicleProfileStore {
  FakeVehicleProfileStore(this.profile);

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('profile screen edits and persists the vehicle profile',
      (tester) async {
    final store = FakeVehicleProfileStore(
      const VehicleProfile(
        id: 1,
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
      ),
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: ProfileScreen(
              repository: LocalVehicleProfileRepository(store: store),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fiat Ducato'), findsOneWidget);
    expect(find.text('Dimensions'), findsOneWidget);
    expect(find.text('Mileage'), findsOneWidget);
  });
}
