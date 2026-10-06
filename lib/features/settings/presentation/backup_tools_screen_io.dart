import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/app_system_services.dart';
import '../../../core/services/backup_file_export_service.dart';
import '../../../core/services/data_backup_service.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class BackupToolsScreen extends StatefulWidget {
  const BackupToolsScreen({super.key});

  @override
  State<BackupToolsScreen> createState() => _BackupToolsScreenState();
}

class _BackupToolsScreenState extends State<BackupToolsScreen> {
  final DataBackupService _service = DataBackupService(
    recoveryReconcile: () => AppSystemServices.instance.reminders.reconcile(),
  );
  final BackupFileExportService _exportService =
      const BackupFileExportService();

  BackupInspection? _inspection;
  String? _selectedPath;
  String? _status;
  bool _busy = false;
  bool _cancelRequested = false;
  double? _progress;

  Future<void> _createBackup() async {
    await _run(() async {
      _cancelRequested = false;
      final result = await _service.createBackup(
        BackupOptions(
          shouldCancel: () => _cancelRequested,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        ),
      );

      final temporaryBackup = File(result.path);
      Uri? durableLocation;
      try {
        durableLocation = await _exportService.exportFile(
          sourcePath: temporaryBackup.path,
          fileName: p.basename(result.path),
          dialogTitle: 'backup_create'.tr(),
        );
      } finally {
        if (await temporaryBackup.exists()) {
          await temporaryBackup.delete();
        }
      }
      if (durableLocation == null) {
        if (!mounted) return;
        setState(() => _status = 'backup_cancelled'.tr());
        return;
      }

      final durablePath = durableLocation.toString();
      if (!mounted) return;
      setState(() {
        _status = 'backup_created'.tr(
          namedArgs: {
            'records': result.recordCount.toString(),
            'files': result.fileCount.toString(),
            'path': durablePath,
          },
        );
      });
    });
  }

  Future<void> _pickBackup() async {
    await _run(() async {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      final path = picked?.path;
      if (path == null) return;
      final inspection = await _service.inspectBackup(path);
      if (!mounted) return;
      setState(() {
        _selectedPath = path;
        _inspection = inspection;
        _status = inspection.isValid
            ? 'backup_valid'.tr(
                namedArgs: {
                  'records': inspection.recordCounts.values
                      .fold<int>(0, (sum, value) => sum + value)
                      .toString(),
                  'files': inspection.fileCount.toString(),
                },
              )
            : 'backup_invalid'.tr(
                namedArgs: {'reason': inspection.errors.join(', ')},
              );
      });
    });
  }

  Future<void> _restore(RestoreStrategy strategy) async {
    final path = _selectedPath;
    if (path == null || _inspection?.isValid != true) return;

    if (strategy == RestoreStrategy.replaceAll) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('backup_replace_confirm_title'.tr()),
              content: Text('backup_replace_confirm_body'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr()),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('backup_restore_replace'.tr()),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    await _run(() async {
      final result = await _service.restoreBackup(path, strategy);
      await AppSystemServices.instance.reminders.reconcile();
      await AppSystemServices.instance.search.ensureFresh(force: true);
      AppSystemServices.instance.lastIntegrityReport =
          await AppSystemServices.instance.integrity.audit();
      if (!mounted) return;
      setState(() {
        _status = 'backup_restored'.tr(
          namedArgs: {
            'restored': result.restoredRecords.toString(),
            'skipped': result.skippedRecords.toString(),
            'conflicts': result.conflicts.toString(),
          },
        );
      });
    });
  }

  Future<void> _export() async {
    await _run(() async {
      final csv = await _service.exportCsv();
      final pdf = await _service.exportVehiclePdf();

      final pdfLocation = await _exportTemporaryFile(
        pdf,
        mimeType: 'application/pdf',
      );
      final csvLocations = <String>[];
      for (final entry in csv.entries) {
        final location = await _exportTemporaryFile(
          entry.value,
          mimeType: 'text/csv',
        );
        if (location != null) {
          csvLocations.add(location.toString());
        }
      }

      if (pdfLocation == null && csvLocations.isEmpty) {
        if (!mounted) return;
        setState(() => _status = 'backup_cancelled'.tr());
        return;
      }
      if (!mounted) return;
      setState(() {
        _status = 'backup_exported'.tr(
          namedArgs: {
            'pdf': pdfLocation?.toString() ?? '',
            'csv': csvLocations.join(', '),
          },
        );
      });
    });
  }

  Future<Uri?> _exportTemporaryFile(
    File file, {
    required String mimeType,
  }) async {
    try {
      return await _exportService.exportFile(
        sourcePath: file.path,
        fileName: p.basename(file.path),
        mimeType: mimeType,
        dialogTitle: 'backup_export'.tr(),
      );
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } on BackupCancelledException {
      if (!mounted) return;
      setState(() => _status = 'backup_cancelled'.tr());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'backup_failed'.tr(
          namedArgs: {'reason': error.toString()},
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _cancelRequested = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;

    return ScreenScaffold(
      title: 'backup_title'.tr(),
      subtitle: 'backup_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _createBackup,
                icon: const Icon(Icons.backup_outlined),
                label: Text('backup_create'.tr()),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickBackup,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text('backup_inspect'.tr()),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.file_download_outlined),
                label: Text('backup_export'.tr()),
              ),
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          if (_progress != null)
            Text('${(_progress! * 100).round()}%'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _cancelRequested = true),
              icon: const Icon(Icons.cancel_outlined),
              label: Text('backup_cancel'.tr()),
            ),
          ),
        ],
        if (_status != null) ...[
          const SizedBox(height: 16),
          PremiumCard(child: SelectableText(_status!)),
        ],
        if (inspection?.isValid == true) ...[
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'backup_restore_mode'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _restore(RestoreStrategy.merge),
                  child: Text('backup_restore_merge'.tr()),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _restore(RestoreStrategy.replaceAll),
                  child: Text('backup_restore_replace'.tr()),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
