import 'package:flutter/services.dart';

import 'device_storage_models.dart';

DeviceStorageService createDeviceStorageService() {
  return const NativeDeviceStorageService();
}

class NativeDeviceStorageService implements DeviceStorageService {
  const NativeDeviceStorageService();

  static const MethodChannel _channel =
      MethodChannel('com.camperboss/device_storage');

  @override
  Future<DeviceStorageSnapshot> snapshot() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'storageStats',
      );
      final total = (raw?['totalBytes'] as num?)?.toInt();
      final free = (raw?['freeBytes'] as num?)?.toInt();
      if (total == null || free == null || total <= 0 || free < 0) {
        return const DeviceStorageSnapshot(source: 'native-unavailable');
      }
      return DeviceStorageSnapshot(
        totalBytes: total,
        freeBytes: free,
        source: 'native-volume',
      );
    } on MissingPluginException {
      return const DeviceStorageSnapshot(source: 'plugin-unavailable');
    } on PlatformException {
      return const DeviceStorageSnapshot(source: 'native-error');
    }
  }
}
