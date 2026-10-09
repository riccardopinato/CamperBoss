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
    final radius = BorderRadius.circular(16);

    // Material owns both the fill and border so descendant Ink/ListTile widgets
    // paint onto the correct surface. Keeping a decorated Container between
    // Material and ListTile hides ink splashes and triggers Flutter assertions.
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
