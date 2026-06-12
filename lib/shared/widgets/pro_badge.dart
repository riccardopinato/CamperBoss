import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProBadge extends StatelessWidget {
  const ProBadge({this.label = 'PRO', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.night,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
