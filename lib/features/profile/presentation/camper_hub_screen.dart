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
      title: 'My camper',
      subtitle:
          'Vehicle identity, documents and maintenance stay local by default.',
      children: [
        ActionTile(
          icon: Icons.directions_bus_outlined,
          title: 'Vehicle profile',
          subtitle: 'Dimensions, mass, mileage, tanks and technical limits.',
          onTap: () => _open(context, const ProfileScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.folder_copy_outlined,
          title: 'Vehicle documents',
          subtitle: 'Private archive with scans, PDFs, OCR and expiry dates.',
          onTap: () => _open(context, const VehicleDocumentsScreen()),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.build_circle_outlined,
          title: 'Maintenance',
          subtitle: 'Service history, mileage intervals and next due items.',
          onTap: () => _open(context, const MaintenanceScreen()),
        ),
      ],
    );
  }
}
