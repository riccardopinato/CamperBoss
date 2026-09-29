import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = color ?? scheme.surface;
    final border = color == null
        ? scheme.outlineVariant.withValues(alpha: 0.72)
        : scheme.outline.withValues(alpha: 0.30);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
