import 'package:flutter_test/flutter_test.dart';

import 'package:camperboss/main.dart';

void main() {
  testWidgets('CamperBoss opens the home dashboard', (tester) async {
    await tester.pumpWidget(const CamperBossApp());

    expect(find.text('Ready for the next stop?'), findsOneWidget);
    expect(find.text('Quiet lakeside camper area'), findsOneWidget);
    expect(find.text('Plan a weekend route'), findsOneWidget);
  });
}
