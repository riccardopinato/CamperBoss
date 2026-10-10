import 'package:camperboss/core/services/fake_local_notification_service.dart';
import 'package:camperboss/core/services/reminder_coordinator.dart';
import 'package:camperboss/features/settings/presentation/more_hub_screen.dart';
import 'package:camperboss/features/settings/presentation/privacy_data_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_localization.dart';

void main() {
  testWidgets('More exposes Privacy & Data disclosure', (tester) async {
    final coordinator = ReminderCoordinator(
      notificationService: FakeLocalNotificationService(),
    );

    await pumpLocalizedHome(
      tester,
      home: MoreHubScreen(reminderCoordinator: coordinator),
    );

    await tester.ensureVisible(find.text('Privacy & data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy & data'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyDataScreen), findsOneWidget);
    expect(find.text('Privacy & data'), findsWidgets);
    expect(
      find.textContaining('stays on your device'),
      findsWidgets,
    );
  });
}
