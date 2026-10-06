import 'provider_trust_config.dart';

class RoutingConfig {
  const RoutingConfig._();

  static String get orsApiKey => ProviderTrustConfig.orsApiKey;
  static String get serviceBaseUrl => ProviderTrustConfig.routingBaseUrl;
  static bool get requiresClientApiKey =>
      ProviderTrustConfig.routingRequiresClientApiKey;

  static bool get isOpenRouteServiceConfigured =>
      ProviderTrustConfig.isRoutingConfigured;
}
