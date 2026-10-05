import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../data/models/checklist_item.dart';
import '../../../data/repositories/local_checklist_repository.dart';
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
      final items = await _repository.listItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'checklist_error_unavailable'.tr();
      });
    }
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
        _error = 'checklist_error_save'.tr();
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
        _error = 'checklist_error_delete'.tr();
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
      title: 'checklist_title'.tr(),
      subtitle: 'checklist_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceBar(
                label: 'checklist_overall_readiness'.tr(),
                value: _progress,
                detail:
                    'checklist_progress_detail'.tr(
                    namedArgs: {
                      'percent': (_progress * 100).round().toString(),
                    },
                  ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: Text('checklist_add'.tr()),
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
        else if (_items.isEmpty)
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checklist_empty_title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text('checklist_empty_body'.tr()),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: Text('checklist_create_first'.tr()),
                ),
              ],
            ),
          )
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

String _categoryLabel(String category) {
  return switch (category) {
    'Pre-trip' => 'checklist_cat_pretrip'.tr(),
    'Arrival' => 'checklist_cat_arrival'.tr(),
    'Service' => 'checklist_cat_service'.tr(),
    'Winter' => 'checklist_cat_winter'.tr(),
    _ => category,
  };
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
        SectionHeader(
          title: _categoryLabel(title),
          action: 'checklist_items_count'.tr(
            namedArgs: {'count': items.length.toString()},
          ),
        ),
        const SizedBox(height: 12),
        PremiumCard(
          child: items.isEmpty
              ? Text(
                  'checklist_category_empty'.tr(),
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
                            tooltip: 'common_edit'.tr(),
                            onPressed: () => onEdit(item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'common_delete'.tr(),
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
            widget.item == null ? 'checklist_add'.tr() : 'checklist_edit'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'common_title'.tr()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleController,
            decoration: InputDecoration(labelText: 'checklist_details'.tr()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _listController,
            decoration: InputDecoration(labelText: 'checklist_list'.tr()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final category in widget.categories)
                DropdownMenuItem(value: category, child: Text(_categoryLabel(category))),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
            decoration: InputDecoration(labelText: 'common_category'.tr()),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _save,
              child: Text('common_save'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
