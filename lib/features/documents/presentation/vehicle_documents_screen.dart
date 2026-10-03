import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/document_capture_service.dart';
import '../../../core/services/document_deletion_service.dart';
import '../../../core/services/document_ocr_service.dart';
import '../../../core/services/document_services_models.dart';
import '../../../core/services/document_storage_service.dart';
import '../../../core/services/app_system_services.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../data/models/vehicle_document.dart';
import '../../../data/repositories/local_vehicle_document_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({
    this.repository,
    this.captureService,
    this.ocrService,
    this.reminderService,
    this.deletionService,
    this.initialDocumentId,
    super.key,
  });

  final VehicleDocumentRepository? repository;
  final DocumentCaptureService? captureService;
  final DocumentOcrService? ocrService;
  final ReminderSyncService? reminderService;
  final DocumentDeletionService? deletionService;
  final int? initialDocumentId;

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  late final VehicleDocumentRepository _repository =
      widget.repository ?? LocalVehicleDocumentRepository();
  late final DocumentCaptureService _captureService =
      widget.captureService ?? createDocumentCaptureService();
  late final DocumentOcrService _ocrService =
      widget.ocrService ?? createDocumentOcrService();
  late final DocumentStorageService _storageService =
      createDocumentStorageService();
  late final ReminderSyncService _reminderService =
      widget.reminderService ?? AppSystemServices.instance.reminders;
  late final DocumentDeletionService _deletionService =
      widget.deletionService ??
          DocumentDeletionService(documentRepository: _repository);

  List<VehicleDocument> _documents = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String _query = '';
  String? _error;

  List<VehicleDocument> get _filteredDocuments {
    return _documents.where((document) => document.matches(_query)).toList();
  }

  int get _expiredCount {
    final now = DateTime.now();
    return _documents.where((document) {
      final expiry = document.expiryDate;
      return expiry != null && !expiry.isAfter(now);
    }).length;
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
      final targetId = widget.initialDocumentId;
      if (targetId != null) {
        documents.sort((a, b) {
          if (a.id == targetId) return -1;
          if (b.id == targetId) return 1;
          return 0;
        });
      }
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'document_error_archive_unavailable'.tr();
      });
    }
  }

  Future<void> _showCaptureMenu() async {
    final action = await showModalBottomSheet<_CaptureAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_captureService.canScanDocuments)
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text('document_action_scan'.tr()),
                onTap: () => Navigator.of(context).pop(_CaptureAction.scan),
              )
            else
              ListTile(
                enabled: false,
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text('document_action_scan'.tr()),
                subtitle: Text('document_scan_unavailable'.tr()),
              ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text('document_action_import_images'.tr()),
              onTap: () => Navigator.of(context).pop(_CaptureAction.images),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text('document_action_import_pdf'.tr()),
              onTap: () => Navigator.of(context).pop(_CaptureAction.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text('cancel'.tr()),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;

    switch (action) {
      case _CaptureAction.scan:
        await _captureDocument(_captureService.scanDocument);
      case _CaptureAction.images:
        await _captureDocument(_captureService.importImages);
      case _CaptureAction.pdf:
        await _captureDocument(_captureService.importPdf);
    }
  }

  Future<void> _captureDocument(
    Future<DocumentCaptureResult?> Function() capture,
  ) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final captureResult = await capture();
      if (!mounted || captureResult == null) return;

      final ocrResult = await _runOcr(captureResult.imagePaths);
      if (!mounted) return;
      final saved = await _openEditor(
        captureResult: captureResult,
        ocrResult: ocrResult,
      );
      if (!saved) {
        await _storageService.deleteFiles(captureResult.filePaths);
      }
    } on UnsupportedError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'document_error_capture_failed'.tr());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<OcrResult> _runOcr(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return const OcrResult(
        status: DocumentOcrStatus.notAvailable,
        language: 'latin',
      );
    }
    if (!_ocrService.isSupported) {
      return const OcrResult(
        status: DocumentOcrStatus.notAvailable,
        language: 'latin',
      );
    }
    return _ocrService.recognizeImages(imagePaths);
  }

  Future<void> _retryOcr(VehicleDocument document) async {
    setState(() {
      _isBusy = true;
      _error = null;
      _documents = [
        for (final current in _documents)
          if (current.id == document.id)
            current.copyWith(ocrStatus: DocumentOcrStatus.processing)
          else
            current,
      ];
    });

    try {
      final ocrResult = await _runOcr(document.pagePaths);
      final saved = await _repository.saveDocument(
        document.copyWith(
          extractedText: ocrResult.text,
          ocrLanguage: ocrResult.language,
          ocrStatus: ocrResult.status,
          processingError: ocrResult.error,
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _documents = [
          for (final current in _documents)
            if (current.id == saved.id) saved else current,
        ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'document_error_ocr_failed'.tr());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool> _openEditor({
    VehicleDocument? document,
    DocumentCaptureResult? captureResult,
    OcrResult? ocrResult,
  }) async {
    final result = await showModalBottomSheet<VehicleDocument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VehicleDocumentEditor(
        document: document,
        captureResult: captureResult,
        ocrResult: ocrResult,
      ),
    );
    if (result == null) return false;

    try {
      final saved = await _repository.saveDocument(result);
      await _reminderService.syncDocument(saved);
      if (!mounted) return false;
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
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _error = 'document_error_save_failed'.tr());
      return false;
    }
  }

  Future<void> _deleteDocument(VehicleDocument document) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('documents_delete_confirm_title'.tr()),
            content: Text(
              'documents_delete_confirm_body'.tr(
                namedArgs: {'title': document.title},
              ),
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

    final previous = _documents;
    setState(() {
      _documents = _documents.where((item) => item.id != document.id).toList();
    });

    try {
      await _deletionService.deleteDocument(document);
      if (document.id != null) {
        await _reminderService.deleteDocumentReminders(document.id.toString());
      }
    } on DocumentInUseException catch (error) {
      if (!mounted) return;
      setState(() {
        _documents = previous;
        _error = 'document_error_in_use'.tr(
          namedArgs: {'count': error.referenceCount.toString()},
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documents = previous;
        _error = 'document_error_delete_failed'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;

    return ScreenScaffold(
      title: 'documents_title'.tr(),
      subtitle: 'documents_subtitle'.tr(),
      children: [
        GridView.extent(
          maxCrossAxisExtent: 190,
          childAspectRatio: 0.92,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              icon: Icons.folder_copy_outlined,
              label: 'documents_metric_saved'.tr(),
              value: _documents.length.toString(),
              detail: 'documents_metric_local'.tr(),
            ),
            MetricTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'documents_metric_pdf'.tr(),
              value: _documents
                  .where((document) => document.mimeType == 'application/pdf')
                  .length
                  .toString(),
              detail: 'documents_metric_private'.tr(),
            ),
            MetricTile(
              icon: Icons.error_outline,
              label: 'documents_metric_expired'.tr(),
              value: _expiredCount.toString(),
              detail: 'documents_metric_expired_detail'.tr(),
            ),
            MetricTile(
              icon: Icons.event_busy_outlined,
              label: 'documents_metric_soon'.tr(),
              value: _expiringCount.toString(),
              detail: 'documents_metric_45_days'.tr(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isBusy ? null : _showCaptureMenu,
          icon: const Icon(Icons.add),
          label: Text(_isBusy ? 'documents_working'.tr() : 'document_add'.tr()),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'documents_search'.tr(),
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
        SectionHeader(title: 'documents_archive'.tr()),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filtered.isEmpty)
          PremiumCard(child: Text('documents_empty'.tr()))
        else
          for (final document in filtered) ...[
            _VehicleDocumentCard(
              document: document,
              onEdit: () { _openEditor(document: document); },
              onDelete: () => _deleteDocument(document),
              onRetryOcr: () => _retryOcr(document),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

enum _CaptureAction { scan, images, pdf }

class _VehicleDocumentCard extends StatelessWidget {
  const _VehicleDocumentCard({
    required this.document,
    required this.onEdit,
    required this.onDelete,
    required this.onRetryOcr,
  });

  final VehicleDocument document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRetryOcr;

  bool get _isExpired {
    final expiry = document.expiryDate;
    return expiry != null && !expiry.isAfter(DateTime.now());
  }

  bool get _isExpiring {
    final expiry = document.expiryDate;
    if (expiry == null) return false;
    final now = DateTime.now();
    return expiry.isAfter(now) &&
        expiry.isBefore(now.add(const Duration(days: 45)));
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(
              document.mimeType == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (_isExpired)
                      Icon(
                        Icons.error_outline,
                        size: 19,
                        color: Theme.of(context).colorScheme.error,
                      )
                    else if (_isExpiring)
                      const Icon(Icons.warning_amber_outlined, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    document.category.tr(),
                    '${document.pageCount} ${'documents_pages'.tr()}',
                    _ocrLabel(document.ocrStatus),
                  ].join(' - '),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (document.expiryDate != null)
                      '${'documents_expiry'.tr()} ${_dateLabel(document.expiryDate!)}',
                    if (document.thumbnailPath != null)
                      'documents_thumbnail_ready'.tr(),
                    if (document.processingError != null)
                      'documents_ocr_retry_available'.tr(),
                  ].join(' - '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (document.ocrStatus == DocumentOcrStatus.failed) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRetryOcr,
                    icon: const Icon(Icons.refresh),
                    label: Text('documents_retry_ocr'.tr()),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'documents_edit'.tr(),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'documents_delete'.tr(),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  static String _ocrLabel(DocumentOcrStatus status) {
    return switch (status) {
      DocumentOcrStatus.notRequested => 'ocr_not_requested'.tr(),
      DocumentOcrStatus.processing => 'ocr_processing'.tr(),
      DocumentOcrStatus.ready => 'ocr_ready'.tr(),
      DocumentOcrStatus.failed => 'ocr_failed'.tr(),
      DocumentOcrStatus.notAvailable => 'ocr_not_available'.tr(),
    };
  }

  static String _dateLabel(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class _VehicleDocumentEditor extends StatefulWidget {
  const _VehicleDocumentEditor({
    this.document,
    this.captureResult,
    this.ocrResult,
  });

  final VehicleDocument? document;
  final DocumentCaptureResult? captureResult;
  final OcrResult? ocrResult;

  @override
  State<_VehicleDocumentEditor> createState() => _VehicleDocumentEditorState();
}

class _VehicleDocumentEditorState extends State<_VehicleDocumentEditor> {
  static const _categories = [
    'document_category_registration',
    'document_category_insurance',
    'document_category_inspection',
    'document_category_service',
    'document_category_road_tax',
    'document_category_gas_system',
    'document_category_manual',
    'document_category_invoice',
    'document_category_other',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late String _category;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _notesController = TextEditingController(text: document?.notes ?? '');
    _category = document?.category ?? _categories.first;
    _issueDate = document?.issueDate;
    _expiryDate = document?.expiryDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final document = widget.document;
    final capture = widget.captureResult;
    final ocr = widget.ocrResult;
    final notes = _notesController.text.trim();
    final primaryPath = capture?.primaryFilePath ?? document?.localFilePath;
    if (primaryPath == null || primaryPath.isEmpty) return;
    final isPdf =
        capture?.pdfPath != null || document?.mimeType == 'application/pdf';

    Navigator.of(context).pop(
      VehicleDocument(
        id: document?.id,
        vehicleId: document?.vehicleId,
        category: _category,
        title: title,
        localFilePath: primaryPath,
        thumbnailPath: capture?.thumbnailPath ?? document?.thumbnailPath,
        pagePaths: capture?.imagePaths ?? document?.pagePaths ?? const [],
        pdfPath: capture?.pdfPath ?? document?.pdfPath,
        mimeType: capture?.mimeType ??
            document?.mimeType ??
            (isPdf ? 'application/pdf' : 'image/jpeg'),
        pageCount: capture?.pageCount ?? document?.pageCount ?? 1,
        fileSize: capture?.fileSize ?? document?.fileSize,
        extractedText: ocr?.text ?? document?.extractedText,
        ocrLanguage: ocr?.language ?? document?.ocrLanguage,
        ocrStatus: ocr?.status ??
            document?.ocrStatus ??
            (isPdf
                ? DocumentOcrStatus.notAvailable
                : DocumentOcrStatus.notRequested),
        processingError: ocr?.error ?? document?.processingError,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        notes: notes.isEmpty ? null : notes,
        createdAt: document?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final capture = widget.captureResult;
    final pageCount = capture?.pageCount ?? document?.pageCount ?? 0;
    final ocrStatus = widget.ocrResult?.status ?? document?.ocrStatus;

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
              document == null ? 'document_save'.tr() : 'document_edit'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category.tr())),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: InputDecoration(labelText: 'documents_category'.tr()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration:
                  InputDecoration(labelText: 'documents_title_field'.tr()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(expiry: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateText(_issueDate, 'documents_issue_date')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(expiry: true),
                    icon: const Icon(Icons.event_available_outlined),
                    label:
                        Text(_dateText(_expiryDate, 'documents_expiry_date')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: 'documents_notes'.tr()),
            ),
            const SizedBox(height: 12),
            Text(
              [
                '$pageCount ${'documents_pages'.tr()}',
                if (ocrStatus != null)
                  _VehicleDocumentCard._ocrLabel(ocrStatus),
              ].join(' - '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                child: Text('save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateText(DateTime? date, String fallbackKey) {
    if (date == null) return fallbackKey.tr();
    return '${date.year}-${date.month}-${date.day}';
  }
}
