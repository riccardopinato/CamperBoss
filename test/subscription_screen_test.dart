import 'package:camperboss/core/services/subscription_service.dart';
import 'package:camperboss/features/subscription/presentation/subscription_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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
    expect(
      find.text(
        'Pro purchases are intentionally deferred. No plan is shown until '
        'a production monetization provider is selected and configured.',
      ),
      findsOneWidget,
    );
  });

  test('provider abstraction preserves verified entitlement state', () async {
    final service = _FakeSubscriptionService(
      state: const ProSubscriptionState(
        isConfigured: true,
        isPro: true,
        packages: [],
      ),
    );

    final state = await service.load();

    expect(state.isConfigured, isTrue);
    expect(state.isPro, isTrue);
    expect(state.packages, isEmpty);
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
