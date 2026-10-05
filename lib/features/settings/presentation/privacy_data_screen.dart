import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'privacy_title'.tr(),
      subtitle: 'privacy_subtitle'.tr(),
      children: [
        _Section(
          icon: Icons.phone_android_outlined,
          title: 'privacy_local_title'.tr(),
          body: 'privacy_local_body'.tr(),
        ),
        const SizedBox(height: 16),
        _Section(
          icon: Icons.public_outlined,
          title: 'privacy_network_title'.tr(),
          body: 'privacy_network_body'.tr(),
        ),
        const SizedBox(height: 16),
        _Section(
          icon: Icons.document_scanner_outlined,
          title: 'privacy_documents_title'.tr(),
          body: 'privacy_documents_body'.tr(),
        ),
        const SizedBox(height: 16),
        _Section(
          icon: Icons.account_circle_outlined,
          title: 'privacy_account_title'.tr(),
          body: 'privacy_account_body'.tr(),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'privacy_providers_title'.tr()),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('privacy_provider_maps'.tr()),
              const SizedBox(height: 8),
              Text('privacy_provider_weather'.tr()),
              const SizedBox(height: 8),
              Text('privacy_provider_routing'.tr()),
              const SizedBox(height: 8),
              Text('privacy_provider_mlkit'.tr()),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
