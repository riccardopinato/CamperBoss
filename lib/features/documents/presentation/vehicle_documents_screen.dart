import 'package:flutter/material.dart';

import '../../../core/services/document_scan_result.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../data/models/vehicle_document.dart';
import '../../../data/repositories/local_vehicle_document_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({
    this.repository,
    this.scannerService,
    super.key,
  });

  final VehicleDocumentRepository? repository;
  final DocumentScannerService? scannerService;

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  late final VehicleDocumentRepository _repository =
      widget.repository ?? LocalVehicleDocumentRepository();
  late final DocumentScannerService _scannerService =
      widget.scannerService ?? createDocumentScannerService();

  List<VehicleDocument> _documents = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String _query = '';
  String? _error;

  List<VehicleDocument> get _filteredDocuments {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _documents;
    return _documents.where((document) {
      return document.name.toLowerCase().contains(query) ||
          document.category.toLowerCase().contains(query) ||
          (document.notes ?? '').toLowerCase().contains(query);
    }).toList();
  }

  int get _expiringCount {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 45));
    return _documents.where((document) {
      final expiry = document.expiryDate;
      return expiry != null && expiry.isAfter(now) && expiry.isBefore(limit);
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documents = await _repository.listDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Document archive unavailable';
      });
    }
  }

  Future<void> _scanDocument() async {
    await _captureDocument(
      () => _scannerService.scan(pageLimit: 25, runOcr: true),
    );
  }

  Future<void> _importDocument() async {
    await _captureDocument(
      () => _scannerService.importLocalFile(runOcr: true),
    );
  }

  Future<void> _captureDocument(
    Future<DocumentScanResult?> Function() capture,
  ) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final result = await capture();
      if (!mounted || result == null || !result.hasFiles) return;

      final acceptedOcr = await _confirmOcr(result.ocrText);
      if (!mounted) return;
      await _openEditor(
        scanResult: DocumentScanResult(
          pagePaths: result.pagePaths,
          pdfPath: result.pdfPath,
          source: result.source,
          ocrText: acceptedOcr,
        ),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Document capture failed');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _confirmOcr(String? text) async {
    final extracted = text?.trim();
    if (extracted == null || extracted.isEmpty) return null;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use extracted text?'),
        content: SingleChildScrollView(
          child: Text(extracted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use text'),
          ),
        ],
      ),
    );

    return accepted == true ? extracted : null;
  }

  Future<void> _openEditor({
    VehicleDocument? document,
    DocumentScanResult? scanResult,
  }) async {
    final result = await showModalBottomSheet<VehicleDocument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VehicleDocumentEditor(
        document: document,
        scanResult: scanResult,
      ),
    );
    if (result == null) return;

    try {
      final saved = await _repository.saveDocument(result);
      if (!mounted) return;
      setState(() {
        if (document == null) {
          _documents = [saved, ..._documents];
        } else {
          _documents = [
            for (final existing in _documents)
              if (existing.id == saved.id) saved else existing,
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Document save failed');
    }
  }

  Future<void> _deleteDocument(VehicleDocument document) async {
    final id = document.id;
    if (id == null) return;

    final previous = _documents;
    setState(() {
      _documents = _documents.where((item) => item.id != id).toList();
    });

    try {
      await _repository.deleteDocument(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documents = previous;
        _error = 'Document delete failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;

    return ScreenScaffold(
      title: 'Vehicle documents',
      subtitle: 'Local private archive for scans, PDFs, deadlines, and notes.',
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
              icon: Icons.folder_copy_outlined,
              label: 'Saved',
              value: _documents.length.toString(),
              detail: 'Local only',
            ),
            MetricTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              value: _documents
                  .where((document) => document.pdfPath != null)
                  .length
                  .toString(),
              detail: 'Private files',
            ),
            MetricTile(
              icon: Icons.event_busy_outlined,
              label: 'Soon',
              value: _expiringCount.toString(),
              detail: '45 days',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _scanDocument,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(_isBusy ? 'Working...' : 'Scan'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              tooltip: 'Import file',
              onPressed: _isBusy ? null : _importDocument,
              icon: const Icon(Icons.upload_file_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search documents',
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
        const SectionHeader(title: 'Archive'),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filtered.isEmpty)
          const PremiumCard(child: Text('No documents saved yet'))
        else
          for (final document in filtered) ...[
            _VehicleDocumentCard(
              document: document,
              onEdit: () => _openEditor(document: document),
              onDelete: () => _deleteDocument(document),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _VehicleDocumentCard extends StatelessWidget {
  const _VehicleDocumentCard({
    required this.document,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleDocument document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(
              document.pdfPath == null
                  ? Icons.image_outlined
                  : Icons.picture_as_pdf_outlined,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    document.category,
                    '${document.pagePaths.length} pages',
                    document.source,
                  ].join(' - '),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (document.expiryDate != null)
                      'Expires ${_dateLabel(document.expiryDate!)}',
                    if (document.pdfPath != null) 'PDF saved',
                    if (document.ocrText != null) 'OCR confirmed',
                  ].join(' - '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit document',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete document',
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

class _VehicleDocumentEditor extends StatefulWidget {
  const _VehicleDocumentEditor({
    this.document,
    this.scanResult,
  });

  final VehicleDocument? document;
  final DocumentScanResult? scanResult;

  @override
  State<_VehicleDocumentEditor> createState() => _VehicleDocumentEditorState();
}

class _VehicleDocumentEditorState extends State<_VehicleDocumentEditor> {
  static const _categories = [
    'Registration',
    'Insurance',
    'Inspection',
    'Service',
    'Road tax',
    'Gas system',
    'Manual',
    'Invoice',
    'Other',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late String _category;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    _nameController = TextEditingController(text: document?.name ?? '');
    _notesController = TextEditingController(
      text: document?.notes ?? widget.scanResult?.ocrText ?? '',
    );
    _category = document?.category ?? _categories.first;
    _issueDate = document?.issueDate;
    _expiryDate = document?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool expiry}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (expiry ? _expiryDate : _issueDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    setState(() {
      if (expiry) {
        _expiryDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final document = widget.document;
    final scan = widget.scanResult;
    final notes = _notesController.text.trim();

    Navigator.of(context).pop(
      VehicleDocument(
        id: document?.id,
        category: _category,
        name: name,
        pagePaths: scan?.pagePaths ?? document?.pagePaths ?? const [],
        pdfPath: scan?.pdfPath ?? document?.pdfPath,
        source: scan?.source ?? document?.source ?? 'manual',
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        notes: notes.isEmpty ? null : notes,
        ocrText: scan?.ocrText ?? document?.ocrText,
        createdAt: document?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final scan = widget.scanResult;
    final pageCount = scan?.pagePaths.length ?? document?.pagePaths.length ?? 0;
    final hasPdf = scan?.pdfPath != null || document?.pdfPath != null;

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
              document == null ? 'Save document' : 'Edit document',
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
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(expiry: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateText(_issueDate, 'Issue date')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(expiry: true),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(_dateText(_expiryDate, 'Expiry')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            Text(
              [
                '$pageCount pages',
                if (hasPdf) 'PDF',
                if (scan?.ocrText != null) 'OCR confirmed',
              ].join(' - '),
              style: Theme.of(context).textTheme.bodySmall,
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

  String _dateText(DateTime? date, String fallback) {
    if (date == null) return fallback;
    return '${date.year}-${date.month}-${date.day}';
  }
}
