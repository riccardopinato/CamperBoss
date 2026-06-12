import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
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
