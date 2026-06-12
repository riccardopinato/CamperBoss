import 'package:flutter/material.dart';

import '../../subscription/presentation/subscription_screen.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Profile',
      subtitle: 'Vehicle, subscription, achievements, and settings.',
      children: [
        PremiumCard(
          child: Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riccardo', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('Motorhome - 7.2 m - 3.5 t'),
                  ],
                ),
              ),
              const ProBadge(label: 'FREE'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ActionTile(
          icon: Icons.directions_car_filled_outlined,
          title: 'Vehicle profile',
          subtitle: 'Height, weight, autonomy, accessories',
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.workspace_premium_outlined,
          title: 'CamperBoss Pro',
          subtitle: 'Monthly, yearly, and lifetime plans',
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Preview paywall',
          icon: Icons.payments_outlined,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const ActionTile(
          icon: Icons.emoji_events_outlined,
          title: 'Achievements',
          subtitle: 'Badges and seasonal challenges',
        ),
      ],
    );
  }
}
