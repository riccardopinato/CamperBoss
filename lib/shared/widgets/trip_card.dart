import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'premium_card.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    required this.title,
    required this.summary,
    required this.progress,
    super.key,
  });

  final String title;
  final String summary;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(summary),
          const SizedBox(height: AppSpacing.lg),
          LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}
