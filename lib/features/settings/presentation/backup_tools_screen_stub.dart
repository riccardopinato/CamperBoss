import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class BackupToolsScreen extends StatelessWidget {
  const BackupToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'backup_title'.tr(),
      subtitle: 'backup_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phonelink_lock_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text('backup_native_only'.tr())),
            ],
          ),
        ),
      ],
    );
  }
}
