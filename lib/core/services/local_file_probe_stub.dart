class LocalFileProbe {
  const LocalFileProbe();

  bool get isSupported => false;

  Future<bool> exists(String path) async => true;
}
