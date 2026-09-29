import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/locale_number_parser.dart';
import '../../../data/models/vehicle_profile.dart';
import '../../../data/repositories/local_vehicle_profile_repository.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

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
        _error = 'profile_error_load'.tr();
      });
    }
  }

  Future<void> _openEditor() async {
    final result = await showModalBottomSheet<VehicleProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VehicleProfileEditor(profile: _profile),
    );
    if (result == null) return;

    try {
      final saved = await _repository.saveProfile(result);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'profile_error_save'.tr());
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('profile_delete_title'.tr()),
            content: Text('profile_delete_body'.tr()),
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

    final previous = _profile;
    setState(() => _profile = null);
    try {
      await _repository.deleteProfile();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = previous;
        _error = 'profile_error_delete'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return ScreenScaffold(
      title: 'profile_title'.tr(),
      subtitle: 'profile_subtitle'.tr(),
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
                            ? 'profile_empty_title'.tr()
                            : '${profile.brand} ${profile.model}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile == null
                            ? 'profile_empty_body'.tr()
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
                Chip(label: Text('profile_local_badge'.tr())),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricTile(
                icon: Icons.height_outlined,
                label: 'profile_dimensions'.tr(),
                value: profile == null ? '--' : _dimensionsLabel(profile),
                detail: 'profile_dimensions_detail'.tr(),
              ),
              MetricTile(
                icon: Icons.monitor_weight_outlined,
                label: 'profile_mass'.tr(),
                value: profile == null ? '--' : _massLabel(profile),
                detail: 'profile_mass_detail'.tr(),
              ),
              MetricTile(
                icon: Icons.water_drop_outlined,
                label: 'profile_tanks'.tr(),
                value: profile == null ? '--' : _tanksLabel(profile),
                detail: 'profile_tanks_detail'.tr(),
              ),
              MetricTile(
                icon: Icons.route_outlined,
                label: 'profile_mileage'.tr(),
                value: profile == null ? '--' : _mileageLabel(profile),
                detail: profile == null
                    ? 'profile_not_saved'.tr()
                    : 'profile_seats_fuel'.tr(
                        namedArgs: {
                          'seats': profile.seats.toString(),
                          'fuel': profile.fuelType,
                        },
                      ),
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
                    profile == null
                        ? 'profile_create'.tr()
                        : 'profile_edit'.tr(),
                  ),
                ),
              ),
              if (profile != null) ...[
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: 'profile_delete'.tr(),
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
        ],
      ],
    );
  }

  String _profileSummary(VehicleProfile profile) {
    return 'profile_summary'.tr(
      namedArgs: {
        'type': profile.vehicleType,
        'year': profile.year.toString(),
        'length': profile.length.toStringAsFixed(2),
        'seats': profile.seats.toString(),
        'mass': profile.maxMass.toStringAsFixed(0),
      },
    );
  }

  static String _dimensionsLabel(VehicleProfile profile) {
    return [
      '${profile.length.toStringAsFixed(2)} m',
      '${profile.width.toStringAsFixed(2)} m',
      '${profile.height.toStringAsFixed(2)} m',
    ].join(' × ');
  }

  static String _massLabel(VehicleProfile profile) {
    return '${profile.weight.toStringAsFixed(0)} / ${profile.maxMass.toStringAsFixed(0)} kg';
  }

  String _tanksLabel(VehicleProfile profile) {
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
    if (parts.isEmpty) return 'profile_unset'.tr();
    return parts.join(' - ');
  }

  static String _mileageLabel(VehicleProfile profile) {
    return '${profile.mileage.toStringAsFixed(0)} km';
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
  late final Map<String, TextEditingController> _controllers;

  TextEditingController get _type => _controllers['type']!;
  TextEditingController get _brand => _controllers['brand']!;
  TextEditingController get _model => _controllers['model']!;
  TextEditingController get _year => _controllers['year']!;
  TextEditingController get _plate => _controllers['plate']!;
  TextEditingController get _length => _controllers['length']!;
  TextEditingController get _width => _controllers['width']!;
  TextEditingController get _height => _controllers['height']!;
  TextEditingController get _weight => _controllers['weight']!;
  TextEditingController get _maxMass => _controllers['maxMass']!;
  TextEditingController get _seats => _controllers['seats']!;
  TextEditingController get _fuel => _controllers['fuel']!;
  TextEditingController get _mileage => _controllers['mileage']!;
  TextEditingController get _fuelCapacity => _controllers['fuelCapacity']!;
  TextEditingController get _waterCapacity => _controllers['waterCapacity']!;
  TextEditingController get _gasCapacity => _controllers['gasCapacity']!;
  TextEditingController get _electricRange => _controllers['electricRange']!;
  TextEditingController get _notes => _controllers['notes']!;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _controllers = {
      'type': TextEditingController(text: p?.vehicleType ?? ''),
      'brand': TextEditingController(text: p?.brand ?? ''),
      'model': TextEditingController(text: p?.model ?? ''),
      'year': TextEditingController(text: p?.year.toString() ?? ''),
      'plate': TextEditingController(text: p?.plate ?? ''),
      'length': TextEditingController(text: p?.length.toStringAsFixed(2) ?? ''),
      'width': TextEditingController(text: p?.width.toStringAsFixed(2) ?? ''),
      'height': TextEditingController(text: p?.height.toStringAsFixed(2) ?? ''),
      'weight': TextEditingController(text: p?.weight.toStringAsFixed(0) ?? ''),
      'maxMass': TextEditingController(text: p?.maxMass.toStringAsFixed(0) ?? ''),
      'seats': TextEditingController(text: p?.seats.toString() ?? ''),
      'fuel': TextEditingController(text: p?.fuelType ?? ''),
      'mileage': TextEditingController(text: p?.mileage.toStringAsFixed(0) ?? ''),
      'fuelCapacity':
          TextEditingController(text: p?.fuelCapacity?.toStringAsFixed(0) ?? ''),
      'waterCapacity':
          TextEditingController(text: p?.waterCapacity?.toStringAsFixed(0) ?? ''),
      'gasCapacity':
          TextEditingController(text: p?.gasCapacity?.toStringAsFixed(0) ?? ''),
      'electricRange':
          TextEditingController(text: p?.electricRange?.toStringAsFixed(0) ?? ''),
      'notes': TextEditingController(text: p?.notes ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'form_required'.tr();
    return null;
  }

  String? _positive(String? value) {
    final parsed = parseLocaleDouble(value ?? '');
    if (parsed == null) return 'form_number_invalid'.tr();
    if (parsed <= 0) return 'form_number_positive'.tr();
    return null;
  }

  String? _nonNegative(String? value) {
    final parsed = parseLocaleDouble(value ?? '');
    if (parsed == null) return 'form_number_invalid'.tr();
    if (parsed < 0) return 'form_number_non_negative'.tr();
    return null;
  }

  String? _optionalPositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _positive(value);
  }

  String? _yearValidator(String? value) {
    final year = int.tryParse(value?.trim() ?? '');
    final maxYear = DateTime.now().year + 1;
    if (year == null) return 'form_number_invalid'.tr();
    if (year < 1900 || year > maxYear) return 'profile_year_invalid'.tr();
    return null;
  }

  String? _seatsValidator(String? value) {
    final seats = int.tryParse(value?.trim() ?? '');
    if (seats == null) return 'form_number_invalid'.tr();
    if (seats <= 0) return 'form_number_positive'.tr();
    return null;
  }

  String? _maxMassValidator(String? value) {
    final base = _positive(value);
    if (base != null) return base;
    final mass = parseLocaleDouble(value ?? '')!;
    final weight = parseLocaleDouble(_weight.text);
    if (weight != null && mass < weight) {
      return 'profile_max_mass_invalid'.tr();
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      VehicleProfile(
        id: widget.profile?.id,
        vehicleType: _type.text.trim(),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: int.parse(_year.text.trim()),
        plate: _nullable(_plate.text),
        length: parseLocaleDouble(_length.text)!,
        width: parseLocaleDouble(_width.text)!,
        height: parseLocaleDouble(_height.text)!,
        weight: parseLocaleDouble(_weight.text)!,
        maxMass: parseLocaleDouble(_maxMass.text)!,
        seats: int.parse(_seats.text.trim()),
        fuelType: _fuel.text.trim(),
        mileage: parseLocaleDouble(_mileage.text)!,
        fuelCapacity: parseLocaleDouble(_fuelCapacity.text),
        waterCapacity: parseLocaleDouble(_waterCapacity.text),
        gasCapacity: parseLocaleDouble(_gasCapacity.text),
        electricRange: parseLocaleDouble(_electricRange.text),
        notes: _nullable(_notes.text),
        updatedAt: DateTime.now(),
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimalKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.profile == null
                    ? 'profile_create'.tr()
                    : 'profile_edit'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _field(_type, 'profile_vehicle_type'.tr(), validator: _requiredText),
              const SizedBox(height: 12),
              _field(_brand, 'profile_brand'.tr(), validator: _requiredText),
              const SizedBox(height: 12),
              _field(_model, 'profile_model'.tr(), validator: _requiredText),
              const SizedBox(height: 12),
              _field(
                _year,
                'profile_year'.tr(),
                keyboardType: TextInputType.number,
                validator: _yearValidator,
              ),
              const SizedBox(height: 12),
              _field(_plate, 'profile_plate'.tr()),
              const SizedBox(height: 12),
              _field(
                _length,
                'profile_length'.tr(),
                keyboardType: decimalKeyboard,
                validator: _positive,
              ),
              const SizedBox(height: 12),
              _field(
                _width,
                'profile_width'.tr(),
                keyboardType: decimalKeyboard,
                validator: _positive,
              ),
              const SizedBox(height: 12),
              _field(
                _height,
                'profile_height'.tr(),
                keyboardType: decimalKeyboard,
                validator: _positive,
              ),
              const SizedBox(height: 12),
              _field(
                _weight,
                'profile_weight'.tr(),
                keyboardType: decimalKeyboard,
                validator: _positive,
              ),
              const SizedBox(height: 12),
              _field(
                _maxMass,
                'profile_max_mass'.tr(),
                keyboardType: decimalKeyboard,
                validator: _maxMassValidator,
              ),
              const SizedBox(height: 12),
              _field(
                _seats,
                'profile_seats'.tr(),
                keyboardType: TextInputType.number,
                validator: _seatsValidator,
              ),
              const SizedBox(height: 12),
              _field(_fuel, 'profile_fuel_type'.tr(), validator: _requiredText),
              const SizedBox(height: 12),
              _field(
                _mileage,
                'profile_current_mileage'.tr(),
                keyboardType: decimalKeyboard,
                validator: _nonNegative,
              ),
              const SizedBox(height: 12),
              _field(
                _fuelCapacity,
                'profile_fuel_tank'.tr(),
                keyboardType: decimalKeyboard,
                validator: _optionalPositive,
              ),
              const SizedBox(height: 12),
              _field(
                _waterCapacity,
                'profile_water_tank'.tr(),
                keyboardType: decimalKeyboard,
                validator: _optionalPositive,
              ),
              const SizedBox(height: 12),
              _field(
                _gasCapacity,
                'profile_gas_tank'.tr(),
                keyboardType: decimalKeyboard,
                validator: _optionalPositive,
              ),
              const SizedBox(height: 12),
              _field(
                _electricRange,
                'profile_electric_range'.tr(),
                keyboardType: decimalKeyboard,
                validator: _optionalPositive,
              ),
              const SizedBox(height: 12),
              _field(
                _notes,
                'profile_notes'.tr(),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text('save'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
