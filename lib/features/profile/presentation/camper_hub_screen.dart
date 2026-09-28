import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../documents/presentation/vehicle_documents_screen.dart';
import '../../maintenance/presentation/maintenance_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class CamperHubScreen extends StatelessWidget {
  const CamperHubScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'camper_hub_title'.tr(),
      subtitle:
          'camper_hub_subtitle'.tr(),
      children: [
        ActionTile(
          icon: Icons.directions_bus_outlined,
          title: 'camper_hub_profile'.tr(),
          subtitle: 'camper_hub_profile_body'.tr(),
          onTap: () => _open(context, const ProfileScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.folder_copy_outlined,
          title: 'camper_hub_documents'.tr(),
          subtitle: 'camper_hub_documents_body'.tr(),
          onTap: () => _open(context, const VehicleDocumentsScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.build_circle_outlined,
          title: 'camper_hub_maintenance'.tr(),
          subtitle: 'camper_hub_maintenance_body'.tr(),
          onTap: () => _open(context, const MaintenanceScreen()),
        ),
      ],
    );
  }
}
