import 'package:camperboss/core/services/onboarding_service.dart';
import 'package:camperboss/data/models/guide_models.dart';
import 'package:camperboss/features/onboarding/presentation/guided_onboarding_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('notification step invokes permission requester', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeOnboardingService()
      ..progress = OnboardingProgress.empty.copyWith(
        currentStepId: 'notifications',
      );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: GuidedOnboardingScreen(onboardingService: service),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explain and request'), findsOneWidget);
    await tester.tap(find.text('Explain and request'));
    await tester.pumpAndSettle();

    expect(service.notificationRequests, 1);
    expect(find.text('Granted'), findsOneWidget);
  });

  testWidgets('guided onboarding renders stepper and advances', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeOnboardingService();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: GuidedOnboardingScreen(onboardingService: service),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guided setup'), findsOneWidget);
    expect(find.text('Language and country'), findsOneWidget);
    expect(find.text('Vehicle profile'), findsOneWidget);

    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(service.completedSteps, contains('locale'));
    expect(service.savedProgress?.currentStepId, 'vehicle');
  });
}

class _FakeOnboardingService implements OnboardingService {
  OnboardingProgress progress = OnboardingProgress.empty.copyWith(
    currentStepId: 'locale',
  );
  final completedSteps = <String>[];
  final skippedSteps = <String>[];
  OnboardingProgress? savedProgress;
  int notificationRequests = 0;

  @override
  Future<void> completeStep(String stepId) async {
    completedSteps.add(stepId);
  }

  @override
  Future<void> finalize(OnboardingProgress progress) async {}

  @override
  Future<OnboardingProgress> loadProgress() async => progress;

  @override
  Future<bool> requestLocationAccess() async => true;

  @override
  Future<bool> requestNotificationAccess() async {
    notificationRequests++;
    return true;
  }

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    savedProgress = progress;
    this.progress = progress;
  }

  @override
  Future<void> saveVehicleDraft({
    required String vehicleType,
    required double length,
    required double width,
    required double height,
    required double maxMass,
    required double mileage,
  }) async {}

  @override
  Future<void> skipStep(String stepId) async {
    skippedSteps.add(stepId);
  }
}
