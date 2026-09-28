import 'package:camperboss/core/services/subscription_service.dart';
import 'package:camperboss/features/subscription/presentation/subscription_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(SubscriptionService service) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MaterialApp(
        home: SubscriptionScreen(service: service),
      ),
    );
  }

  testWidgets('shows live packages and enables real purchase action',
      (tester) async {
    final service = _FakeSubscriptionService(
      state: const ProSubscriptionState(
        isConfigured: true,
        isPro: false,
        packages: [
          ProPackage(
            identifier: 'monthly',
            title: 'Monthly Pro',
            description: 'Monthly access',
            price: '€4.99',
          ),
        ],
      ),
    );

    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Pro'), findsOneWidget);
    expect(find.text('€4.99'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();

    expect(service.purchased, 'monthly');
  });

  testWidgets('does not show fake plans when RevenueCat is unavailable',
      (tester) async {
    final service = _FakeSubscriptionService(
      state: const ProSubscriptionState(
        isConfigured: false,
        isPro: false,
        packages: [],
        message: 'revenuecat_not_configured',
      ),
    );

    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();

    expect(find.textContaining('not configured'), findsOneWidget);
    expect(find.text('Monthly Pro'), findsNothing);
    expect(find.text('Choose'), findsNothing);
  });

  testWidgets('shows verified active entitlement without checkout buttons',
      (tester) async {
    final service = _FakeSubscriptionService(
      state: const ProSubscriptionState(
        isConfigured: true,
        isPro: true,
        packages: [],
      ),
    );

    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();

    expect(find.text('PRO ACTIVE'), findsOneWidget);
    expect(find.textContaining('Premium entitlement verified'), findsOneWidget);
    expect(find.text('Choose'), findsNothing);
  });
}

class _FakeSubscriptionService implements SubscriptionService {
  _FakeSubscriptionService({required this.state});

  ProSubscriptionState state;
  String? purchased;

  @override
  Future<ProSubscriptionState> load() async => state;

  @override
  Future<ProSubscriptionState> purchase(String packageIdentifier) async {
    purchased = packageIdentifier;
    return state;
  }

  @override
  Future<ProSubscriptionState> restore() async => state;
}
