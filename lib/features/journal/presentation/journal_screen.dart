import 'package:flutter/material.dart';

import '../../../data/models/journal_entry.dart';
import '../../../data/repositories/local_journal_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    this.repository,
    this.initialEntryId,
    super.key,
  });

  final JournalRepository? repository;
  final int? initialEntryId;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final JournalRepository _repository =
      widget.repository ?? LocalJournalRepository();

  List<JournalEntry> _entries = const [];
  bool _isLoading = true;
  String? _error;

  double get _totalKm => _entries.fold(
        0,
        (total, entry) => total + (entry.kilometers ?? 0),
      );

  double get _totalCost => _entries.fold(
        0,
        (total, entry) => total + (entry.cost ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _repository.listEntries();
      if (!mounted) return;
      final targetId = widget.initialEntryId;
      if (targetId != null) {
        entries.sort((a, b) {
          if (a.id == targetId) return -1;
          if (b.id == targetId) return 1;
          return _sortEntries(a, b);
        });
      }
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'journal_error_unavailable'.tr();
      });
    }
  }

  Future<void> _openEditor({JournalEntry? entry}) async {
    final result = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _JournalEntryEditor(entry: entry),
    );

    if (result == null) return;

    try {
      final saved = await _repository.saveEntry(result.copyWith(id: entry?.id));
      if (!mounted) return;
      setState(() {
        if (entry == null) {
          _entries = [saved, ..._entries];
        } else {
          _entries = [
            for (final existing in _entries)
              if (existing.id == saved.id) saved else existing,
          ];
        }
        _entries = [..._entries]..sort(_sortEntries);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'journal_error_save'.tr());
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final id = entry.id;
    if (id == null) return;

    final previous = _entries;
    setState(() => _entries = _entries.where((item) => item.id != id).toList());

    try {
      await _repository.deleteEntry(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = previous;
        _error = 'journal_error_delete'.tr();
      });
    }
  }

  int _sortEntries(JournalEntry a, JournalEntry b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Travel journal',
      subtitle: 'Keep notes, places, mileage, costs, and favorite stops.',
      children: [
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.95,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              icon: Icons.route_outlined,
              label: 'Km',
              value: _totalKm.round().toString(),
              detail: 'Tracked',
            ),
            MetricTile(
              icon: Icons.euro_outlined,
              label: 'Spend',
              value: _totalCost.round().toString(),
              detail: 'Logged',
            ),
            MetricTile(
              icon: Icons.favorite_border,
              label: 'Stops',
              value: _entries.length.toString(),
              detail: 'Saved',
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Add journal note'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_entries.isEmpty)
          const PremiumCard(child: Text('No journal notes yet'))
        else
          for (final entry in _entries) ...[
            _JournalEntryCard(
              entry: entry,
              onEdit: () => _openEditor(entry: entry),
              onDelete: () => _deleteEntry(entry),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: const Icon(Icons.photo_camera_outlined),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(entry.summary),
                const SizedBox(height: 8),
                Text(
                  [
                    if (entry.createdAt != null) _dateLabel(entry.createdAt!),
                    if (entry.place != null && entry.place!.isNotEmpty)
                      entry.place!,
                    if (entry.kilometers != null)
                      '${entry.kilometers!.round()} km',
                    if (entry.cost != null) 'EUR ${entry.cost!.round()}',
                  ].join(' - '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit note',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete note',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class _JournalEntryEditor extends StatefulWidget {
  const _JournalEntryEditor({this.entry});

  final JournalEntry? entry;

  @override
  State<_JournalEntryEditor> createState() => _JournalEntryEditorState();
}

class _JournalEntryEditorState extends State<_JournalEntryEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _placeController;
  late final TextEditingController _kmController;
  late final TextEditingController _costController;
  DateTime _createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _summaryController = TextEditingController(text: entry?.summary ?? '');
    _placeController = TextEditingController(text: entry?.place ?? '');
    _kmController = TextEditingController(
      text: entry?.kilometers?.round().toString() ?? '',
    );
    _costController = TextEditingController(
      text: entry?.cost?.round().toString() ?? '',
    );
    _createdAt = entry?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _placeController.dispose();
    _kmController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _createdAt = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    if (title.isEmpty || summary.isEmpty) return;

    final place = _placeController.text.trim();

    Navigator.of(context).pop(
      JournalEntry(
        id: widget.entry?.id,
        title: title,
        summary: summary,
        createdAt: _createdAt,
        place: place.isEmpty ? null : place,
        kilometers: double.tryParse(_kmController.text.trim()),
        cost: double.tryParse(_costController.text.trim()),
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
              widget.entry == null ? 'Add note' : 'Edit note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Place'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kmController,
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
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                '${_createdAt.year}-${_createdAt.month}-${_createdAt.day}',
              ),
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
}
