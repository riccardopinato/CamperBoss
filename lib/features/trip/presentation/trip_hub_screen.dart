import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../checklist/presentation/checklist_screen.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import 'travel_history_screen.dart';
import 'trip_planner_screen.dart';

class TripHubScreen extends StatelessWidget {
  const TripHubScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'trip_hub_title'.tr(),
      subtitle:
          'trip_hub_subtitle'.tr(),
      children: [
        ActionTile(
          icon: Icons.route_outlined,
          title: 'trip_hub_planner'.tr(),
          subtitle: 'trip_hub_planner_body'.tr(),
          onTap: () => _open(context, const TripPlannerScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.checklist_outlined,
          title: 'trip_hub_checklists'.tr(),
          subtitle: 'trip_hub_checklists_body'.tr(),
          onTap: () => _open(context, const ChecklistScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.auto_stories_outlined,
          title: 'trip_hub_journal'.tr(),
          subtitle: 'trip_hub_journal_body'.tr(),
          onTap: () => _open(context, const JournalScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'trip_hub_finance'.tr(),
          subtitle: 'trip_hub_finance_body'.tr(),
          onTap: () => _open(context, const FinanceScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.timeline_outlined,
          title: 'trip_hub_history'.tr(),
          subtitle: 'trip_hub_history_body'.tr(),
          onTap: () => _open(context, const TravelHistoryScreen()),
        ),
      ],
    );
  }
}
