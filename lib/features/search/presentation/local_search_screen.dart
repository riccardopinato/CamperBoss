import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/local_search_provider.dart';
import '../../../core/services/local_search_service.dart';
import '../../../data/models/search_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../documents/presentation/vehicle_documents_screen.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../maintenance/presentation/maintenance_screen.dart';
import '../../offline/presentation/offline_guides_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../trip/presentation/trip_planner_screen.dart';

class LocalSearchScreen extends ConsumerStatefulWidget {
  const LocalSearchScreen({
    this.searchService,
    this.onOpenHit,
    super.key,
  });

  final LocalSearchIndex? searchService;
  final ValueChanged<SearchHit>? onOpenHit;

  @override
  ConsumerState<LocalSearchScreen> createState() => _LocalSearchScreenState();
}

class _LocalSearchScreenState extends ConsumerState<LocalSearchScreen> {
  final _controller = TextEditingController();
  final _selectedTypes = <SearchDocumentType>{};

  late LocalSearchIndex _searchService;
  SearchIndexSnapshot? _snapshot;
  List<SearchHit> _hits = const [];
  bool _isLoading = true;
  bool _isRebuilding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchService =
          widget.searchService ?? ref.read(localSearchServiceProvider);
      _load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await _searchService.snapshot();
      if (snapshot.status == SearchIndexStatus.empty) {
        await _rebuild(silent: true);
      } else {
        await _search();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Search index unavailable';
        _isLoading = false;
      });
    }
  }

  Future<void> _search() async {
    if (!mounted) return;
    try {
      final snapshot = await _searchService.snapshot();
      final hits = await _searchService.search(
        _controller.text,
        types: _selectedTypes.isEmpty ? null : _selectedTypes,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _hits = hits;
        _error = snapshot.status == SearchIndexStatus.corrupted
            ? snapshot.lastError ?? 'Search index corrupted'
            : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _rebuild({bool silent = false}) async {
    if (!silent) setState(() => _isRebuilding = true);
    try {
      await _searchService.rebuild();
      await _search();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Index rebuild failed');
    } finally {
      if (mounted) setState(() => _isRebuilding = false);
    }
  }

  void _toggleType(SearchDocumentType type) {
    setState(() {
      if (!_selectedTypes.add(type)) _selectedTypes.remove(type);
    });
    _search();
  }

  void _openHit(SearchHit hit) {
    final callback = widget.onOpenHit;
    if (callback != null) {
      callback(hit);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _screenFor(hit.type)),
    );
  }

  Widget _screenFor(SearchDocumentType type) {
    return switch (type) {
      SearchDocumentType.vehicleDocument => const VehicleDocumentsScreen(),
      SearchDocumentType.maintenance => const MaintenanceScreen(),
      SearchDocumentType.journal => const JournalScreen(),
      SearchDocumentType.trip => const TripPlannerScreen(),
      SearchDocumentType.booking => const FinanceScreen(),
      SearchDocumentType.offlineGuide => const OfflineGuidesScreen(),
      SearchDocumentType.vehicleNote => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final snapshot = _snapshot;
    return ScreenScaffold(
      title: 'Search',
      subtitle: 'Private local search across documents, trips and guides.',
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'Search CamperBoss',
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _controller.clear();
                      _search();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in SearchDocumentType.values)
              FilterChip(
                selected: _selectedTypes.contains(type),
                label: Text(_labelFor(type)),
                onSelected: (_) => _toggleType(type),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  snapshot == null
                      ? 'Index status unavailable'
                      : '${snapshot.documentCount} local items - ${snapshot.status.name}',
                ),
              ),
              IconButton(
                tooltip: 'Rebuild index',
                onPressed: _isRebuilding ? null : _rebuild,
                icon: _isRebuilding
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          PremiumCard(child: Text(_error!)),
        ],
        const SizedBox(height: 16),
        SectionHeader(title: 'Results', action: '${_hits.length}'),
        const SizedBox(height: 8),
        if (_hits.isEmpty)
          const EmptyState(
            icon: Icons.manage_search,
            title: 'No local results',
            message: 'Try another term or rebuild the private local index.',
          )
        else
          for (final hit in _groupedHits()) ...[
            _SearchHitCard(hit: hit, onTap: () => _openHit(hit)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  List<SearchHit> _groupedHits() {
    return [..._hits]..sort((a, b) {
        final type = a.type.index.compareTo(b.type.index);
        if (type != 0) return type;
        return b.score.compareTo(a.score);
      });
  }

  String _labelFor(SearchDocumentType type) {
    return switch (type) {
      SearchDocumentType.vehicleDocument => 'Documents',
      SearchDocumentType.maintenance => 'Service',
      SearchDocumentType.journal => 'Journal',
      SearchDocumentType.trip => 'Trips',
      SearchDocumentType.booking => 'Bookings',
      SearchDocumentType.offlineGuide => 'Guides',
      SearchDocumentType.vehicleNote => 'Vehicle',
    };
  }
}

class _SearchHitCard extends StatelessWidget {
  const _SearchHitCard({
    required this.hit,
    required this.onTap,
  });

  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(_iconFor(hit.type))),
          title: Text(
            hit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            hit.snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _iconFor(SearchDocumentType type) {
    return switch (type) {
      SearchDocumentType.vehicleDocument => Icons.folder_copy_outlined,
      SearchDocumentType.maintenance => Icons.build_circle_outlined,
      SearchDocumentType.journal => Icons.auto_stories_outlined,
      SearchDocumentType.trip => Icons.route_outlined,
      SearchDocumentType.booking => Icons.event_available_outlined,
      SearchDocumentType.offlineGuide => Icons.menu_book_outlined,
      SearchDocumentType.vehicleNote => Icons.directions_car_outlined,
    };
  }
}
