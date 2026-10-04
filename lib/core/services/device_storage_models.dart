class DeviceStorageSnapshot {
  const DeviceStorageSnapshot({
    this.totalBytes,
    this.freeBytes,
    required this.source,
  });

  final int? totalBytes;
  final int? freeBytes;
  final String source;

  bool get isAvailable =>
      totalBytes != null &&
      freeBytes != null &&
      totalBytes! > 0 &&
      freeBytes! >= 0;
}

abstract interface class DeviceStorageService {
  Future<DeviceStorageSnapshot> snapshot();
}
