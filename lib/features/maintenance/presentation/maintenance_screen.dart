import 'package:flutter/material.dart';

import '../../../data/models/maintenance_record.dart';
import '../../../data/repositories/local_maintenance_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({
    this.repository,
    super.key,
  });

  final MaintenanceRepository? repository;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final MaintenanceRepository _repository =
      widget.repository ?? LocalMaintenanceRepository();

  List<MaintenanceRecord> _records = const [];
  bool _isLoading = true;
  String? _error;

  int get _dueSoonCount {
    return _records
        .where((record) => record.status() == MaintenanceStatus.dueSoon)
        .length;
  }

  int get _overdueCount {
    return _records
        .where((record) => record.status() == MaintenanceStatus.overdue)
        .length;
  }

  double get _totalCost {
    return _records.fold(0, (total, record) => total + (record.cost ?? 0));
  }

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
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Maintenance history unavailable';
      });
    }
  }

  Future<void> _openEditor({MaintenanceRecord? record}) async {
    final result = await showModalBottomSheet<MaintenanceRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MaintenanceEditor(record: record),
    );
    if (result == null) return;

    try {
      final saved = await _repository.saveRecord(result);
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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Maintenance save failed');
    }
  }

  Future<void> _deleteRecord(MaintenanceRecord record) async {
    final id = record.id;
    if (id == null) return;

    final previous = _records;
    setState(() => _records = _records.where((item) => item.id != id).toList());

    try {
      await _repository.deleteRecord(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = previous;
        _error = 'Maintenance delete failed';
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
      title: 'Maintenance',
      subtitle: 'Track service history, intervals, due dates, and attachments.',
      children: [
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.92,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              icon: Icons.build_circle_outlined,
              label: 'Records',
              value: _records.length.toString(),
              detail: 'History',
            ),
            MetricTile(
              icon: Icons.event_busy_outlined,
              label: 'Due soon',
              value: _dueSoonCount.toString(),
              detail: '30 days',
            ),
            MetricTile(
              icon: Icons.euro_outlined,
              label: 'Spend',
              value: _totalCost.round().toString(),
              detail: 'Tracked',
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
                label: const Text('Add service'),
              ),
            ),
            if (_overdueCount > 0) ...[
              const SizedBox(width: 12),
              Chip(
                avatar: const Icon(Icons.warning_amber_outlined),
                label: Text('$_overdueCount overdue'),
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeader(title: 'History'),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_records.isEmpty)
          const PremiumCard(child: Text('No maintenance records yet'))
        else
          for (final record in _records) ...[
            _MaintenanceCard(
              record: record,
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
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = record.status();

    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(_iconForStatus(status)),
          ),
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
                    record.category,
                    _dateLabel(record.date),
                    '${record.mileage.round()} km',
                    if (record.cost != null) 'EUR ${record.cost!.round()}',
                  ].join(' - '),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    status.label,
                    if (record.nextDueDate != null)
                      'Next ${_dateLabel(record.nextDueDate!)}',
                    if (record.nextDueMileage != null)
                      '${record.nextDueMileage!.round()} km',
                    if (record.attachmentPaths.isNotEmpty)
                      '${record.attachmentPaths.length} attachments',
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
            tooltip: 'Edit service',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete service',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  IconData _iconForStatus(MaintenanceStatus status) {
    return switch (status) {
      MaintenanceStatus.regular => Icons.check_circle_outline,
      MaintenanceStatus.dueSoon => Icons.schedule_outlined,
      MaintenanceStatus.overdue => Icons.warning_amber_outlined,
    };
  }

  static String _dateLabel(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class _MaintenanceEditor extends StatefulWidget {
  const _MaintenanceEditor({this.record});

  final MaintenanceRecord? record;

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

  late final TextEditingController _titleController;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _providerController;
  late final TextEditingController _notesController;
  late final TextEditingController _intervalMonthsController;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _nextDueKmController;
  late final TextEditingController _attachmentsController;
  late String _category;
  late DateTime _date;
  DateTime? _nextDueDate;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _category = record?.category ?? _categories.first;
    _date = record?.date ?? DateTime.now();
    _nextDueDate = record?.nextDueDate;
    _titleController = TextEditingController(text: record?.title ?? '');
    _mileageController = TextEditingController(
      text: record?.mileage.round().toString() ?? '',
    );
    _costController = TextEditingController(
      text: record?.cost?.round().toString() ?? '',
    );
    _providerController = TextEditingController(text: record?.provider ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _intervalMonthsController = TextEditingController(
      text: record?.intervalMonths?.toString() ?? '',
    );
    _intervalKmController = TextEditingController(
      text: record?.intervalKilometers?.round().toString() ?? '',
    );
    _nextDueKmController = TextEditingController(
      text: record?.nextDueMileage?.round().toString() ?? '',
    );
    _attachmentsController = TextEditingController(
      text: record?.attachmentPaths.join('\n') ?? '',
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
    _attachmentsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool nextDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextDue ? _nextDueDate ?? DateTime.now() : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
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

  void _save() {
    final title = _titleController.text.trim();
    final mileage = double.tryParse(_mileageController.text.trim());
    if (title.isEmpty || mileage == null) return;

    final intervalMonths = int.tryParse(_intervalMonthsController.text.trim());
    final intervalKm = double.tryParse(_intervalKmController.text.trim());
    final nextDueKm = double.tryParse(_nextDueKmController.text.trim()) ??
        (intervalKm == null ? null : mileage + intervalKm);
    final provider = _providerController.text.trim();
    final notes = _notesController.text.trim();
    final attachments = _attachmentsController.text
        .split('\n')
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      MaintenanceRecord(
        id: widget.record?.id,
        category: _category,
        title: title,
        date: _date,
        mileage: mileage,
        cost: double.tryParse(_costController.text.trim()),
        provider: provider.isEmpty ? null : provider,
        notes: notes.isEmpty ? null : notes,
        intervalMonths: intervalMonths,
        intervalKilometers: intervalKm,
        nextDueDate: _nextDueDate ??
            (intervalMonths == null
                ? null
                : DateTime(
                    _date.year, _date.month + intervalMonths, _date.day)),
        nextDueMileage: nextDueKm,
        attachmentPaths: attachments,
        createdAt: widget.record?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.record == null ? 'Add service' : 'Edit service',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Km'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _providerController,
              decoration: const InputDecoration(labelText: 'Provider'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(nextDue: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateLabel(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(nextDue: true),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(
                      _nextDueDate == null
                          ? 'Next due'
                          : _dateLabel(_nextDueDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _intervalMonthsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Interval months',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _intervalKmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Interval km'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nextDueKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Next due km'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _attachmentsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Attachment paths',
                hintText: 'One local path per line',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
