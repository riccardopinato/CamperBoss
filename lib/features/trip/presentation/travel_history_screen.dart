import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/travel_history_service.dart';
import '../../../data/models/route_preview.dart';
import '../../../data/models/travel_history_models.dart';
import '../../../data/models/trip_plan.dart';
import '../../../data/repositories/local_trip_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../map/presentation/map_marker_cluster_layer.dart';
import '../../map/presentation/map_marker_mapper.dart';

class TravelHistoryScreen extends StatefulWidget {
  const TravelHistoryScreen({
    this.initialTripId,
    this.tripRepository,
    this.historyService,
    super.key,
  });

  final int? initialTripId;
  final TripRepository? tripRepository;
  final TravelHistoryService? historyService;

  @override
  State<TravelHistoryScreen> createState() => _TravelHistoryScreenState();
}

class _TravelHistoryScreenState extends State<TravelHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TripRepository _tripRepository =
      widget.tripRepository ?? LocalTripRepository();
  late final TravelHistoryService _historyService =
      widget.historyService ?? TravelHistoryService();
  late final TabController _tabController =
      TabController(length: 4, vsync: this);
  final _mapController = MapController();
  final _markerMapper = const MapMarkerMapper();

  List<TripPlan> _trips = const [];
  List<GpxTrack> _tracks = const [];
  List<TravelMemory> _memories = const [];
  TravelHistoryStats? _stats;
  Set<String> _selectedMemoryIds = <String>{};
  int? _selectedTripId;
  String? _selectedTag;
  DateTime? _fromDate;
  DateTime? _toDate;
  TravelMemory? _selectedMemory;
  bool _isLoading = true;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final trips = await _tripRepository.listTrips();
      final selectedTripId = widget.initialTripId ??
          _selectedTripId ??
          (trips.isEmpty ? null : trips.first.id);
      final bundle = await _historyService.load(tripId: selectedTripId);
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _selectedTripId = selectedTripId;
        _tracks = bundle.tracks;
        _memories = bundle.memories;
        _stats = bundle.stats;
        _selectedMemoryIds.removeWhere(
          (id) => !_memories.any((memory) => memory.id == id),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Travel history unavailable';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTrip(int? tripId) async {
    setState(() => _selectedTripId = tripId);
    await _load();
  }

  Future<void> _importGpx() async {
    try {
      final bundle = await _historyService.importGpx(tripId: _selectedTripId);
      if (!mounted) return;
      setState(() {
        _tracks = bundle.tracks;
        _memories = bundle.memories;
        _stats = bundle.stats;
        _status = 'GPX imported locally';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _exportTrack(GpxTrack track) async {
    try {
      final path = await _historyService.exportTrack(
        track,
        memories: _filteredMemories
            .where((memory) => memory.tripId == track.tripId)
            .toList(growable: false),
      );
      if (!mounted) return;
      setState(() => _status = 'GPX exported to $path');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'GPX export failed');
    }
  }

  Future<void> _exportSelectedPhotos() async {
    final memories = _filteredMemories
        .where((memory) => _selectedMemoryIds.contains(memory.id))
        .toList(growable: false);
    if (memories.isEmpty) {
      setState(() => _error = 'Select at least one memory with photos');
      return;
    }
    try {
      final path = await _historyService.exportSelectedPhotos(memories);
      if (!mounted) return;
      setState(() => _status = 'Photo ZIP exported to $path');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Photo ZIP export failed');
    }
  }

  Future<void> _deleteTrack(GpxTrack track) async {
    await _historyService.deleteTrack(track);
    await _load();
  }

  Future<void> _deleteMemory(TravelMemory memory) async {
    await _historyService.deleteMemory(memory);
    await _load();
  }

  Future<void> _openMemoryEditor({TravelMemory? memory}) async {
    final saved = await showModalBottomSheet<TravelMemory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TravelMemoryEditor(
        initialTripId: _selectedTripId,
        memory: memory,
        historyService: _historyService,
      ),
    );
    if (saved == null) return;
    await _historyService.saveMemory(saved);
    await _load();
  }

  Set<String> get _availableTags {
    return {
      for (final memory in _memories) ...memory.tags,
    };
  }

  List<TravelMemory> get _filteredMemories {
    return _memories.where((memory) {
      if (_selectedTag != null && !memory.tags.contains(_selectedTag))
        return false;
      if (_fromDate != null && memory.occurredAt.isBefore(_fromDate!))
        return false;
      if (_toDate != null && memory.occurredAt.isAfter(_toDate!)) return false;
      return true;
    }).toList(growable: false);
  }

  List<_TimelineItem> get _timelineItems {
    final items = <_TimelineItem>[
      for (final track in _tracks)
        _TimelineItem(
          when: _firstRecordedAt(track) ??
              track.updatedAt ??
              track.createdAt ??
              DateTime.now(),
          title: track.name,
          subtitle:
              '${(track.distanceMeters / 1000).toStringAsFixed(1)} km GPX track',
          icon: Icons.alt_route_outlined,
        ),
      for (final memory in _filteredMemories)
        _TimelineItem(
          when: memory.occurredAt,
          title: memory.title,
          subtitle: memory.description ?? 'Geolocated memory',
          icon: Icons.photo_camera_outlined,
        ),
    ];
    items.sort((a, b) => b.when.compareTo(a.when));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ScreenScaffold(
      title: 'Travel history',
      subtitle: 'GPX, memories, visited places and trip statistics.',
      children: [
        if (_trips.isNotEmpty)
          DropdownButtonFormField<int?>(
            initialValue: _selectedTripId,
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('All trips')),
              ..._trips.map(
                (trip) => DropdownMenuItem<int?>(
                  value: trip.id,
                  child: Text(trip.title),
                ),
              ),
            ],
            onChanged: _selectTrip,
            decoration: const InputDecoration(labelText: 'Trip filter'),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _importGpx,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Import GPX'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openMemoryEditor(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add memory'),
            ),
            OutlinedButton.icon(
              onPressed:
                  _selectedMemoryIds.isEmpty ? null : _exportSelectedPhotos,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('ZIP selected photos'),
            ),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          PremiumCard(child: Text(_status!)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          PremiumCard(child: Text(_error!)),
        ],
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Map'),
            Tab(text: 'List'),
            Tab(text: 'Summary'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 780,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineTab(),
              _buildMapTab(context),
              _buildListTab(),
              _buildSummaryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    if (_timelineItems.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No travel history yet',
        message: 'Import a GPX or create a memory to start the timeline.',
      );
    }
    return ListView.separated(
      itemCount: _timelineItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _timelineItems[index];
        return PremiumCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Icon(item.icon)),
            title: Text(item.title),
            subtitle: Text(
              '${_date(item.when)} - ${item.subtitle}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTab(BuildContext context) {
    final allPoints = [
      for (final track in _tracks) ...track.points,
    ];
    final center = allPoints.isEmpty
        ? const LatLng(45.4642, 9.19)
        : LatLng(
            allPoints.last.latitude,
            allPoints.last.longitude,
          );
    final selectedMemory = _selectedMemory != null &&
            _filteredMemories.any((memory) => memory.id == _selectedMemory!.id)
        ? _selectedMemory
        : null;
    final memoryMarkers = [
      for (final memory in _filteredMemories)
        if (selectedMemory == null || memory.id != selectedMemory.id)
          _markerMapper.buildPersonalMarker(
            PersonalMapMarker(
              id: memory.id,
              latitude: memory.latitude,
              longitude: memory.longitude,
              icon: Icons.photo_camera_outlined,
            ),
            onTap: () => setState(() => _selectedMemory = memory),
          ),
    ];

    final plannedStops = _selectedTripId == null
        ? const <RouteWaypoint>[]
        : parseRouteWaypoints(
            _selectedTripStages(),
          );

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _availableTags)
                FilterChip(
                  label: Text(tag),
                  selected: _selectedTag == tag,
                  onSelected: (_) {
                    setState(
                        () => _selectedTag = _selectedTag == tag ? null : tag);
                  },
                ),
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(start: true),
                icon: const Icon(Icons.event_outlined),
                label: Text(_fromDate == null ? 'From' : _date(_fromDate!)),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(start: false),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_toDate == null ? 'To' : _date(_toDate!)),
              ),
              IconButton.outlined(
                tooltip: 'Clear filters',
                onPressed: () {
                  setState(() {
                    _selectedTag = null;
                    _fromDate = null;
                    _toDate = null;
                  });
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 6),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.camperboss.camperboss',
                    ),
                    for (final track in _tracks)
                      if (track.points.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                for (final point in track.points)
                                  LatLng(point.latitude, point.longitude),
                              ],
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                    if (memoryMarkers.isNotEmpty)
                      MapMarkerClusterLayer(markers: memoryMarkers),
                    MarkerLayer(
                      markers: [
                        for (final stop in plannedStops)
                          Marker(
                            point: stop.point,
                            width: 38,
                            height: 38,
                            child: const Icon(Icons.flag_circle_outlined),
                          ),
                        if (selectedMemory != null)
                          _markerMapper.buildPersonalMarker(
                            PersonalMapMarker(
                              id: selectedMemory.id,
                              latitude: selectedMemory.latitude,
                              longitude: selectedMemory.longitude,
                              icon: Icons.photo_camera,
                            ),
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ),
                if (selectedMemory != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedMemory.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (selectedMemory.description != null) ...[
                            const SizedBox(height: 6),
                            Text(selectedMemory.description!),
                          ],
                          const SizedBox(height: 8),
                          Text(_date(selectedMemory.occurredAt)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTab() {
    return ListView(
      children: [
        const SectionHeader(title: 'Tracks'),
        const SizedBox(height: 8),
        if (_tracks.isEmpty)
          const PremiumCard(child: Text('No imported GPX tracks'))
        else
          for (final track in _tracks) ...[
            PremiumCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                          '${(track.distanceMeters / 1000).toStringAsFixed(1)} km'
                          '${track.duration == null ? '' : ' - ${_duration(track.duration!)}'}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Export GPX',
                    onPressed: () => _exportTrack(track),
                    icon: const Icon(Icons.download_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete track',
                    onPressed: () => _deleteTrack(track),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        const SectionHeader(title: 'Memories'),
        const SizedBox(height: 8),
        if (_filteredMemories.isEmpty)
          const PremiumCard(child: Text('No memories for the current filters'))
        else
          for (final memory in _filteredMemories) ...[
            PremiumCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _selectedMemoryIds.contains(memory.id),
                    onChanged: (_) {
                      setState(() {
                        if (!_selectedMemoryIds.add(memory.id)) {
                          _selectedMemoryIds.remove(memory.id);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMemory = memory),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memory.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            memory.description ?? 'Geolocated memory',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_date(memory.occurredAt)} - '
                            '${memory.latitude.toStringAsFixed(4)}, '
                            '${memory.longitude.toStringAsFixed(4)}',
                          ),
                          if (memory.localPhotoPaths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _MemoryPreview(memory: memory),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit memory',
                    onPressed: () => _openMemoryEditor(memory: memory),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete memory',
                    onPressed: () => _deleteMemory(memory),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildSummaryTab() {
    final stats = _stats;
    if (stats == null) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'No statistics yet',
        message: 'Import a track or save memories linked to a trip.',
      );
    }
    return ListView(
      children: [
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              icon: Icons.alt_route_outlined,
              label: 'Distance',
              value: '${(stats.distanceMeters / 1000).toStringAsFixed(1)} km',
              detail: '${stats.trackDays} days',
            ),
            MetricTile(
              icon: Icons.place_outlined,
              label: 'Places',
              value: stats.placeCount.toString(),
              detail: 'Visited',
            ),
            MetricTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Costs',
              value: 'EUR ${(stats.totalCostMinor / 100).toStringAsFixed(0)}',
              detail: 'Linked to trip',
            ),
            MetricTile(
              icon: Icons.local_gas_station_outlined,
              label: 'Fuel',
              value: '${stats.totalFuelLiters.toStringAsFixed(1)} L',
              detail: stats.consumptionLitersPer100Km == null
                  ? 'No consumption yet'
                  : '${stats.consumptionLitersPer100Km!.toStringAsFixed(1)} L/100km',
            ),
          ],
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Derived statistics',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                  'Duration: ${stats.duration == null ? 'N/A' : _duration(stats.duration!)}'),
              Text(
                'Elevation gain: ${stats.elevationGainMeters == null ? 'N/A' : '${stats.elevationGainMeters!.toStringAsFixed(0)} m'}',
              ),
              Text(
                'Average speed: ${stats.averageSpeedKmh == null ? 'N/A' : '${stats.averageSpeedKmh!.toStringAsFixed(1)} km/h'}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange({required bool start}) async {
    final current = start ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _fromDate = picked;
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  String _date(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '${value.inMinutes} min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }

  DateTime? _firstRecordedAt(GpxTrack track) {
    for (final point in track.points) {
      if (point.recordedAt != null) return point.recordedAt;
    }
    return null;
  }

  List<String> _selectedTripStages() {
    for (final trip in _trips) {
      if (trip.id == _selectedTripId) return trip.stages;
    }
    return const [];
  }
}

class _TravelMemoryEditor extends StatefulWidget {
  const _TravelMemoryEditor({
    required this.initialTripId,
    required this.historyService,
    this.memory,
  });

  final int? initialTripId;
  final TravelMemory? memory;
  final TravelHistoryService historyService;

  @override
  State<_TravelMemoryEditor> createState() => _TravelMemoryEditorState();
}

class _TravelMemoryEditorState extends State<_TravelMemoryEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _tagsController;
  late DateTime _occurredAt;
  late bool _favorite;
  List<String> _photoPaths = const [];
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    final memory = widget.memory;
    _titleController = TextEditingController(text: memory?.title ?? '');
    _descriptionController =
        TextEditingController(text: memory?.description ?? '');
    _latitudeController = TextEditingController(
      text: memory?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: memory?.longitude.toString() ?? '',
    );
    _tagsController =
        TextEditingController(text: memory?.tags.join(', ') ?? '');
    _occurredAt = memory?.occurredAt ?? DateTime.now();
    _favorite = memory?.favorite ?? false;
    _photoPaths = memory?.localPhotoPaths ?? const [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _importPhoto() async {
    try {
      final candidate = await widget.historyService.importPhoto();
      if (candidate == null) return;
      if (!mounted) return;
      var latitude = _latitudeController.text;
      var longitude = _longitudeController.text;
      var occurredAt = _occurredAt;
      if (candidate.hasCoordinates || candidate.recordedAt != null) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Use photo metadata?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (candidate.previewBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(candidate.previewBytes!),
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (candidate.hasCoordinates)
                  Text(
                    'Coordinates: ${candidate.latitude!.toStringAsFixed(5)}, ${candidate.longitude!.toStringAsFixed(5)}',
                  ),
                if (candidate.recordedAt != null)
                  Text('Date: ${candidate.recordedAt!.toIso8601String()}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep manual fields'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Use metadata'),
              ),
            ],
          ),
        );
        if (accepted == true) {
          if (candidate.latitude != null) {
            latitude = candidate.latitude!.toStringAsFixed(6);
          }
          if (candidate.longitude != null) {
            longitude = candidate.longitude!.toStringAsFixed(6);
          }
          if (candidate.recordedAt != null) {
            occurredAt = candidate.recordedAt!;
          }
        }
      }
      setState(() {
        _photoPaths = [..._photoPaths, candidate.path];
        _previewBytes = candidate.previewBytes == null
            ? null
            : Uint8List.fromList(candidate.previewBytes!);
        _latitudeController.text = latitude;
        _longitudeController.text = longitude;
        _occurredAt = occurredAt;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _save() {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (_titleController.text.trim().isEmpty ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return;
    }

    Navigator.of(context).pop(
      TravelMemory(
        id: widget.memory?.id ??
            'memory-${DateTime.now().microsecondsSinceEpoch}',
        tripId: widget.memory?.tripId ?? widget.initialTripId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        occurredAt: _occurredAt,
        localPhotoPaths: _photoPaths,
        tags: _tagsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet(),
        favorite: _favorite,
        createdAt: widget.memory?.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.memory == null ? 'Add memory' : 'Edit memory',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      '${_occurredAt.year}-${_occurredAt.month.toString().padLeft(2, '0')}-${_occurredAt.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Import photo'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _favorite,
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorite'),
              onChanged: (value) => setState(() => _favorite = value),
            ),
            if (_previewBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _previewBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
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

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({required this.memory});

  final TravelMemory memory;

  @override
  Widget build(BuildContext context) {
    if (memory.localPhotoPaths.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.photo_library_outlined, size: 18),
        const SizedBox(width: 6),
        Text('${memory.localPhotoPaths.length} photo(s)'),
      ],
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.when,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final DateTime when;
  final String title;
  final String subtitle;
  final IconData icon;
}
