import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';

class ResourceBar extends StatelessWidget {
  const ResourceBar({
    required this.label,
    required this.value,
    required this.detail,
    this.color = AppColors.moss,
    super.key,
  });

  final String label;
  final double value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          minHeight: 9,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
