import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/services/app_system_services.dart';
import '../../../core/services/offline_guides_service.dart';
import '../../../data/models/guide_models.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class OfflineGuidesScreen extends StatefulWidget {
  const OfflineGuidesScreen({
    this.guidesService,
    this.initialSourceId,
    super.key,
  });

  final OfflineGuidesService? guidesService;
  final String? initialSourceId;

  @override
  State<OfflineGuidesScreen> createState() => _OfflineGuidesScreenState();
}

class _OfflineGuidesScreenState extends State<OfflineGuidesScreen> {
  late final OfflineGuidesService _guidesService =
      widget.guidesService ?? AppSystemServices.instance.guides;
  final _searchController = TextEditingController();

  List<GuidePackage> _packages = const [];
  List<GuideEntrySearchResult> _results = const [];
  Set<String> _favorites = const {};
  bool _isInstalling = false;
  bool _isLoading = true;
  String? _error;
  bool _openedInitialSource = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final packages = await _guidesService.listInstalledPackages();
      final favorites = await _guidesService.loadFavorites();
      final results = await _guidesService.search(_searchController.text);
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _favorites = favorites;
        _results = results;
        _isLoading = false;
      });
      _openInitialSourceIfNeeded();
    } catch (error, stackTrace) {
      debugPrint('Offline guides load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'offline_guides_error'.tr();
        _isLoading = false;
      });
    }
  }

  void _openInitialSourceIfNeeded() {
    if (_openedInitialSource) return;
    final source = widget.initialSourceId;
    if (source == null || source.isEmpty) return;

    final separator = source.indexOf(':');
    if (separator <= 0 || separator >= source.length - 1) return;
    final packageId = source.substring(0, separator);
    final entryId = source.substring(separator + 1);
    _openedInitialSource = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openDocument(packageId, entryId);
    });
  }

  Future<void> _installEssential() async {
    setState(() => _isInstalling = true);
    try {
      await _guidesService.installBundledPackage();
      await _load();
    } catch (error, stackTrace) {
      debugPrint('Offline guide install failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = 'offline_guides_error'.tr());
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }

  Future<void> _toggleFavorite(String entryId) async {
    await _guidesService.toggleFavorite(entryId);
    await _load();
  }

  Future<void> _openDocument(String packageId, String entryId) async {
    final document = await _guidesService.loadDocument(packageId, entryId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GuideReaderScreen(
          document: document,
          guidesService: _guidesService,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(String _) async {
    final results = await _guidesService.search(_searchController.text);
    if (!mounted) return;
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'offline_guides_title'.tr(),
      subtitle: 'offline_guides_subtitle'.tr(),
      children: [
        PremiumCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CamperBoss Essential',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text('offline_guides_essential_body'.tr()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isInstalling ? null : _installEssential,
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  _isInstalling
                      ? 'offline_guides_installing'.tr()
                      : 'offline_guides_install'.tr(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'offline_guides_search'.tr(),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          PremiumCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          SectionHeader(title: 'offline_guides_installed'.tr()),
          const SizedBox(height: 12),
          if (_packages.isEmpty)
            PremiumCard(
              child: Text('offline_guides_empty'.tr()),
            )
          else
            for (final package in _packages) ...[
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${package.category} - ${package.language.toUpperCase()} - ${package.version}',
                    ),
                    const SizedBox(height: 8),
                    Text(package.attribution),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          SectionHeader(title: 'offline_guides_index'.tr()),
          const SizedBox(height: 12),
          for (final result in _results) ...[
            PremiumCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(result.entry.title),
                subtitle: Text(
                  '${result.packageTitle}${result.entry.summary == null ? '' : ' - ${result.entry.summary!}'}',
                ),
                leading: Icon(_iconFor(result.entry.contentType)),
                trailing: IconButton(
                  tooltip: 'offline_guides_favorite'.tr(),
                  onPressed: () => _toggleFavorite(result.entry.id),
                  icon: Icon(
                    _favorites.contains(result.entry.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
                onTap: () => _openDocument(result.packageId, result.entry.id),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  IconData _iconFor(GuideContentType type) {
    return switch (type) {
      GuideContentType.markdown => Icons.description_outlined,
      GuideContentType.html => Icons.language_outlined,
      GuideContentType.pdf => Icons.picture_as_pdf_outlined,
      GuideContentType.json => Icons.data_object_outlined,
    };
  }
}

class _GuideReaderScreen extends StatefulWidget {
  const _GuideReaderScreen({
    required this.document,
    required this.guidesService,
  });

  final GuideDocument document;
  final OfflineGuidesService guidesService;

  @override
  State<_GuideReaderScreen> createState() => _GuideReaderScreenState();
}

class _GuideReaderScreenState extends State<_GuideReaderScreen> {
  final _controller = ScrollController();
  GuideReadingProgress? _progress;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _saveProgress();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final progress = await widget.guidesService.loadReadingProgress(
      widget.document.entryId,
    );
    if (!mounted || progress == null) return;
    _progress = progress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(progress.offset.toDouble());
      }
    });
  }

  Future<void> _saveProgress() async {
    if (!_controller.hasClients) return;
    await widget.guidesService.saveReadingProgress(
      GuideReadingProgress(
        entryId: widget.document.entryId,
        offset: _controller.offset.round(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _openPdf() async {
    final path = widget.document.localPath;
    if (path == null) return;
    await launchUrl(Uri.file(path));
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    return ScreenScaffold(
      title: document.title,
      subtitle: document.attribution,
      children: [
        if (_progress != null) ...[
          Text(
            'offline_guides_last_position'.tr(
              namedArgs: {
                'date': localizedDateTime(
                  _progress!.updatedAt.toLocal(),
                  locale: context.locale.toLanguageTag(),
                ),
              },
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        if (document.contentType == GuideContentType.pdf)
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('offline_guides_pdf_safety'.tr()),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openPdf,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('offline_guides_open_pdf'.tr()),
                ),
              ],
            ),
          )
        else
          PremiumCard(
            child: SingleChildScrollView(
              controller: _controller,
              child: _GuideBody(document: document),
            ),
          ),
      ],
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.document});

  final GuideDocument document;

  @override
  Widget build(BuildContext context) {
    return switch (document.contentType) {
      GuideContentType.markdown => _MarkdownBody(content: document.content),
      GuideContentType.html => SelectableText(_htmlToText(document.content)),
      GuideContentType.json => SelectableText(document.content),
      GuideContentType.pdf => const SizedBox.shrink(),
    };
  }

  String _htmlToText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          if (line.startsWith('# '))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line.substring(2),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            )
          else if (line.startsWith('## '))
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                line.substring(3),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            )
          else if (line.startsWith('- '))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${line.substring(2)}'),
            )
          else if (RegExp(r'^\d+\.\s').hasMatch(line))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            )
          else if (line.trim().isEmpty)
            const SizedBox(height: 8)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
        ],
      ],
    );
  }
}
