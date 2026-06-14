import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import 'premium_card.dart';
import 'pro_badge.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.tags,
    this.address,
    this.city,
    this.coordinates,
    this.source,
    this.services = const [],
    this.onDirections,
    super.key,
  });

  final String name;
  final String type;
  final String distance;
  final String rating;
  final List<String> tags;
  final String? address;
  final String? city;
  final String? coordinates;
  final String? source;
  final List<String> services;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.forest,
                child: Icon(Icons.rv_hookup, color: AppColors.text),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$type - $distance'),
                  ],
                ),
              ),
              ProBadge(label: rating),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.surfaceSoft,
                ),
            ],
          ),
          if (address != null ||
              city != null ||
              coordinates != null ||
              source != null ||
              services.isNotEmpty ||
              onDirections != null) ...[
            const SizedBox(height: AppSpacing.md),
            if (address != null) Text(address!),
            if (city != null) Text(city!),
            if (coordinates != null) Text(coordinates!),
            if (services.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                services.join(' - '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
            if (source != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                source!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
            if (onDirections != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
