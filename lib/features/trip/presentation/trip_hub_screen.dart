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
      title: 'Trips',
      subtitle:
          'Plan the route, prepare the camper and keep the whole trip in one place.',
      children: [
        ActionTile(
          icon: Icons.route_outlined,
          title: 'Trip planner',
          subtitle: 'Destinations, stages, routing, dates and overnight stops.',
          onTap: () => _open(context, const TripPlannerScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.checklist_outlined,
          title: 'Checklists',
          subtitle: 'Departure, arrival, service and winter routines.',
          onTap: () => _open(context, const ChecklistScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.auto_stories_outlined,
          title: 'Travel journal',
          subtitle: 'Real notes, places, kilometres and costs.',
          onTap: () => _open(context, const JournalScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget, fuel & bookings',
          subtitle: 'Expenses, refuelling, budgets and reservations.',
          onTap: () => _open(context, const FinanceScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.timeline_outlined,
          title: 'GPX, memories & statistics',
          subtitle: 'Travel history, geolocated memories and route statistics.',
          onTap: () => _open(context, const TravelHistoryScreen()),
        ),
      ],
    );
  }
}
