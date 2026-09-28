import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

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

class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({
    this.entitlementId = const String.fromEnvironment(
      'REVENUECAT_ENTITLEMENT_ID',
      defaultValue: 'pro',
    ),
    this.androidApiKey =
        const String.fromEnvironment('REVENUECAT_ANDROID_API_KEY'),
    this.iosApiKey =
        const String.fromEnvironment('REVENUECAT_IOS_API_KEY'),
    this.webApiKey =
        const String.fromEnvironment('REVENUECAT_WEB_API_KEY'),
  });

  final String entitlementId;
  final String androidApiKey;
  final String iosApiKey;
  final String webApiKey;

  static bool _configured = false;

  String get _apiKey {
    if (kIsWeb) return webApiKey.trim();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidApiKey.trim(),
      TargetPlatform.iOS => iosApiKey.trim(),
      _ => '',
    };
  }

  bool get _platformSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _ensureConfigured() async {
    if (!_platformSupported || _apiKey.isEmpty) return false;
    if (_configured) return true;

    if (kDebugMode) {
      await rc.Purchases.setLogLevel(rc.LogLevel.info);
    }
    await rc.Purchases.configure(rc.PurchasesConfiguration(_apiKey));
    _configured = true;
    return true;
  }

  @override
  Future<ProSubscriptionState> load() async {
    if (!await _ensureConfigured()) {
      return const ProSubscriptionState(
        isConfigured: false,
        isPro: false,
        packages: [],
        message: 'revenuecat_not_configured',
      );
    }

    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      final offerings = await rc.Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];

      return ProSubscriptionState(
        isConfigured: true,
        isPro: _isEntitled(customerInfo),
        packages: [
          for (final package in packages)
            ProPackage(
              identifier: package.identifier,
              title: package.storeProduct.title,
              description: package.storeProduct.description,
              price: package.storeProduct.priceString,
            ),
        ],
      );
    } on PlatformException catch (error) {
      throw SubscriptionFailure(_messageFor(error));
    }
  }

  @override
  Future<ProSubscriptionState> purchase(String packageIdentifier) async {
    if (!await _ensureConfigured()) {
      throw const SubscriptionFailure('revenuecat_not_configured');
    }

    try {
      final offerings = await rc.Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      final package = packages
          .where((candidate) => candidate.identifier == packageIdentifier)
          .firstOrNull;
      if (package == null) {
        throw const SubscriptionFailure('revenuecat_package_unavailable');
      }

      final result = await rc.Purchases.purchasePackage(package);
      return _stateFromCustomerInfo(result.customerInfo, packages);
    } on PlatformException catch (error) {
      final code = rc.PurchasesErrorHelper.getErrorCode(error);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        throw const SubscriptionFailure(
          'revenuecat_purchase_cancelled',
          cancelled: true,
        );
      }
      throw SubscriptionFailure(_messageFor(error));
    }
  }

  @override
  Future<ProSubscriptionState> restore() async {
    if (!await _ensureConfigured()) {
      throw const SubscriptionFailure('revenuecat_not_configured');
    }
    if (kIsWeb) {
      throw const SubscriptionFailure('revenuecat_restore_web_unavailable');
    }

    try {
      final customerInfo = await rc.Purchases.restorePurchases();
      final offerings = await rc.Purchases.getOfferings();
      return _stateFromCustomerInfo(
        customerInfo,
        offerings.current?.availablePackages ?? const [],
      );
    } on PlatformException catch (error) {
      throw SubscriptionFailure(_messageFor(error));
    }
  }

  ProSubscriptionState _stateFromCustomerInfo(
    rc.CustomerInfo customerInfo,
    List<rc.Package> packages,
  ) {
    return ProSubscriptionState(
      isConfigured: true,
      isPro: _isEntitled(customerInfo),
      packages: [
        for (final package in packages)
          ProPackage(
            identifier: package.identifier,
            title: package.storeProduct.title,
            description: package.storeProduct.description,
            price: package.storeProduct.priceString,
          ),
      ],
    );
  }

  bool _isEntitled(rc.CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  String _messageFor(PlatformException error) {
    final code = rc.PurchasesErrorHelper.getErrorCode(error);
    return 'RevenueCat: ${code.name}';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
