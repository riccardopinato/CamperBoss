import 'package:flutter_test/flutter_test.dart';

import 'package:camperboss/main.dart';

void main() {
  testWidgets('CamperBoss opens the home dashboard', (tester) async {
    await tester.pumpWidget(const CamperBossApp());

    expect(find.text('Camper cockpit'), findsOneWidget);
    expect(find.text('Boss Score'), findsOneWidget);
    expect(find.text('Fresh water'), findsOneWidget);
  });
}
