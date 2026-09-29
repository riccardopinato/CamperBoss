import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/presentation/guided_onboarding_screen.dart';
import 'offline_guides_screen.dart';
import '../../../core/providers/download_manager_provider.dart';
import '../../../core/services/app_download_manager.dart';
import '../../../core/services/storage_inspector.dart';
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
    final storageProjection = ref.watch(storageProjectionProvider);

    return ScreenScaffold(
      title: 'offline_title'.tr(),
      subtitle: 'offline_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OfflineGuidesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: Text('offline_open_guides'.tr()),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GuidedOnboardingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch_outlined),
                label: Text('offline_guided_setup'.tr()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        storageProjection.when(
          data: (projection) => StorageProjectionCard(projection: projection),
          error: (_, __) => _OfflineRecoveryCard(
            messageKey: 'offline_storage_error',
            onRetry: () => ref.invalidate(storageProjectionProvider),
          ),
          loading: () => const LinearProgressIndicator(),
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
          error: (_, __) => _OfflineRecoveryCard(
            messageKey: 'offline_error',
            onRetry: () => ref.invalidate(downloadsProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _OfflineRecoveryCard extends StatelessWidget {
  const _OfflineRecoveryCard({
    required this.messageKey,
    required this.onRetry,
  });

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  messageKey.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('offline_recovery_help'.tr()),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('offline_retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class StorageProjectionCard extends StatelessWidget {
  const StorageProjectionCard({required this.projection, super.key});

  final StorageProjection projection;

  @override
  Widget build(BuildContext context) {
    final ratio = projection.projectedUsageRatio.clamp(0.0, 1.0);
    final color = switch (projection.pressure) {
      StoragePressure.normal => Colors.green,
      StoragePressure.warning => Colors.orange,
      StoragePressure.critical ||
      StoragePressure.insufficient =>
        Colors.redAccent,
    };

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'offline_storage_title'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                label: Text('offline_storage_${projection.pressure.name}'.tr()),
                backgroundColor: color.withValues(alpha: 0.16),
                side: BorderSide(color: color.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: ratio, color: color),
          const SizedBox(height: 8),
          Text(
            '${'offline_storage_used'.tr()}: ${_sizeLabel(projection.usedBytes)}'
            ' - ${'offline_storage_available'.tr()}: ${_sizeLabel(projection.availableBytes)}'
            ' - ${'offline_storage_remaining'.tr()}: ${_sizeLabel(projection.projectedRemainingBytes)}',
          ),
        ],
      ),
    );
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
                  onPressed: () => _runAction(
                    context,
                    () => manager.pause(record.packageId),
                  ),
                  icon: const Icon(Icons.pause),
                  label: Text('offline_pause'.tr()),
                ),
              if (record.status == DownloadStatus.paused)
                FilledButton.icon(
                  onPressed: () => _runAction(
                    context,
                    () => manager.resume(record.packageId),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('offline_resume'.tr()),
                ),
              if (record.status == DownloadStatus.failed ||
                  record.status == DownloadStatus.corrupted ||
                  record.status == DownloadStatus.canceled)
                OutlinedButton.icon(
                  onPressed: () => _runAction(
                    context,
                    () => manager.retry(record.packageId),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text('offline_retry'.tr()),
                ),
              if (record.status == DownloadStatus.running ||
                  record.status == DownloadStatus.queued ||
                  record.status == DownloadStatus.paused)
                OutlinedButton.icon(
                  onPressed: () => _runAction(
                    context,
                    () => manager.cancel(record.packageId),
                  ),
                  icon: const Icon(Icons.close),
                  label: Text('offline_cancel'.tr()),
                ),
              OutlinedButton.icon(
                onPressed: () => _runAction(
                    context,
                    () => manager.delete(record.packageId),
                  ),
                icon: const Icon(Icons.delete_outline),
                label: Text('offline_delete'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('offline_action_failed'.tr())),
      );
    }
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
      label: Text('offline_status_${status.name}'.tr()),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}
