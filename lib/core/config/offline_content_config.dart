abstract final class OfflineContentConfig {
  static const String manifestUrl = String.fromEnvironment(
    'CAMPERBOSS_OFFLINE_MANIFEST_URL',
  );

  static const String allowedHostsCsv = String.fromEnvironment(
    'CAMPERBOSS_OFFLINE_ALLOWED_HOSTS',
  );

  static Uri? get manifestUri {
    final raw = manifestUrl.trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static bool get isRemoteCatalogConfigured => manifestUri != null;

  static Set<String> get allowedHosts {
    final hosts = <String>{
      if (manifestUri case final uri?) uri.host.toLowerCase(),
    };
    for (final value in allowedHostsCsv.split(',')) {
      final host = value.trim().toLowerCase();
      if (host.isNotEmpty) hosts.add(host);
    }
    return Set.unmodifiable(hosts);
  }
}
