import 'managed_media_inspector_stub.dart'
    if (dart.library.io) 'managed_media_inspector_io.dart' as implementation;

class ManagedMediaSnapshot {
  const ManagedMediaSnapshot({
    required this.bytes,
    required this.fileCount,
    required this.isAvailable,
  });

  final int bytes;
  final int fileCount;
  final bool isAvailable;
}

abstract interface class ManagedMediaInspector {
  Future<ManagedMediaSnapshot> snapshot();
}

ManagedMediaInspector createManagedMediaInspector() {
  return implementation.createManagedMediaInspector();
}
