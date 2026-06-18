import 'package:flutter/material.dart';

import '../../../data/models/vehicle_profile.dart';
import '../../../data/repositories/local_vehicle_profile_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    this.repository,
    super.key,
  });

  final VehicleProfileRepository? repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final VehicleProfileRepository _repository =
      widget.repository ?? LocalVehicleProfileRepository();

  VehicleProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _repository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Vehicle profile unavailable';
      });
    }
  }

  Future<void> _openEditor() async {
    final result = await showModalBottomSheet<VehicleProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VehicleProfileEditor(profile: _profile),
    );

    if (result == null) return;

    try {
      final saved = await _repository.saveProfile(result);
      if (!mounted) return;
      setState(() => _profile = saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Vehicle profile save failed');
    }
  }

  Future<void> _deleteProfile() async {
    final previous = _profile;
    setState(() => _profile = null);

    try {
      await _repository.deleteProfile();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = previous;
        _error = 'Vehicle profile delete failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return ScreenScaffold(
      title: 'My vehicle',
      subtitle: 'Save dimensions, tanks, mileage, and limits locally.',
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
          PremiumCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(
                    profile == null
                        ? Icons.directions_car_outlined
                        : Icons.directions_bus_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile == null
                            ? 'No vehicle profile saved yet'
                            : '${profile.brand} ${profile.model}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile == null
                            ? 'Create one to track dimensions, tanks, mileage, and payload.'
                            : _profileSummary(profile),
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            profile.vehicleType,
                            if (profile.plate != null &&
                                profile.plate!.isNotEmpty)
                              profile.plate!,
                          ].join(' - '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const ProBadge(label: 'LOCAL'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricTile(
                icon: Icons.height_outlined,
                label: 'Dimensions',
                value: profile == null ? '--' : _dimensionsLabel(profile),
                detail: 'L / W / H',
              ),
              MetricTile(
                icon: Icons.monitor_weight_outlined,
                label: 'Mass',
                value: profile == null ? '--' : _massLabel(profile),
                detail: 'Weight and max mass',
              ),
              MetricTile(
                icon: Icons.water_drop_outlined,
                label: 'Tanks',
                value: profile == null ? '--' : _tanksLabel(profile),
                detail: 'Fuel, water, gas',
              ),
              MetricTile(
                icon: Icons.route_outlined,
                label: 'Mileage',
                value: profile == null ? '--' : _mileageLabel(profile),
                detail: profile == null
                    ? 'No profile saved'
                    : '${profile.seats} seats and ${profile.fuelType}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openEditor,
                  icon: Icon(profile == null ? Icons.add : Icons.edit_outlined),
                  label: Text(
                    profile == null ? 'Create profile' : 'Edit profile',
                  ),
                ),
              ),
              if (profile != null) ...[
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: 'Delete profile',
                  onPressed: _deleteProfile,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          if (profile?.notes != null && profile!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            PremiumCard(child: Text(profile.notes!)),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _ProfileActions(),
        ],
      ],
    );
  }

  static String _profileSummary(VehicleProfile profile) {
    final year = profile.year.toString();
    final length = profile.length.toStringAsFixed(2);
    final maxMass = profile.maxMass.toStringAsFixed(0);
    return '${profile.vehicleType} - $year - $length m - ${profile.seats} seats - $maxMass kg max';
  }

  static String _dimensionsLabel(VehicleProfile profile) {
    return [
      '${profile.length.toStringAsFixed(2)} m',
      '${profile.width.toStringAsFixed(2)} m',
      '${profile.height.toStringAsFixed(2)} m',
    ].join(' x ');
  }

  static String _massLabel(VehicleProfile profile) {
    return '${profile.weight.toStringAsFixed(0)} / ${profile.maxMass.toStringAsFixed(0)} kg';
  }

  static String _tanksLabel(VehicleProfile profile) {
    final parts = <String>[
      if (profile.fuelCapacity != null)
        'F ${profile.fuelCapacity!.toStringAsFixed(0)} L',
      if (profile.waterCapacity != null)
        'W ${profile.waterCapacity!.toStringAsFixed(0)} L',
      if (profile.gasCapacity != null)
        'G ${profile.gasCapacity!.toStringAsFixed(0)} kg',
      if (profile.electricRange != null)
        'EV ${profile.electricRange!.toStringAsFixed(0)} km',
    ];
    if (parts.isEmpty) return 'Unset';
    return parts.join(' - ');
  }

  static String _mileageLabel(VehicleProfile profile) {
    return '${profile.mileage.toStringAsFixed(0)} km';
  }
}

