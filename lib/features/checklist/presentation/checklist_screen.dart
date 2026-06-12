import 'package:flutter/material.dart';

import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/checklist_item_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = MockCamperRepository.checklist;

    return ScreenScaffold(
      title: 'Checklist',
      subtitle: 'Mock pre-trip list ready for Drift later.',
      children: [
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
      ],
    );
  }
}
