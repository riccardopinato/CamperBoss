import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/document_storage_service.dart';
import '../../../core/services/app_system_services.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../core/utils/locale_number_parser.dart';
import '../../../data/models/maintenance_record.dart';
import '../../../data/models/vehicle_profile.dart';
import '../../../data/repositories/local_maintenance_repository.dart';
import '../../../data/repositories/local_vehicle_profile_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({
    this.repository,
    this.reminderService,
    this.vehicleProfileRepository,
    this.initialRecordId,
    super.key,
  });

  final MaintenanceRepository? repository;
  final ReminderSyncService? reminderService;
  final VehicleProfileRepository? vehicleProfileRepository;
  final int? initialRecordId;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final MaintenanceRepository _repository =
      widget.repository ?? LocalMaintenanceRepository();
  late final ReminderSyncService _reminderService =
      widget.reminderService ?? AppSystemServices.instance.reminders;
  late final DocumentStorageService _storageService =
      createDocumentStorageService();
  late final VehicleProfileRepository _vehicleProfileRepository =
      widget.vehicleProfileRepository ?? LocalVehicleProfileRepository();

  List<MaintenanceRecord> _records = const [];
  double? _currentMileage;
  bool _isLoading = true;
  String? _error;

  MaintenanceStatus _status(MaintenanceRecord record) =>
      record.status(currentMileage: _currentMileage);

  int get _dueSoonCount => _records
      .where((record) => _status(record) == MaintenanceStatus.dueSoon)
      .length;

  int get _overdueCount => _records
      .where((record) => _status(record) == MaintenanceStatus.overdue)
      .length;

  double get _totalCost =>
      _records.fold(0, (total, record) => total + (record.cost ?? 0));

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await _repository.listRecords();
      VehicleProfile? profile;
      try {
        profile = await _vehicleProfileRepository.loadProfile();
      } catch (_) {
        profile = null;
      }
      if (!mounted) return;
      final targetId = widget.initialRecordId;
      if (targetId != null) {
        records.sort((a, b) {
          if (a.id == targetId) return -1;
          if (b.id == targetId) return 1;
          return _sortRecords(a, b);
        });
      }
      setState(() {
        _records = records;
        _currentMileage = profile?.mileage;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'maintenance_error_load'.tr();
      });
    }
  }

  Future<void> _openEditor({MaintenanceRecord? record}) async {
    final result = await showModalBottomSheet<MaintenanceRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MaintenanceEditor(
        record: record,
        storageService: _storageService,
      ),
    );
    if (result == null) return;

    try {
      final saved = await _repository.saveRecord(result);
      await _reminderService.syncMaintenance(saved);
      if (!mounted) return;
      setState(() {
        if (record == null) {
          _records = [saved, ..._records];
        } else {
          _records = [
            for (final existing in _records)
              if (existing.id == saved.id) saved else existing,
          ];
        }
        _records = [..._records]..sort(_sortRecords);
        _error = null;
      });
    } catch (_) {
      final previous = (record?.attachmentPaths ?? const <String>[]).toSet();
      await _storageService.deleteFiles(
        result.attachmentPaths.where((path) => !previous.contains(path)),
      );
      if (!mounted) return;
      setState(() => _error = 'maintenance_error_save'.tr());
    }
  }

  Future<void> _deleteRecord(MaintenanceRecord record) async {
    final id = record.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('maintenance_delete_title'.tr()),
            content: Text(
              'maintenance_delete_body'.tr(namedArgs: {'title': record.title}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('delete'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final previous = _records;
    setState(() => _records = _records.where((item) => item.id != id).toList());

    try {
      await _repository.deleteRecord(id);
      await _reminderService.deleteMaintenanceReminders(id.toString());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = previous;
        _error = 'maintenance_error_delete'.tr();
      });
    }
  }

  int _sortRecords(MaintenanceRecord a, MaintenanceRecord b) {
    final date = b.date.compareTo(a.date);
    if (date != 0) return date;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'maintenance_title'.tr(),
      subtitle: 'maintenance_subtitle'.tr(),
      children: [
        GridView.extent(
          maxCrossAxisExtent: 190,
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              icon: Icons.build_circle_outlined,
              label: 'maintenance_records'.tr(),
              value: _records.length.toString(),
              detail: 'maintenance_history'.tr(),
            ),
            MetricTile(
              icon: Icons.event_busy_outlined,
              label: 'maintenance_due_soon'.tr(),
              value: _dueSoonCount.toString(),
              detail: 'maintenance_due_window'.tr(),
            ),
            MetricTile(
              icon: Icons.payments_outlined,
              label: 'maintenance_spend'.tr(),
              value: _totalCost.toStringAsFixed(0),
              detail: 'maintenance_spend_detail'.tr(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: Text('maintenance_add'.tr()),
              ),
            ),
            if (_overdueCount > 0) ...[
              const SizedBox(width: 12),
              Chip(
                avatar: const Icon(Icons.warning_amber_outlined),
                label: Text(
                  'maintenance_overdue_count'.tr(
                    namedArgs: {'count': _overdueCount.toString()},
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_currentMileage == null) ...[
          const SizedBox(height: 12),
          Text(
            'maintenance_mileage_missing'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        SectionHeader(title: 'maintenance_history'.tr()),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_records.isEmpty)
          PremiumCard(child: Text('maintenance_empty'.tr()))
        else
          for (final record in _records) ...[
            _MaintenanceCard(
              record: record,
              currentMileage: _currentMileage,
              onEdit: () => _openEditor(record: record),
              onDelete: () => _deleteRecord(record),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.record,
    required this.currentMileage,
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceRecord record;
  final double? currentMileage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = record.status(currentMileage: currentMileage);

    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(_iconForStatus(status))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    _categoryLabel(record.category),
                    _dateLabel(record.date),
                    '${record.mileage.round()} km',
                    if (record.cost != null)
                      'maintenance_cost_value'.tr(
                        namedArgs: {
                          'value': record.cost!.toStringAsFixed(2),
                        },
                      ),
                  ].join(' - '),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    _statusLabel(status),
                    if (record.nextDueDate != null)
                      'maintenance_next_date'.tr(
                        namedArgs: {'date': _dateLabel(record.nextDueDate!)},
                      ),
                    if (record.nextDueMileage != null)
                      'maintenance_next_km'.tr(
                        namedArgs: {
                          'km': record.nextDueMileage!.round().toString(),
                        },
                      ),
                    if (record.attachmentPaths.isNotEmpty)
                      'maintenance_attachments_count'.tr(
                        namedArgs: {
                          'count': record.attachmentPaths.length.toString(),
                        },
                      ),
                  ].join(' - '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(record.notes!),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'maintenance_edit'.tr(),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'maintenance_delete'.tr(),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  static IconData _iconForStatus(MaintenanceStatus status) {
    return switch (status) {
      MaintenanceStatus.regular => Icons.check_circle_outline,
      MaintenanceStatus.dueSoon => Icons.schedule_outlined,
      MaintenanceStatus.overdue => Icons.warning_amber_outlined,
    };
  }

  static String _statusLabel(MaintenanceStatus status) {
    return switch (status) {
      MaintenanceStatus.regular => 'maintenance_status_regular'.tr(),
      MaintenanceStatus.dueSoon => 'maintenance_status_due_soon'.tr(),
      MaintenanceStatus.overdue => 'maintenance_status_overdue'.tr(),
    };
  }

  static String _categoryLabel(String category) {
    final key = switch (category) {
      'Oil' => 'maintenance_category_oil',
      'Filters' => 'maintenance_category_filters',
      'Inspection' => 'maintenance_category_inspection',
      'Service' => 'maintenance_category_service',
      'Gas' => 'maintenance_category_gas',
      'Extinguisher' => 'maintenance_category_extinguisher',
      'Tires' => 'maintenance_category_tires',
      'Batteries' => 'maintenance_category_batteries',
      'Timing belt' => 'maintenance_category_timing_belt',
      'AdBlue' => 'maintenance_category_adblue',
      'Leaks' => 'maintenance_category_leaks',
      _ => 'maintenance_category_custom',
    };
    return key.tr();
  }

  static String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _MaintenanceEditor extends StatefulWidget {
  const _MaintenanceEditor({
    required this.storageService,
    this.record,
  });

  final MaintenanceRecord? record;
  final DocumentStorageService storageService;

  @override
  State<_MaintenanceEditor> createState() => _MaintenanceEditorState();
}

class _MaintenanceEditorState extends State<_MaintenanceEditor> {
  static const _categories = [
    'Oil',
    'Filters',
    'Inspection',
    'Service',
    'Gas',
    'Extinguisher',
    'Tires',
    'Batteries',
    'Timing belt',
    'AdBlue',
    'Leaks',
    'Custom',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _providerController;
  late final TextEditingController _notesController;
  late final TextEditingController _intervalMonthsController;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _nextDueKmController;
  late String _category;
  late DateTime _date;
  late List<String> _attachmentPaths;
  final List<String> _pendingAttachmentSources = [];
  DateTime? _nextDueDate;
  bool _isSaving = false;
  String? _attachmentError;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _category = record?.category ?? _categories.first;
    _date = record?.date ?? DateTime.now();
    _nextDueDate = record?.nextDueDate;
    _attachmentPaths = [...?record?.attachmentPaths];
    _titleController = TextEditingController(text: record?.title ?? '');
    _mileageController = TextEditingController(
      text: record?.mileage.toStringAsFixed(0) ?? '',
    );
    _costController = TextEditingController(
      text: record?.cost?.toStringAsFixed(2) ?? '',
    );
    _providerController = TextEditingController(text: record?.provider ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _intervalMonthsController = TextEditingController(
      text: record?.intervalMonths?.toString() ?? '',
    );
    _intervalKmController = TextEditingController(
      text: record?.intervalKilometers?.toStringAsFixed(0) ?? '',
    );
    _nextDueKmController = TextEditingController(
      text: record?.nextDueMileage?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    _intervalMonthsController.dispose();
    _intervalKmController.dispose();
    _nextDueKmController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool nextDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextDue ? _nextDueDate ?? DateTime.now() : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (picked == null) return;
    setState(() {
      if (nextDue) {
        _nextDueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _pickAttachments() async {
    if (kIsWeb || _isSaving) return;
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty || !mounted) return;
      final sources = result.files
          .map((file) => file.path)
          .whereType<String>()
          .where((path) => path.trim().isNotEmpty)
          .toList(growable: false);
      setState(() {
        for (final source in sources) {
          if (!_pendingAttachmentSources.contains(source)) {
            _pendingAttachmentSources.add(source);
          }
        }
        _attachmentError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _attachmentError = 'maintenance_attachment_pick_failed'.tr());
    }
  }

  void _removeExistingAttachment(String path) {
    setState(() => _attachmentPaths.remove(path));
  }

  void _removePendingAttachment(String path) {
    setState(() => _pendingAttachmentSources.remove(path));
  }

  String _attachmentName(String path) {
    final name = p.basename(path);
    return name.isEmpty ? 'maintenance_attachment_file'.tr() : name;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'form_required'.tr();
    return null;
  }

  String? _nonNegative(String? value) {
    final parsed = parseLocaleDouble(value ?? '');
    if (parsed == null) return 'form_number_invalid'.tr();
    if (parsed < 0) return 'form_number_non_negative'.tr();
    return null;
  }

  String? _optionalNonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _nonNegative(value);
  }

  String? _optionalPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'form_number_invalid'.tr();
    if (parsed <= 0) return 'form_number_positive'.tr();
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final mileage = parseLocaleDouble(_mileageController.text)!;
    final intervalMonths = int.tryParse(_intervalMonthsController.text.trim());
    final intervalKm = parseLocaleDouble(_intervalKmController.text);
    final nextDueKm = parseLocaleDouble(_nextDueKmController.text) ??
        (intervalKm == null ? null : mileage + intervalKm);
    final provider = _providerController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _isSaving = true;
      _attachmentError = null;
    });

    final copied = <String>[];
    try {
      for (final source in _pendingAttachmentSources) {
        copied.add(
          await widget.storageService.copyIntoPrivateDocuments(source),
        );
      }

      if (!mounted) {
        await widget.storageService.deleteFiles(copied);
        return;
      }

      Navigator.of(context).pop(
        MaintenanceRecord(
          id: widget.record?.id,
          category: _category,
          title: _titleController.text.trim(),
          date: _date,
          mileage: mileage,
          cost: parseLocaleDouble(_costController.text),
          provider: provider.isEmpty ? null : provider,
          notes: notes.isEmpty ? null : notes,
          intervalMonths: intervalMonths,
          intervalKilometers: intervalKm,
          nextDueDate: _nextDueDate ??
              (intervalMonths == null
                  ? null
                  : DateTime(
                      _date.year,
                      _date.month + intervalMonths,
                      _date.day,
                    )),
          nextDueMileage: nextDueKm,
          attachmentPaths: [..._attachmentPaths, ...copied],
          createdAt: widget.record?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      await widget.storageService.deleteFiles(copied);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _attachmentError = 'maintenance_attachment_copy_failed'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const decimalKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.record == null
                    ? 'maintenance_add'.tr()
                    : 'maintenance_edit'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(_MaintenanceCard._categoryLabel(category)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
                decoration:
                    InputDecoration(labelText: 'maintenance_category'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                validator: _requiredText,
                decoration: InputDecoration(labelText: 'maintenance_item_title'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageController,
                keyboardType: decimalKeyboard,
                validator: _nonNegative,
                decoration:
                    InputDecoration(labelText: 'maintenance_mileage'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: decimalKeyboard,
                validator: _optionalNonNegative,
                decoration: InputDecoration(labelText: 'maintenance_cost'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerController,
                decoration:
                    InputDecoration(labelText: 'maintenance_provider'.tr()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickDate(nextDue: false),
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  'maintenance_service_date'.tr(
                    namedArgs: {'date': _MaintenanceCard._dateLabel(_date)},
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickDate(nextDue: true),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  _nextDueDate == null
                      ? 'maintenance_next_due_date'.tr()
                      : 'maintenance_next_date'.tr(
                          namedArgs: {
                            'date':
                                _MaintenanceCard._dateLabel(_nextDueDate!),
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervalMonthsController,
                keyboardType: TextInputType.number,
                validator: _optionalPositiveInt,
                decoration:
                    InputDecoration(labelText: 'maintenance_interval_months'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervalKmController,
                keyboardType: decimalKeyboard,
                validator: _optionalNonNegative,
                decoration:
                    InputDecoration(labelText: 'maintenance_interval_km'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nextDueKmController,
                keyboardType: decimalKeyboard,
                validator: _optionalNonNegative,
                decoration:
                    InputDecoration(labelText: 'maintenance_next_due_km'.tr()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'maintenance_attachments'.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: kIsWeb || _isSaving ? null : _pickAttachments,
                    icon: const Icon(Icons.attach_file),
                    label: Text('maintenance_attachment_add'.tr()),
                  ),
                ],
              ),
              if (kIsWeb)
                Text(
                  'maintenance_attachment_native_only'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_attachmentPaths.isEmpty &&
                  _pendingAttachmentSources.isEmpty &&
                  !kIsWeb)
                Text(
                  'maintenance_attachment_empty'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              for (final path in _attachmentPaths)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_attachmentName(path)),
                  trailing: IconButton(
                    tooltip: 'remove'.tr(),
                    onPressed: _isSaving
                        ? null
                        : () => _removeExistingAttachment(path),
                    icon: const Icon(Icons.close),
                  ),
                ),
              for (final path in _pendingAttachmentSources)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(_attachmentName(path)),
                  subtitle: Text('maintenance_attachment_pending'.tr()),
                  trailing: IconButton(
                    tooltip: 'remove'.tr(),
                    onPressed: _isSaving
                        ? null
                        : () => _removePendingAttachment(path),
                    icon: const Icon(Icons.close),
                  ),
                ),
              if (_attachmentError != null)
                Text(
                  _attachmentError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'maintenance_notes'.tr()),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('save'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
