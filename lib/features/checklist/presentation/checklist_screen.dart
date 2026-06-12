import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/checklist_item_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = MockCamperRepository.checklist;

    return ScreenScaffold(
      title: 'Checklist',
      subtitle: 'Departure, arrival, service, and winter routines.',
      children: [
        const PremiumCard(
          child: ResourceBar(
            label: 'Pre-trip completed',
            value: 0.71,
            detail: '2 critical checks still open',
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Pre-trip'),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            children: [
              for (final item in items)
                ChecklistItemTile(
                  title: item.title,
                  subtitle: item.subtitle,
                  checked: item.checked,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Arrival routine'),
        const SizedBox(height: 12),
        const PremiumCard(
          child: Column(
            children: [
              ChecklistItemTile(
                title: 'Level camper and stabilize',
                subtitle: 'Check slope before opening fridge',
                checked: false,
              ),
              ChecklistItemTile(
                title: 'Switch fridge to site mode',
                checked: false,
              ),
              ChecklistItemTile(
                title: 'Log overnight location',
                subtitle: 'Useful for journal and emergency sharing',
                checked: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
