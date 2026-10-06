import 'package:flutter/foundation.dart';

enum RoutingProviderMode {
  unavailable,
  proxy,
  directDevelopment,
}

abstract final class ProviderTrustPolicy {
  static const Set<String> forbiddenOfflineBulkHosts = {
    'tiles.openfreemap.org',
    'tile.openstreetmap.org',
    'vector.openstreetmap.org',
  };

  static Uri? parseHttpsUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.trim().isEmpty) {
      return null;
    }
    return uri;
  }

  static bool isForbiddenOfflineBulkHost(String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (forbiddenOfflineBulkHosts.contains(normalized)) return true;
    return normalized.endsWith('.tile.openstreetmap.org');
  }

  static Uri? parseApprovedOfflineStyleUrl(String raw) {
    final uri = parseHttpsUrl(raw);
    if (uri == null || isForbiddenOfflineBulkHost(uri.host)) return null;
    return uri;
  }
}

/// Compile-time provider configuration with explicit trust boundaries.
///
/// Production routing never treats a key embedded in the Flutter client as a
/// secret. Use CAMPERBOSS_ROUTING_PROXY_URL for production. Direct ORS access
/// is retained only for explicitly opted-in development builds.
///
/// Open-Meteo public endpoints are permitted only while the build is explicitly
/// non-commercial. Before enabling ads/IAP/subscriptions, route these requests
/// through approved commercial endpoints/proxies.
abstract final class ProviderTrustConfig {
  static const String routingProxyUrl = String.fromEnvironment(
    'CAMPERBOSS_ROUTING_PROXY_URL',
  );
  static const String orsApiKey = String.fromEnvironment('ORS_API_KEY');
  static const bool allowDirectOrsDevelopment = bool.fromEnvironment(
    'CAMPERBOSS_ALLOW_DIRECT_ORS_DEV',
    defaultValue: false,
  );

  static const bool commercialDistribution = bool.fromEnvironment(
    'CAMPERBOSS_COMMERCIAL_DISTRIBUTION',
    defaultValue: false,
  );
  static const String weatherEndpointUrl = String.fromEnvironment(
    'CAMPERBOSS_WEATHER_ENDPOINT',
  );
  static const String geocodingEndpointUrl = String.fromEnvironment(
    'CAMPERBOSS_GEOCODING_ENDPOINT',
  );
  static const String offlineMapStyleUrl = String.fromEnvironment(
    'CAMPERBOSS_OFFLINE_MAP_STYLE_URL',
  );

  static const String _publicWeatherEndpoint =
      'https://api.open-meteo.com/v1/forecast';
  static const String _publicGeocodingEndpoint =
      'https://geocoding-api.open-meteo.com/v1/search';

  static Uri? get routingProxyUri =>
      ProviderTrustPolicy.parseHttpsUrl(routingProxyUrl);

  static RoutingProviderMode get routingMode {
    if (routingProxyUri != null) return RoutingProviderMode.proxy;
    if (!kReleaseMode &&
        allowDirectOrsDevelopment &&
        orsApiKey.trim().isNotEmpty) {
      return RoutingProviderMode.directDevelopment;
    }
    return RoutingProviderMode.unavailable;
  }

  static bool get isRoutingConfigured =>
      routingMode != RoutingProviderMode.unavailable;

  static String get routingBaseUrl => switch (routingMode) {
        RoutingProviderMode.proxy => routingProxyUri!.toString(),
        RoutingProviderMode.directDevelopment =>
          'https://api.heigit.org/openrouteservice',
        RoutingProviderMode.unavailable => '',
      };

  static bool get routingRequiresClientApiKey =>
      routingMode == RoutingProviderMode.directDevelopment;

  static Uri? get weatherEndpoint {
    final configured = ProviderTrustPolicy.parseHttpsUrl(weatherEndpointUrl);
    if (configured != null) return configured;
    if (!commercialDistribution) return Uri.parse(_publicWeatherEndpoint);
    return null;
  }

  static Uri? get geocodingEndpoint {
    final configured = ProviderTrustPolicy.parseHttpsUrl(geocodingEndpointUrl);
    if (configured != null) return configured;
    if (!commercialDistribution) return Uri.parse(_publicGeocodingEndpoint);
    return null;
  }

  static Uri? get offlineMapStyleUri =>
      ProviderTrustPolicy.parseApprovedOfflineStyleUrl(offlineMapStyleUrl);

  static bool get isOfflineMapDownloadConfigured =>
      offlineMapStyleUri != null;
}
