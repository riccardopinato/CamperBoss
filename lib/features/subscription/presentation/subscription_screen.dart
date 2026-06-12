import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CamperBoss Pro')),
      body: ScreenScaffold(
        title: 'Travel without limits',
        subtitle: 'Mock paywall before RevenueCat integration.',
        children: [
          PremiumCard(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProBadge(label: 'BEST VALUE'),
                const SizedBox(height: 16),
                Text(
                  'Built for people who actually travel',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Offline maps, advanced filters, weather risk alerts, unlimited journals, and backup for every route.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _BenefitRow(
            icon: Icons.offline_bolt_outlined,
            title: 'Offline route confidence',
            subtitle: 'Download areas before mountain roads or poor coverage.',
          ),
          const SizedBox(height: 10),
          const _BenefitRow(
            icon: Icons.tune_outlined,
            title: 'Filters that matter',
            subtitle: 'Height, payload, water, dump, safety, pets, and 24h.',
          ),
          const SizedBox(height: 10),
          const _BenefitRow(
            icon: Icons.thunderstorm_outlined,
            title: 'Weather and road alerts',
            subtitle: 'Know when wind, rain, or cold changes the plan.',
          ),
          const SizedBox(height: 24),
          for (final plan in const [
            ('Monthly Pro', 'Offline maps, premium filters, no ads'),
            ('Yearly Pro', 'Best value for frequent travelers'),
            ('Lifetime', 'One payment for the whole road ahead'),
          ]) ...[
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.$1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(plan.$2),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Choose plan',
                    icon: Icons.arrow_forward,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
