import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import 'premium_card.dart';

class WeatherSummaryCard extends StatelessWidget {
  const WeatherSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.forest,
      child: Row(
        children: [
          const Icon(Icons.wb_cloudy_outlined, size: 42, color: AppColors.gold),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lake Garda basecamp',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('22 C, light wind, clear route window'),
              ],
            ),
          ),
          Text(
            'Good',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
