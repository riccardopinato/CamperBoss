import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/download_manager_provider.dart';
import '../../../core/services/app_download_manager.dart';
import '../../../data/models/download_models.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class OfflineContentScreen extends ConsumerWidget {
  const OfflineContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final manager = ref.watch(downloadManagerProvider);

    return ScreenScaffold(
      title: 'offline_title'.tr(),
      subtitle: 'offline_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Row(
            children: [
              const Icon(Icons.wifi_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'offline_wifi_only'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('offline_wifi_only_help'.tr()),
                  ],
                ),
              ),
              const Switch(value: true, onChanged: null),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'offline_installed'.tr()),
        const SizedBox(height: 12),
        downloads.when(
          data: (records) {
            if (records.isEmpty) {
              return PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'offline_empty_title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('offline_empty_body'.tr()),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final record in records) ...[
                  DownloadRecordTile(record: record, manager: manager),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
          error: (error, _) => PremiumCard(
            child: Text('${'offline_error'.tr()}: $error'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class DownloadRecordTile extends StatelessWidget {
  const DownloadRecordTile({
    required this.record,
    required this.manager,
    super.key,
  });

  final DownloadRecord record;
  final AppDownloadManager manager;

  @override
  Widget build(BuildContext context) {
    final progress = record.progress.clamp(0.0, 1.0);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForType(record.type)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${_typeLabel(record.type)} - ${record.version} - ${_sizeLabel(record.totalBytes)}',
                    ),
                  ],
                ),
              ),
              _StatusChip(status: record.status),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress == 0 ? null : progress),
          const SizedBox(height: 8),
          Text(
            [
              '${(progress * 100).round()}%',
              if (record.speedBytesPerSecond != null)
                '${_sizeLabel(record.speedBytesPerSecond!)}/s',
              if (record.lastError != null) record.lastError!,
            ].join(' - '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (record.status == DownloadStatus.running)
                OutlinedButton.icon(
                  onPressed: () => manager.pause(record.packageId),
                  icon: const Icon(Icons.pause),
                  label: Text('offline_pause'.tr()),
                ),
              if (record.status == DownloadStatus.paused)
                FilledButton.icon(
                  onPressed: () => manager.resume(record.packageId),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('offline_resume'.tr()),
                ),
              if (record.status == DownloadStatus.failed ||
                  record.status == DownloadStatus.corrupted ||
                  record.status == DownloadStatus.canceled)
                OutlinedButton.icon(
                  onPressed: () => manager.retry(record.packageId),
                  icon: const Icon(Icons.refresh),
                  label: Text('offline_retry'.tr()),
                ),
              if (record.status == DownloadStatus.running ||
                  record.status == DownloadStatus.queued ||
                  record.status == DownloadStatus.paused)
                OutlinedButton.icon(
                  onPressed: () => manager.cancel(record.packageId),
                  icon: const Icon(Icons.close),
                  label: Text('offline_cancel'.tr()),
                ),
              OutlinedButton.icon(
                onPressed: () => manager.delete(record.packageId),
                icon: const Icon(Icons.delete_outline),
                label: Text('offline_delete'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForType(DownloadPackageType type) {
    return switch (type) {
      DownloadPackageType.map => Icons.map_outlined,
      DownloadPackageType.poiDatabase => Icons.place_outlined,
      DownloadPackageType.guide => Icons.menu_book_outlined,
      DownloadPackageType.manual => Icons.description_outlined,
      DownloadPackageType.languagePack => Icons.translate,
      DownloadPackageType.backup => Icons.backup_outlined,
      DownloadPackageType.other => Icons.download_outlined,
    };
  }

  String _typeLabel(DownloadPackageType type) {
    return switch (type) {
      DownloadPackageType.map => 'offline_type_map'.tr(),
      DownloadPackageType.poiDatabase => 'offline_type_poi'.tr(),
      DownloadPackageType.guide => 'offline_type_guide'.tr(),
      DownloadPackageType.manual => 'offline_type_manual'.tr(),
      DownloadPackageType.languagePack => 'offline_type_language'.tr(),
      DownloadPackageType.backup => 'offline_type_backup'.tr(),
      DownloadPackageType.other => 'offline_type_other'.tr(),
    };
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'offline_size_unknown'.tr();
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DownloadStatus.completed => Colors.green,
      DownloadStatus.failed || DownloadStatus.corrupted => Colors.redAccent,
      DownloadStatus.running ||
      DownloadStatus.queued ||
      DownloadStatus.verifying =>
        Colors.amber,
      DownloadStatus.paused || DownloadStatus.canceled => Colors.grey,
    };

    return Chip(
      label: Text(status.name),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}
