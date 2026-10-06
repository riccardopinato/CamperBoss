class ProPackage {
  const ProPackage({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
  });

  final String identifier;
  final String title;
  final String description;
  final String price;
}

class ProSubscriptionState {
  const ProSubscriptionState({
    required this.isConfigured,
    required this.isPro,
    required this.packages,
    this.message,
  });

  final bool isConfigured;
  final bool isPro;
  final List<ProPackage> packages;
  final String? message;
}

class SubscriptionFailure implements Exception {
  const SubscriptionFailure(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

abstract interface class SubscriptionService {
  Future<ProSubscriptionState> load();
  Future<ProSubscriptionState> purchase(String packageIdentifier);
  Future<ProSubscriptionState> restore();
}

/// Provider-neutral placeholder kept intentionally dormant until CamperBoss
/// selects and configures its production monetization provider.
///
/// Release builds must not expose invented plans or a fake checkout.
class DeferredSubscriptionService implements SubscriptionService {
  const DeferredSubscriptionService();

  static const ProSubscriptionState deferredState = ProSubscriptionState(
    isConfigured: false,
    isPro: false,
    packages: [],
    message: 'pro_deferred',
  );

  @override
  Future<ProSubscriptionState> load() async => deferredState;

  @override
  Future<ProSubscriptionState> purchase(String packageIdentifier) {
    throw const SubscriptionFailure('pro_deferred');
  }

  @override
  Future<ProSubscriptionState> restore() {
    throw const SubscriptionFailure('pro_deferred');
  }
}