class _ProfileActions extends StatelessWidget {
  _ProfileActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle tools',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        const _ActionRow(
          icon: Icons.workspace_premium_outlined,
          title: 'CamperBoss Pro',
          subtitle: 'Monthly, yearly, and lifetime plans',
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Fuel & costs',
          icon: Icons.local_gas_station_outlined,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FinanceScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Preview paywall',
          icon: Icons.payments_outlined,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const _ActionRow(
          icon: Icons.emoji_events_outlined,
          title: 'Achievements',
          subtitle: 'Badges and seasonal challenges',
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleProfileEditor extends StatefulWidget {
  const _VehicleProfileEditor({this.profile});

  final VehicleProfile? profile;

  @override
  State<_VehicleProfileEditor> createState() => _VehicleProfileEditorState();
}

class _VehicleProfileEditorState extends State<_VehicleProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _maxMassController;
  late final TextEditingController _seatsController;
  late final TextEditingController _fuelController;
  late final TextEditingController _mileageController;
  late final TextEditingController _fuelCapacityController;
  late final TextEditingController _waterCapacityController;
  late final TextEditingController _gasCapacityController;
  late final TextEditingController _electricRangeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _typeController = TextEditingController(text: profile?.vehicleType ?? '');
    _brandController = TextEditingController(text: profile?.brand ?? '');
    _modelController = TextEditingController(text: profile?.model ?? '');
    _yearController =
        TextEditingController(text: profile?.year.toString() ?? '');
    _plateController = TextEditingController(text: profile?.plate ?? '');
    _lengthController = TextEditingController(
      text: profile?.length.toStringAsFixed(2) ?? '',
    );
    _widthController = TextEditingController(
      text: profile?.width.toStringAsFixed(2) ?? '',
    );
    _heightController = TextEditingController(
      text: profile?.height.toStringAsFixed(2) ?? '',
    );
    _weightController = TextEditingController(
      text: profile?.weight.toStringAsFixed(0) ?? '',
    );
    _maxMassController = TextEditingController(
      text: profile?.maxMass.toStringAsFixed(0) ?? '',
    );
    _seatsController =
        TextEditingController(text: profile?.seats.toString() ?? '');
    _fuelController = TextEditingController(text: profile?.fuelType ?? '');
    _mileageController = TextEditingController(
      text: profile?.mileage.toStringAsFixed(0) ?? '',
    );
    _fuelCapacityController = TextEditingController(
      text: profile?.fuelCapacity?.toStringAsFixed(0) ?? '',
    );
    _waterCapacityController = TextEditingController(
      text: profile?.waterCapacity?.toStringAsFixed(0) ?? '',
    );
    _gasCapacityController = TextEditingController(
      text: profile?.gasCapacity?.toStringAsFixed(0) ?? '',
    );
    _electricRangeController = TextEditingController(
      text: profile?.electricRange?.toStringAsFixed(0) ?? '',
    );
    _notesController = TextEditingController(text: profile?.notes ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _maxMassController.dispose();
    _seatsController.dispose();
    _fuelController.dispose();
    _mileageController.dispose();
    _fuelCapacityController.dispose();
    _waterCapacityController.dispose();
    _gasCapacityController.dispose();
    _electricRangeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      VehicleProfile(
        id: widget.profile?.id,
        vehicleType: _typeController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        plate: _trimmedOrNull(_plateController.text),
        length: double.parse(_lengthController.text.trim()),
        width: double.parse(_widthController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        maxMass: double.parse(_maxMassController.text.trim()),
        seats: int.parse(_seatsController.text.trim()),
        fuelType: _fuelController.text.trim(),
        mileage: double.parse(_mileageController.text.trim()),
        fuelCapacity: _parseOptionalDouble(_fuelCapacityController.text),
        waterCapacity: _parseOptionalDouble(_waterCapacityController.text),
        gasCapacity: _parseOptionalDouble(_gasCapacityController.text),
        electricRange: _parseOptionalDouble(_electricRangeController.text),
        notes: _trimmedOrNull(_notesController.text),
        updatedAt: DateTime.now(),
      ),
    );
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _requiredNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return double.tryParse(value.trim()) == null
        ? 'Enter a valid number'
        : null;
  }

  String? _requiredInt(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return int.tryParse(value.trim()) == null ? 'Enter a valid number' : null;
  }

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim()) == null
        ? 'Enter a valid number'
        : null;
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.parse(trimmed);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label),
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profile == null ? 'Create profile' : 'Edit profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildField(
                _typeController,
                'Vehicle type',
                validator: (value) => _requiredText(value, 'Vehicle type'),
              ),
              const SizedBox(height: 12),
              _buildField(
                _brandController,
                'Brand',
                validator: (value) => _requiredText(value, 'Brand'),
              ),
              const SizedBox(height: 12),
              _buildField(
                _modelController,
                'Model',
                validator: (value) => _requiredText(value, 'Model'),
              ),
              const SizedBox(height: 12),
              _buildField(
                _yearController,
                'Year',
                keyboardType: TextInputType.number,
                validator: (value) => _requiredInt(value, 'Year'),
              ),
              const SizedBox(height: 12),
              _buildField(
                _plateController,
                'Plate (optional)',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _lengthController,
                      'Length (m)',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredNumber(value, 'Length'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _widthController,
                      'Width (m)',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredNumber(value, 'Width'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _heightController,
                      'Height (m)',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredNumber(value, 'Height'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _weightController,
                      'Weight (kg)',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredNumber(value, 'Weight'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _maxMassController,
                      'Max mass (kg)',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredNumber(value, 'Max mass'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _seatsController,
                      'Seats',
                      keyboardType: TextInputType.number,
                      validator: (value) => _requiredInt(value, 'Seats'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(
                _fuelController,
                'Fuel type',
                validator: (value) => _requiredText(value, 'Fuel type'),
              ),
              const SizedBox(height: 12),
              _buildField(
                _mileageController,
                'Mileage (km)',
                keyboardType: TextInputType.number,
                validator: (value) => _requiredNumber(value, 'Mileage'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _fuelCapacityController,
                      'Fuel tank (L)',
                      keyboardType: TextInputType.number,
                      validator: _optionalNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _waterCapacityController,
                      'Water tank (L)',
                      keyboardType: TextInputType.number,
                      validator: _optionalNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _gasCapacityController,
                      'Gas tank (kg)',
                      keyboardType: TextInputType.number,
                      validator: _optionalNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _electricRangeController,
                      'Electric range (km)',
                      keyboardType: TextInputType.number,
                      validator: _optionalNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
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
      ),
    );
  }
}
