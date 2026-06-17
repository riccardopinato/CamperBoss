class RoutingConfig {
  const RoutingConfig._();

  static const orsApiKey = String.fromEnvironment('ORS_API_KEY');

  static bool get isOpenRouteServiceConfigured => orsApiKey.trim().isNotEmpty;
}
