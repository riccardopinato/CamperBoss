import 'device_storage_models.dart';
import 'device_storage_service_stub.dart'
    if (dart.library.io) 'device_storage_service_io.dart' as implementation;

export 'device_storage_models.dart';

DeviceStorageService createDeviceStorageService() {
  return implementation.createDeviceStorageService();
}
