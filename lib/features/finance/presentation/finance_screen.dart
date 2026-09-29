import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/finance_summary_service.dart';
import '../../../core/services/app_system_services.dart';
import '../../../core/services/reminder_coordinator.dart';
import '../../../data/models/finance_models.dart';
import '../../../data/models/route_preview.dart';
import '../../../data/models/trip_plan.dart';
import '../../../data/models/vehicle_document.dart';
import '../../../data/models/vehicle_profile.dart';
import '../../../data/repositories/local_finance_repository.dart';
import '../../../data/repositories/local_route_preview_repository.dart';
import '../../../data/repositories/local_trip_repository.dart';
import '../../../data/repositories/local_vehicle_document_repository.dart';
import '../../../data/repositories/local_vehicle_profile_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({
    this.financeRepository,
    this.tripRepository,
    this.routePreviewRepository,
    this.profileRepository,
    this.documentRepository,
    this.reminderService,
    this.initialTripId,
    super.key,
  });

  final FinanceRepository? financeRepository;
  final TripRepository? tripRepository;
  final RoutePreviewRepository? routePreviewRepository;
  final VehicleProfileRepository? profileRepository;
  final VehicleDocumentRepository? documentRepository;
  final ReminderSyncService? reminderService;
  final int? initialTripId;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late final FinanceRepository _financeRepository =
      widget.financeRepository ?? LocalFinanceRepository();
  late final TripRepository _tripRepository =
      widget.tripRepository ?? LocalTripRepository();
  late final RoutePreviewRepository _routePreviewRepository =
      widget.routePreviewRepository ?? LocalRoutePreviewRepository();
  late final VehicleProfileRepository _profileRepository =
      widget.profileRepository ?? LocalVehicleProfileRepository();
  late final VehicleDocumentRepository _documentRepository =
      widget.documentRepository ?? LocalVehicleDocumentRepository();
  late final ReminderSyncService _reminderService =
      widget.reminderService ?? AppSystemServices.instance.reminders;
  final _summaryService = const FinanceSummaryService();

  VehicleProfile? _profile;
  List<TripPlan> _trips = const [];
  List<VehicleDocument> _documents = const [];
  List<Expense> _expenses = const [];
  List<FuelEntry> _fuelEntries = const [];
  List<TripBooking> _bookings = const [];
  TripBudget? _budget;
  RouteResult? _route;
  int? _selectedTripId;
  bool _isLoading = true;
  String? _error;

  TripPlan? get _selectedTrip {
    final id = _selectedTripId;
    if (id == null) return null;
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileRepository.loadProfile();
      final trips = await _tripRepository.listTrips();
      final documents = await _documentRepository.listDocuments();
      final expenses = await _financeRepository.listExpenses();
      final fuelEntries = await _financeRepository.listFuelEntries();
      final bookings = await _financeRepository.listBookings();
      final selectedTripId = widget.initialTripId ??
          _selectedTripId ??
          (trips.isEmpty ? null : trips.first.id);
      final budget = selectedTripId == null
          ? null
          : await _financeRepository.loadTripBudget(selectedTripId);
      final route = selectedTripId == null
          ? null
          : await _routePreviewRepository.loadRouteForTrip(selectedTripId);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _trips = trips;
        _documents = documents;
        _expenses = expenses;
        _fuelEntries = fuelEntries;
        _bookings = bookings;
        _selectedTripId = selectedTripId;
        _budget = budget;
        _route = route;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Finance data unavailable';
      });
    }
  }

  Future<void> _selectTrip(int? tripId) async {
    setState(() => _selectedTripId = tripId);
    if (tripId == null) {
      setState(() {
        _budget = null;
        _route = null;
      });
      return;
    }
    final budget = await _financeRepository.loadTripBudget(tripId);
    final route = await _routePreviewRepository.loadRouteForTrip(tripId);
    if (!mounted) return;
    setState(() {
      _budget = budget;
      _route = route;
    });
  }

  Future<void> _saveExpense([Expense? expense]) async {
    final created = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExpenseEditor(
        expense: expense,
        profile: _profile,
        trips: _trips,
        documents: _documents,
        initialTripId: _selectedTripId,
      ),
    );
    if (created == null) return;

    try {
      await _financeRepository.saveExpense(created);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Expense save failed');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    await _financeRepository.deleteExpense(expense.id);
    await _load();
  }

  Future<void> _saveFuelEntry([FuelEntry? entry]) async {
    final profile = _profile;
    if (profile?.id == null) {
      setState(() => _error = 'Create a vehicle profile before adding fuel');
      return;
    }

    final created = await showModalBottomSheet<FuelEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FuelEditor(
        entry: entry,
        vehicleId: profile!.id!,
        trips: _trips,
        documents: _documents,
        initialTripId: _selectedTripId,
      ),
    );
    if (created == null) return;

    try {
      await _financeRepository.saveFuelEntry(created);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Fuel entry save failed');
    }
  }

  Future<void> _deleteFuelEntry(FuelEntry entry) async {
    await _financeRepository.deleteFuelEntry(entry.id);
    await _load();
  }

  Future<void> _saveBudget() async {
    final trip = _selectedTrip;
    final id = trip?.id;
    if (id == null) return;
    final budget = await showModalBottomSheet<TripBudget>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BudgetEditor(
        tripId: id,
        budget: _budget,
      ),
    );
    if (budget == null) return;

    try {
      await _financeRepository.saveTripBudget(budget);
      await _selectTrip(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Budget save failed');
    }
  }

  Future<void> _saveBooking([TripBooking? booking]) async {
    final trip = _selectedTrip;
    final tripId = trip?.id;
    if (tripId == null) {
      setState(() => _error = 'Select a trip before adding a booking');
      return;
    }

    final created = await showModalBottomSheet<TripBooking>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BookingEditor(
        booking: booking,
        tripId: tripId,
        documents: _documents,
      ),
    );
    if (created == null) return;

    try {
      final saved = await _financeRepository.saveBooking(created);
      await _reminderService.syncBooking(saved);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Booking save failed');
    }
  }

  Future<void> _deleteBooking(TripBooking booking) async {
    await _financeRepository.deleteBooking(booking.id);
    await _reminderService.deleteBookingReminders(booking.id);
    await _load();
  }

  Future<void> _openNavigation(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() => _error = 'Navigation unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final trip = _selectedTrip;
    final tripExpenses =
        _expenses.where((expense) => expense.tripId == trip?.id).toList();
    final vehicleFuel = _fuelEntries
        .where((entry) => entry.vehicleId == profile?.id)
        .toList(growable: false);
    final tripFuel =
        _fuelEntries.where((entry) => entry.tripId == trip?.id).toList();
    final tripBookings =
        _bookings.where((booking) => booking.tripId == trip?.id).toList();
    final fuelStats = _summaryService.buildFuelStats(vehicleFuel);
    final budgetSummary = trip == null
        ? null
        : _summaryService.buildTripBudgetSummary(
            trip: trip,
            expenses: tripExpenses,
            fuelEntries: tripFuel,
            bookings: tripBookings,
            budget: _budget,
            route: _route,
          );

    return ScreenScaffold(
      title: 'Costs, budgets & bookings',
      subtitle:
          'Track fuel, expenses, trip budgets, attachments, and reminders locally.',
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _FinanceActions(
            onAddFuel: profile?.id == null ? null : () => _saveFuelEntry(),
            onAddExpense: _saveExpense,
            onAddBooking: trip?.id == null ? null : () => _saveBooking(),
          ),
          const SizedBox(height: 16),
          if (profile != null) ...[
            const SectionHeader(title: 'Vehicle'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.12,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Fuel spend',
                  value: formatAmountMinor(fuelStats.totalCostMinor),
                  detail:
                      '${(fuelStats.totalVolumeMilliLitres / 1000).toStringAsFixed(1)} L',
                ),
                MetricTile(
                  icon: Icons.speed_outlined,
                  label: 'Avg consumption',
                  value: fuelStats.averageConsumptionLitersPer100Km == null
                      ? '--'
                      : '${fuelStats.averageConsumptionLitersPer100Km!.toStringAsFixed(1)} L/100km',
                  detail: 'Full tanks only',
                ),
                MetricTile(
                  icon: Icons.route_outlined,
                  label: 'Cost / km',
                  value: fuelStats.costPerKmMinor == null
                      ? '--'
                      : formatAmountMinor(fuelStats.costPerKmMinor!),
                  detail: 'Fuel only',
                ),
                MetricTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'This month',
                  value: formatAmountMinor(fuelStats.monthlyCostMinor),
                  detail:
                      'This year ${formatAmountMinor(fuelStats.yearlyCostMinor)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_trips.isNotEmpty) ...[
            PremiumCard(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedTripId,
                      items: [
                        for (final trip in _trips)
                          DropdownMenuItem(
                            value: trip.id,
                            child: Text(trip.title),
                          ),
                      ],
                      onChanged: _selectTrip,
                      decoration: const InputDecoration(
                        labelText: 'Trip budget context',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    tooltip: 'Edit budget',
                    onPressed: trip?.id == null ? null : _saveBudget,
                    icon: const Icon(Icons.savings_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (budgetSummary != null) ...[
              const SectionHeader(title: 'Trip'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.12,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Planned',
                    value: formatAmountMinor(budgetSummary.plannedMinor),
                    detail: 'Budget',
                  ),
                  MetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Spent',
                    value: formatAmountMinor(budgetSummary.spentMinor),
                    detail: 'Expenses + fuel + bookings',
                  ),
                  MetricTile(
                    icon: Icons.balance_outlined,
                    label: 'Remaining',
                    value: formatAmountMinor(budgetSummary.remainingMinor),
                    detail: budgetSummary.remainingMinor < 0
                        ? 'Over budget'
                        : 'Available',
                  ),
                  MetricTile(
                    icon: Icons.analytics_outlined,
                    label: 'Cost / day',
                    value: budgetSummary.costPerDayMinor == null
                        ? '--'
                        : formatAmountMinor(budgetSummary.costPerDayMinor!),
                    detail: budgetSummary.costPerKmMinor == null
                        ? 'No route saved'
                        : 'Cost / km ${formatAmountMinor(budgetSummary.costPerKmMinor!)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
          const SectionHeader(title: 'Fuel log'),
          const SizedBox(height: 12),
          if (vehicleFuel.isEmpty)
            const PremiumCard(child: Text('No fuel entries yet'))
          else
            for (final entry in vehicleFuel) ...[
              _FuelCard(
                entry: entry,
                onEdit: () => _saveFuelEntry(entry),
                onDelete: () => _deleteFuelEntry(entry),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 16),
          const SectionHeader(title: 'Expenses'),
          const SizedBox(height: 12),
          if (_expenses.isEmpty)
            const PremiumCard(child: Text('No expenses yet'))
          else
            for (final expense in _expenses) ...[
              _ExpenseCard(
                expense: expense,
                documentTitle: _documentTitle(expense.documentId),
                onEdit: () => _saveExpense(expense),
                onDelete: () => _deleteExpense(expense),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 16),
          const SectionHeader(title: 'Bookings'),
          const SizedBox(height: 12),
          if (tripBookings.isEmpty)
            const PremiumCard(child: Text('No bookings for the selected trip'))
          else
            for (final booking in tripBookings) ...[
              _BookingCard(
                booking: booking,
                documentTitle: _documentTitle(booking.documentId),
                onEdit: () => _saveBooking(booking),
                onDelete: () => _deleteBooking(booking),
                onNavigate: booking.address == null
                    ? null
                    : () => _openNavigation(booking.address!),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ],
    );
  }

  String? _documentTitle(int? id) {
    if (id == null) return null;
    for (final document in _documents) {
      if (document.id == id) return document.title;
    }
    return null;
  }
}

class _FinanceActions extends StatelessWidget {
  const _FinanceActions({
    required this.onAddFuel,
    required this.onAddExpense,
    required this.onAddBooking,
  });

  final VoidCallback? onAddFuel;
  final VoidCallback onAddExpense;
  final VoidCallback? onAddBooking;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: onAddFuel,
            icon: const Icon(Icons.local_gas_station_outlined),
            label: const Text('Add fuel'),
          ),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Add expense'),
          ),
          FilledButton.icon(
            onPressed: onAddBooking,
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('Add booking'),
          ),
        ],
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  const _FuelCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FuelEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final costPerLiter =
        entry.liters <= 0 ? null : entry.totalCostMinor / entry.liters;
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(child: Icon(Icons.local_gas_station_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.station ?? 'Fuel entry',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(entry.date)} - ${entry.odometerKm} km - ${entry.liters.toStringAsFixed(1)} L',
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatAmountMinor(entry.totalCostMinor)}'
                  '${costPerLiter == null ? '' : ' - ${formatAmountMinor(costPerLiter.round())}/L'}'
                  '${entry.fullTank ? ' - Full tank' : ' - Partial'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(entry.notes!),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit fuel',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete fuel',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.documentTitle,
  });

  final Expense expense;
  final String? documentTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title ?? expense.category.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.scope.name} - ${expense.category.name} - ${formatAmountMinor(expense.amountMinor, currencyCode: expense.currencyCode)}',
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatDate(expense.occurredAt)}${documentTitle == null ? '' : ' - $documentTitle'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(expense.notes!),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit expense',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onEdit,
    required this.onDelete,
    this.documentTitle,
    this.onNavigate,
  });

  final TripBooking booking;
  final String? documentTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.event_available_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.type.name} - ${booking.status.name}'
                      '${booking.costMinor == null ? '' : ' - ${formatAmountMinor(booking.costMinor!, currencyCode: booking.currencyCode)}'}',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit booking',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete booking',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (booking.startsAt != null)
                'Start ${_formatDate(booking.startsAt!)}',
              if (booking.endsAt != null) 'End ${_formatDate(booking.endsAt!)}',
              if (booking.bookingCode != null &&
                  booking.bookingCode!.isNotEmpty)
                'Code ${booking.bookingCode!}',
              if (documentTitle != null) documentTitle!,
            ].join(' - '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (booking.address != null && booking.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(booking.address!),
          ],
          if (booking.contact != null && booking.contact!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(booking.contact!),
          ],
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(booking.notes!),
          ],
          if (onNavigate != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigate'),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _ExpenseEditor extends StatefulWidget {
  const _ExpenseEditor({
    required this.profile,
    required this.trips,
    required this.documents,
    required this.initialTripId,
    this.expense,
  });

  final VehicleProfile? profile;
  final List<TripPlan> trips;
  final List<VehicleDocument> documents;
  final int? initialTripId;
  final Expense? expense;

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<_ExpenseEditor> {
  late ExpenseScope _scope;
  late ExpenseCategory _category;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _notesController;
  DateTime _occurredAt = DateTime.now();
  int? _tripId;
  int? _documentId;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _scope = expense?.scope ?? ExpenseScope.trip;
    _category = expense?.category ?? ExpenseCategory.other;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text:
          expense == null ? '' : (expense.amountMinor / 100).toStringAsFixed(2),
    );
    _currencyController =
        TextEditingController(text: expense?.currencyCode ?? 'EUR');
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _occurredAt = expense?.occurredAt ?? DateTime.now();
    _tripId = expense?.tripId ?? widget.initialTripId;
    _documentId = expense?.documentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _occurredAt = picked);
    }
  }

  void _save() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return;
    Navigator.of(context).pop(
      Expense(
        id: widget.expense?.id ??
            'expense-${DateTime.now().microsecondsSinceEpoch}',
        scope: _scope,
        vehicleId: _scope == ExpenseScope.trip ? null : widget.profile?.id,
        tripId: _scope == ExpenseScope.trip ? _tripId : null,
        category: _category,
        amountMinor: parseAmountMinor(amount),
        currencyCode: _currencyController.text.trim().toUpperCase(),
        occurredAt: _occurredAt,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentId: _documentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title: widget.expense == null ? 'Add expense' : 'Edit expense',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ExpenseScope>(
            initialValue: _scope,
            items: ExpenseScope.values
                .map(
                  (scope) => DropdownMenuItem(
                    value: scope,
                    child: Text(scope.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _scope = value);
            },
            decoration: const InputDecoration(labelText: 'Scope'),
          ),
          const SizedBox(height: 12),
          if (_scope == ExpenseScope.trip)
            DropdownButtonFormField<int>(
              initialValue: _tripId,
              items: [
                for (final trip in widget.trips)
                  DropdownMenuItem(value: trip.id, child: Text(trip.title)),
              ],
              onChanged: (value) => setState(() => _tripId = value),
              decoration: const InputDecoration(labelText: 'Trip'),
            ),
          if (_scope == ExpenseScope.trip) const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            items: ExpenseCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_formatDate(_occurredAt)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _documentId,
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('No document')),
              for (final document in widget.documents)
                DropdownMenuItem<int>(
                  value: document.id,
                  child: Text(document.title),
                ),
            ],
            onChanged: (value) => setState(() => _documentId = value),
            decoration: const InputDecoration(labelText: 'Attachment'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

class _FuelEditor extends StatefulWidget {
  const _FuelEditor({
    required this.vehicleId,
    required this.trips,
    required this.documents,
    required this.initialTripId,
    this.entry,
  });

  final int vehicleId;
  final List<TripPlan> trips;
  final List<VehicleDocument> documents;
  final int? initialTripId;
  final FuelEntry? entry;

  @override
  State<_FuelEditor> createState() => _FuelEditorState();
}

class _FuelEditorState extends State<_FuelEditor> {
  late final TextEditingController _stationController;
  late final TextEditingController _odometerController;
  late final TextEditingController _litersController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _notesController;
  DateTime _date = DateTime.now();
  bool _fullTank = true;
  int? _tripId;
  int? _documentId;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _stationController = TextEditingController(text: entry?.station ?? '');
    _odometerController =
        TextEditingController(text: entry?.odometerKm.toString() ?? '');
    _litersController = TextEditingController(
      text: entry == null ? '' : entry.liters.toStringAsFixed(1),
    );
    _amountController = TextEditingController(
      text:
          entry == null ? '' : (entry.totalCostMinor / 100).toStringAsFixed(2),
    );
    _currencyController =
        TextEditingController(text: entry?.currencyCode ?? 'EUR');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _date = entry?.date ?? DateTime.now();
    _fullTank = entry?.fullTank ?? true;
    _tripId = entry?.tripId ?? widget.initialTripId;
    _documentId = entry?.documentId;
  }

  @override
  void dispose() {
    _stationController.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final odometer = int.tryParse(_odometerController.text.trim());
    final liters =
        double.tryParse(_litersController.text.trim().replaceAll(',', '.'));
    final amount = _amountController.text.trim();
    if (odometer == null || liters == null || amount.isEmpty) return;

    Navigator.of(context).pop(
      FuelEntry(
        id: widget.entry?.id ?? 'fuel-${DateTime.now().microsecondsSinceEpoch}',
        vehicleId: widget.vehicleId,
        tripId: _tripId,
        date: _date,
        odometerKm: odometer,
        volumeMilliLitres: (liters * 1000).round(),
        totalCostMinor: parseAmountMinor(amount),
        currencyCode: _currencyController.text.trim().toUpperCase(),
        fullTank: _fullTank,
        station: _stationController.text.trim().isEmpty
            ? null
            : _stationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentId: _documentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title: widget.entry == null ? 'Add fuel' : 'Edit fuel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _stationController,
            decoration: const InputDecoration(labelText: 'Station'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _tripId,
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('No trip')),
              for (final trip in widget.trips)
                DropdownMenuItem(value: trip.id, child: Text(trip.title)),
            ],
            onChanged: (value) => setState(() => _tripId = value),
            decoration: const InputDecoration(labelText: 'Trip'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Odometer km'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _litersController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Liters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total cost'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Full tank'),
            value: _fullTank,
            onChanged: (value) => setState(() => _fullTank = value),
          ),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_formatDate(_date)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _documentId,
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('No document')),
              for (final document in widget.documents)
                DropdownMenuItem<int>(
                  value: document.id,
                  child: Text(document.title),
                ),
            ],
            onChanged: (value) => setState(() => _documentId = value),
            decoration: const InputDecoration(labelText: 'Attachment'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({
    required this.tripId,
    this.budget,
  });

  final int tripId;
  final TripBudget? budget;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget == null
          ? ''
          : (widget.budget!.plannedAmountMinor / 100).toStringAsFixed(2),
    );
    _currencyController =
        TextEditingController(text: widget.budget?.currencyCode ?? 'EUR');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return;
    Navigator.of(context).pop(
      TripBudget(
        tripId: widget.tripId,
        plannedAmountMinor: parseAmountMinor(amount),
        currencyCode: _currencyController.text.trim().toUpperCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title: 'Trip budget',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Planned budget'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

class _BookingEditor extends StatefulWidget {
  const _BookingEditor({
    required this.tripId,
    required this.documents,
    this.booking,
  });

  final int tripId;
  final List<VehicleDocument> documents;
  final TripBooking? booking;

  @override
  State<_BookingEditor> createState() => _BookingEditorState();
}

class _BookingEditorState extends State<_BookingEditor> {
  late BookingType _type;
  late BookingStatus _status;
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final TextEditingController _bookingCodeController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _contactController;
  late final TextEditingController _notesController;
  late final TextEditingController _poiIdController;
  DateTime? _startsAt;
  DateTime? _endsAt;
  int? _documentId;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    _type = booking?.type ?? BookingType.campsite;
    _status = booking?.status ?? BookingStatus.confirmed;
    _titleController = TextEditingController(text: booking?.title ?? '');
    _addressController = TextEditingController(text: booking?.address ?? '');
    _bookingCodeController =
        TextEditingController(text: booking?.bookingCode ?? '');
    _amountController = TextEditingController(
      text: booking?.costMinor == null
          ? ''
          : (booking!.costMinor! / 100).toStringAsFixed(2),
    );
    _currencyController =
        TextEditingController(text: booking?.currencyCode ?? 'EUR');
    _contactController = TextEditingController(text: booking?.contact ?? '');
    _notesController = TextEditingController(text: booking?.notes ?? '');
    _poiIdController = TextEditingController(text: booking?.poiId ?? '');
    _startsAt = booking?.startsAt;
    _endsAt = booking?.endsAt;
    _documentId = booking?.documentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _bookingCodeController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    _poiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _startsAt : _endsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startsAt = picked;
      } else {
        _endsAt = picked;
      }
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      TripBooking(
        id: widget.booking?.id ??
            'booking-${DateTime.now().microsecondsSinceEpoch}',
        tripId: widget.tripId,
        type: _type,
        status: _status,
        title: title,
        startsAt: _startsAt,
        endsAt: _endsAt,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        bookingCode: _bookingCodeController.text.trim().isEmpty
            ? null
            : _bookingCodeController.text.trim(),
        costMinor: _amountController.text.trim().isEmpty
            ? null
            : parseAmountMinor(_amountController.text.trim()),
        currencyCode: _currencyController.text.trim().toUpperCase(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentId: _documentId,
        poiId: _poiIdController.text.trim().isEmpty
            ? null
            : _poiIdController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title: widget.booking == null ? 'Add booking' : 'Edit booking',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BookingType>(
            initialValue: _type,
            items: BookingType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BookingStatus>(
            initialValue: _status,
            items: BookingStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(start: true),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                      _startsAt == null ? 'Start' : _formatDate(_startsAt!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(start: false),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(_endsAt == null ? 'End' : _formatDate(_endsAt!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bookingCodeController,
            decoration: const InputDecoration(labelText: 'Booking code'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cost'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Contact'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _documentId,
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('No document')),
              for (final document in widget.documents)
                DropdownMenuItem<int>(
                  value: document.id,
                  child: Text(document.title),
                ),
            ],
            onChanged: (value) => setState(() => _documentId = value),
            decoration: const InputDecoration(labelText: 'Attachment'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _poiIdController,
            decoration: const InputDecoration(labelText: 'Linked POI id'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

class _EditorSheet extends StatelessWidget {
  const _EditorSheet({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
