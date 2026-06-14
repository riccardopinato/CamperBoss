import 'package:flutter/material.dart';

import '../../../data/models/trip_plan.dart';
import '../../../data/repositories/local_trip_repository.dart';
import '../../../data/repositories/mock_camper_repository.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/resource_bar.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/trip_card.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({
    this.repository,
    super.key,
  });

  final TripRepository? repository;

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  late final TripRepository _repository =
      widget.repository ?? LocalTripRepository();

  List<TripPlan> _trips = const [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  TripPlan? get _selectedTrip {
    if (_trips.isEmpty) return null;
    return _trips[_selectedIndex.clamp(0, _trips.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var trips = await _repository.listTrips();
      if (trips.isEmpty) {
        trips = await _seedTrips();
      }
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _selectedIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Trip planner unavailable';
      });
    }
  }

  Future<List<TripPlan>> _seedTrips() async {
    final seeds = [
      MockCamperRepository.trips[0].copyWith(
        stages: const [
          'Stage 1: Verona to Molveno',
          'Overnight: lake area',
          'Weather checkpoint near mountain pass',
        ],
        overnightStop: 'Lake area backup spot',
        estimatedCost: 148,
        notes: 'Check mountain roads and LPG before arrival.',
      ),
      MockCamperRepository.trips[1].copyWith(
        stages: const ['Sirmione', 'Bardolino', 'Malcesine'],
        overnightStop: 'North shore aire',
        estimatedCost: 96,
        notes: 'Keep one slow morning for groceries and laundry.',
      ),
    ];

    final saved = <TripPlan>[];
    for (final trip in seeds) {
      saved.add(await _repository.saveTrip(trip));
    }
    return saved;
  }

  Future<void> _openEditor({TripPlan? trip}) async {
    final result = await showModalBottomSheet<TripPlan>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TripEditor(trip: trip),
    );

    if (result == null) return;

    try {
      final saved = await _repository.saveTrip(result.copyWith(id: trip?.id));
      if (!mounted) return;
      setState(() {
        if (trip == null) {
          _trips = [saved, ..._trips];
          _selectedIndex = 0;
        } else {
          _trips = [
            for (final existing in _trips)
              if (existing.id == saved.id) saved else existing,
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Trip save failed');
    }
  }

  Future<void> _deleteSelectedTrip() async {
    final trip = _selectedTrip;
    final id = trip?.id;
    if (trip == null || id == null) return;

    final previous = _trips;
    setState(() {
      _trips = _trips.where((entry) => entry.id != id).toList();
      _selectedIndex = 0;
    });

    try {
      await _repository.deleteTrip(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trips = previous;
        _error = 'Trip delete failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _selectedTrip;
    final progress = trip?.progress ?? 0.0;

    return ScreenScaffold(
      title: 'Trip planner',
      subtitle: 'Create trips, stages, stops, costs, notes, and dates.',
      children: [
        PremiumCard(
          child: Row(
            children: [
              Expanded(
                child: ResourceBar(
                  label: 'Planner completion',
                  value: progress,
                  detail: trip == null
                      ? 'No trip selected'
                      : '${trip.stages.length} stages saved locally',
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add trip',
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
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
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (trip == null)
          const PremiumCard(child: Text('No trips yet'))
        else ...[
          if (_trips.length > 1)
            _TripSelector(
              trips: _trips,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
          if (_trips.length > 1) const SizedBox(height: 16),
          TripCard(
            title: trip.title,
            summary: trip.summary,
            progress: progress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditor(trip: trip),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit trip'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                tooltip: 'Delete trip',
                onPressed: _deleteSelectedTrip,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TripMetrics(trip: trip),
          const SizedBox(height: 16),
          for (final stage in trip.stages) ...[
            ActionTile(
              icon: _iconForStage(stage),
              title: stage,
              subtitle: trip.overnightStop ?? 'Saved stage',
            ),
            const SizedBox(height: 12),
          ],
          if (trip.notes != null && trip.notes!.isNotEmpty)
            PremiumCard(child: Text(trip.notes!)),
        ],
      ],
    );
  }

  IconData _iconForStage(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('weather')) return Icons.cloud_outlined;
    if (lower.contains('overnight') || lower.contains('stop')) {
      return Icons.night_shelter_outlined;
    }
    return Icons.flag_outlined;
  }
}

class _TripSelector extends StatelessWidget {
  const _TripSelector({
    required this.trips,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<TripPlan> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: [
          for (final (index, trip) in trips.indexed)
            ButtonSegment(value: index, label: Text(trip.title)),
        ],
        selected: {selectedIndex},
        onSelectionChanged: (selection) => onSelected(selection.single),
      ),
    );
  }
}

class _TripMetrics extends StatelessWidget {
  const _TripMetrics({required this.trip});

  final TripPlan trip;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricTile(
          icon: Icons.local_gas_station_outlined,
          label: 'Cost',
          value: trip.estimatedCost == null
              ? 'TBD'
              : 'EUR ${trip.estimatedCost!.round()}',
          detail: trip.overnightStop ?? 'No stop selected',
        ),
        MetricTile(
          icon: Icons.event_outlined,
          label: 'Dates',
          value: _dateRange,
          detail: 'Editable trip window',
        ),
        MetricTile(
          icon: Icons.route_outlined,
          label: 'Stages',
          value: '${trip.stages.length}',
          detail: 'Saved route points',
        ),
        MetricTile(
          icon: Icons.height_outlined,
          label: 'Progress',
          value: '${(trip.progress * 100).round()}%',
          detail: 'Planner readiness',
        ),
      ],
    );
  }

  String get _dateRange {
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null && end == null) return 'Unset';
    final startText = start == null ? '?' : '${start.month}/${start.day}';
    final endText = end == null ? '?' : '${end.month}/${end.day}';
    return '$startText-$endText';
  }
}

class _TripEditor extends StatefulWidget {
  const _TripEditor({this.trip});

  final TripPlan? trip;

  @override
  State<_TripEditor> createState() => _TripEditorState();
}

class _TripEditorState extends State<_TripEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _stagesController;
  late final TextEditingController _overnightController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _titleController = TextEditingController(text: trip?.title ?? '');
    _summaryController = TextEditingController(text: trip?.summary ?? '');
    _stagesController = TextEditingController(
      text: trip?.stages.join('\n') ?? '',
    );
    _overnightController = TextEditingController(text: trip?.overnightStop);
    _costController = TextEditingController(
      text: trip?.estimatedCost?.round().toString() ?? '',
    );
    _notesController = TextEditingController(text: trip?.notes);
    _startDate = trip?.startDate;
    _endDate = trip?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _stagesController.dispose();
    _overnightController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    if (title.isEmpty || summary.isEmpty) return;

    final stages = _stagesController.text
        .split('\n')
        .map((stage) => stage.trim())
        .where((stage) => stage.isNotEmpty)
        .toList();
    final cost = double.tryParse(_costController.text.trim());
    final notes = _notesController.text.trim();
    final overnightStop = _overnightController.text.trim();
    final progress = (stages.length / 6).clamp(0.0, 1.0);

    Navigator.of(context).pop(
      TripPlan(
        id: widget.trip?.id,
        title: title,
        summary: summary,
        progress: progress,
        startDate: _startDate,
        endDate: _endDate,
        stages: stages,
        overnightStop: overnightStop.isEmpty ? null : overnightStop,
        estimatedCost: cost,
        notes: notes.isEmpty ? null : notes,
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
              widget.trip == null ? 'Add trip' : 'Edit trip',
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
              decoration: const InputDecoration(labelText: 'Summary'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stagesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Stages',
                hintText: 'One stage or stop per line',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _overnightController,
              decoration: const InputDecoration(labelText: 'Overnight stop'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estimated cost'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: true),
                    icon: const Icon(Icons.event),
                    label: Text(_dateLabel(_startDate, fallback: 'Start')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: false),
                    icon: const Icon(Icons.event_available),
                    label: Text(_dateLabel(_endDate, fallback: 'End')),
                  ),
                ),
              ],
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

  String _dateLabel(DateTime? date, {required String fallback}) {
    if (date == null) return fallback;
    return '${date.year}-${date.month}-${date.day}';
  }
}
