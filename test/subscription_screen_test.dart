import 'package:camperboss/core/services/subscription_service.dart';
import 'package:camperboss/features/subscription/presentation/subscription_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  Widget app(SubscriptionService service) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: SubscriptionScreen(service: service),
          );
        },
      ),
    );
  }

  test('default monetization service stays intentionally deferred', () async {
    const service = DeferredSubscriptionService();
    final state = await service.load();

    expect(state.isConfigured, isFalse);
    expect(state.isPro, isFalse);
    expect(state.packages, isEmpty);
    expect(state.message, 'pro_deferred');
  });

  testWidgets('deferred monetization never exposes fake plans or checkout',
      (tester) async {
    await tester.pumpWidget(app(const DeferredSubscriptionService()));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Pro'), findsNothing);
    expect(find.text('Yearly Pro'), findsNothing);
    expect(find.text('Lifetime'), findsNothing);
    expect(find.text('Choose'), findsNothing);
    expect(find.textContaining('intentionally deferred'), findsOneWidget);
  });

  testWidgets('provider abstraction can still render verified entitlement',
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
    expect(find.textContaining('Pro entitlement is currently active'), findsOneWidget);
    expect(find.text('Choose'), findsNothing);
  });
}

class _FakeSubscriptionService implements SubscriptionService {
  _FakeSubscriptionService({required this.state});

  final ProSubscriptionState state;

  @override
  Future<ProSubscriptionState> load() async => state;

  @override
  Future<ProSubscriptionState> purchase(String packageIdentifier) async => state;

  @override
  Future<ProSubscriptionState> restore() async => state;
}
