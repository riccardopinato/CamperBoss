import 'managed_media_inspector.dart';

ManagedMediaInspector createManagedMediaInspector() {
  return const UnsupportedManagedMediaInspector();
}

class UnsupportedManagedMediaInspector implements ManagedMediaInspector {
  const UnsupportedManagedMediaInspector();

  @override
  Future<ManagedMediaSnapshot> snapshot() async {
    return const ManagedMediaSnapshot(
      bytes: 0,
      fileCount: 0,
      isAvailable: false,
    );
  }
}
