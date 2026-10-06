import 'package:camperboss/core/theme/app_theme.dart';
import 'package:camperboss/shared/widgets/metric_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app theme preserves concrete Material title font sizes', () {
    final theme = AppTheme.dark();

    expect(theme.textTheme.headlineMedium?.fontSize, isNotNull);
    expect(theme.textTheme.titleLarge?.fontSize, isNotNull);
    expect(theme.textTheme.titleMedium?.fontSize, isNotNull);
    expect(theme.textTheme.titleLarge!.fontSize!, lessThan(40));
    expect(theme.textTheme.titleMedium!.fontSize!, lessThan(32));
  });

  testWidgets('MetricTile pins label typography instead of inheriting ambient size',
      (tester) async {
    final theme = AppTheme.dark();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: DefaultTextStyle(
            style: const TextStyle(fontSize: 72),
            child: const SizedBox(
              width: 180,
              height: 220,
              child: MetricTile(
                icon: Icons.height_outlined,
                label: 'Dimensioni',
                value: '--',
                detail: 'Lunghezza / larghezza / altezza',
              ),
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Dimensioni'));
    expect(label.style?.fontSize, theme.textTheme.titleMedium?.fontSize);
    expect(label.style?.fontSize, lessThan(32));
  });
}
