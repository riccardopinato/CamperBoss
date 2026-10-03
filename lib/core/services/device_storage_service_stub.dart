import 'device_storage_models.dart';

DeviceStorageService createDeviceStorageService() {
  return const UnsupportedDeviceStorageService();
}

class UnsupportedDeviceStorageService implements DeviceStorageService {
  const UnsupportedDeviceStorageService();

  @override
  Future<DeviceStorageSnapshot> snapshot() async {
    return const DeviceStorageSnapshot(source: 'unavailable');
  }
}
