import 'package:flutter/material.dart';

import '../../../data/models/checklist_item.dart';
import '../../../data/repositories/local_checklist_repository.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/checklist_item_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({
    this.repository,
    super.key,
  });

  final ChecklistRepository? repository;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  static const _categories = ['Pre-trip', 'Arrival', 'Service', 'Winter'];

  late final ChecklistRepository _repository =
      widget.repository ?? LocalChecklistRepository();
  List<CamperChecklistItem> _items = const [];
  bool _isLoading = true;
  String? _error;

  double get _progress {
    if (_items.isEmpty) return 0;
    return _items.where((item) => item.checked).length / _items.length;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var items = await _repository.listItems();
      if (items.isEmpty) {
        items = await _seedInitialItems();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Checklist unavailable';
      });
    }
  }

  Future<List<CamperChecklistItem>> _seedInitialItems() async {
    final seeds = <CamperChecklistItem>[
      for (final (index, item) in MockCamperRepository.checklist.indexed)
        item.copyWith(
          listName: 'Departure list',
          category: 'Pre-trip',
          position: index,
        ),
      const CamperChecklistItem(
        title: 'Level camper and stabilize',
        subtitle: 'Check slope before opening fridge',
        checked: false,
        listName: 'Arrival list',
        category: 'Arrival',
        position: 100,
      ),
      const CamperChecklistItem(
        title: 'Switch fridge to site mode',
        checked: false,
        listName: 'Arrival list',
        category: 'Arrival',
        position: 101,
      ),
      const CamperChecklistItem(
        title: 'Log overnight location',
        subtitle: 'Useful for journal and emergency sharing',
        checked: true,
        listName: 'Arrival list',
        category: 'Arrival',
        position: 102,
      ),
    ];

    final saved = <CamperChecklistItem>[];
    for (final item in seeds) {
      saved.add(await _repository.saveItem(item));
    }
    return saved;
  }

  Future<void> _toggle(CamperChecklistItem item, bool? value) async {
    final updated = item.copyWith(
      checked: value ?? false,
      updatedAt: DateTime.now(),
    );
    await _saveAndReplace(updated);
  }

  Future<void> _saveAndReplace(CamperChecklistItem item) async {
    final previous = _items;
    setState(() {
      _items = [
        for (final existing in _items)
          if (existing.id == item.id) item else existing,
      ];
    });

    try {
      final saved = await _repository.saveItem(item);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final existing in _items)
            if (existing.id == item.id) saved else existing,
        ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previous;
        _error = 'Checklist save failed';
      });
    }
  }

  Future<void> _deleteItem(CamperChecklistItem item) async {
    final id = item.id;
    if (id == null) return;

    final previous = _items;
    setState(() => _items = _items.where((entry) => entry.id != id).toList());

    try {
      await _repository.deleteItem(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previous;
        _error = 'Checklist delete failed';
      });
    }
  }

  Future<void> _openEditor({CamperChecklistItem? item}) async {
    final result = await showModalBottomSheet<CamperChecklistItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ChecklistItemEditor(
          item: item,
          categories: _categories,
          position: _items.length,
        );
      },
    );

    if (result == null) return;

    if (item == null) {
      try {
        final saved = await _repository.saveItem(result);
        if (!mounted) return;
        setState(() => _items = [..._items, saved]);
      } catch (_) {
        if (!mounted) return;
        setState(() => _error = 'Checklist save failed');
      }
    } else {
      await _saveAndReplace(result.copyWith(id: item.id));
    }
  }

  List<CamperChecklistItem> _itemsFor(String category) {
    return _items.where((item) => item.category == category).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Checklist',
      subtitle: 'Tap checks, track progress, and keep routines saved.',
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceBar(
                label: 'Overall readiness',
                value: _progress,
                detail:
                    '${(_progress * 100).round()}% completed across routines',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add check'),
              ),
            ],
          ),
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
        else
          for (final category in _categories) ...[
            _ChecklistCategorySection(
              title: category,
              items: _itemsFor(category),
              onChanged: _toggle,
              onEdit: (item) => _openEditor(item: item),
              onDelete: _deleteItem,
            ),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

class _ChecklistCategorySection extends StatelessWidget {
  const _ChecklistCategorySection({
    required this.title,
    required this.items,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<CamperChecklistItem> items;
  final void Function(CamperChecklistItem item, bool? value) onChanged;
  final ValueChanged<CamperChecklistItem> onEdit;
  final ValueChanged<CamperChecklistItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, action: '${items.length} items'),
        const SizedBox(height: 12),
        PremiumCard(
          child: items.isEmpty
              ? Text(
                  'No checks yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Column(
                  children: [
                    for (final item in items)
                      Row(
                        children: [
                          Expanded(
                            child: ChecklistItemTile(
                              title: item.title,
                              subtitle: item.subtitle ?? item.listName,
                              checked: item.checked,
                              onChanged: (value) => onChanged(item, value),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => onEdit(item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => onDelete(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChecklistItemEditor extends StatefulWidget {
  const _ChecklistItemEditor({
    required this.categories,
    required this.position,
    this.item,
  });

  final CamperChecklistItem? item;
  final List<String> categories;
  final int position;

  @override
  State<_ChecklistItemEditor> createState() => _ChecklistItemEditorState();
}

class _ChecklistItemEditorState extends State<_ChecklistItemEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _listController;
  late String _category;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _subtitleController = TextEditingController(text: item?.subtitle ?? '');
    _listController = TextEditingController(text: item?.listName ?? 'Camper');
    _category = item?.category ?? widget.categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final subtitle = _subtitleController.text.trim();
    final listName = _listController.text.trim();
    final item = widget.item;

    Navigator.of(context).pop(
      CamperChecklistItem(
        id: item?.id,
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        checked: item?.checked ?? false,
        listName: listName.isEmpty ? 'Camper' : listName,
        category: _category,
        position: item?.position ?? widget.position,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item == null ? 'Add check' : 'Edit check',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _listController,
            decoration: const InputDecoration(labelText: 'List'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final category in widget.categories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Category'),
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
    );
  }
}
