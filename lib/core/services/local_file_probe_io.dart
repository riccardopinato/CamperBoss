import 'dart:io';

class LocalFileProbe {
  const LocalFileProbe();

  bool get isSupported => true;

  Future<bool> exists(String path) => File(path).exists();
}
