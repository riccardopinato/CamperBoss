import 'package:flutter/material.dart';

import '../../../core/services/offline_guides_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../data/models/guide_models.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class GuidedOnboardingScreen extends StatefulWidget {
  const GuidedOnboardingScreen({
    this.onboardingService,
    super.key,
  });

  final OnboardingService? onboardingService;

  @override
  State<GuidedOnboardingScreen> createState() => _GuidedOnboardingScreenState();
}

class _GuidedOnboardingScreenState extends State<GuidedOnboardingScreen> {
  late final OnboardingService _service =
      widget.onboardingService ?? LocalOnboardingService();
  final _vehicleTypeController = TextEditingController(text: 'Camper van');
  final _lengthController = TextEditingController(text: '6.00');
  final _widthController = TextEditingController(text: '2.10');
  final _heightController = TextEditingController(text: '2.80');
  final _maxMassController = TextEditingController(text: '3500');
  final _mileageController = TextEditingController(text: '0');
  final _steps = const [
    'locale',
    'vehicle',
    'location',
    'notifications',
    'guides',
    'checklist',
    'finish',
  ];

  OnboardingProgress _progress = OnboardingProgress.empty;
  String _localeCode = 'it';
  String _countryCode = 'IT';
  bool _grantLocation = false;
  bool _grantNotifications = false;
  bool _installChecklist = true;
  bool _selectEssentialGuide = true;
  bool _isLoading = true;
  bool _isFinishing = false;
  String? _status;

  int get _currentIndex {
    final current = _progress.currentStepId;
    if (current == null) return 0;
    final index = _steps.indexOf(current);
    return index == -1 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _maxMassController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final progress = await _service.loadProgress();
    if (!mounted) return;
    setState(() {
      _progress = progress.currentStepId == null && !progress.completed
          ? progress.copyWith(currentStepId: _steps.first)
          : progress;
      _localeCode = progress.localeCode ?? 'it';
      _countryCode = progress.countryCode ?? 'IT';
      _installChecklist = progress.installChecklist;
      _selectEssentialGuide = progress.selectedGuidePackageIds.contains(
        LocalOfflineGuidesService.bundledPackageId,
      );
      _isLoading = false;
    });
  }

  Future<void> _saveProgress({
    required String currentStepId,
    bool completed = false,
  }) async {
    final progress = _progress.copyWith(
      currentStepId: currentStepId,
      completed: completed,
      localeCode: _localeCode,
      countryCode: _countryCode,
      installChecklist: _installChecklist,
      selectedGuidePackageIds: _selectEssentialGuide
          ? {LocalOfflineGuidesService.bundledPackageId}
          : <String>{},
    );
    await _service.saveProgress(progress);
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  Future<void> _continue() async {
    final stepId = _steps[_currentIndex];
    switch (stepId) {
      case 'vehicle':
        await _service.saveVehicleDraft(
          vehicleType: _vehicleTypeController.text.trim().isEmpty
              ? 'Camper van'
              : _vehicleTypeController.text.trim(),
          length: double.tryParse(_lengthController.text.trim()) ?? 6,
          width: double.tryParse(_widthController.text.trim()) ?? 2.1,
          height: double.tryParse(_heightController.text.trim()) ?? 2.8,
          maxMass: double.tryParse(_maxMassController.text.trim()) ?? 3500,
          mileage: double.tryParse(_mileageController.text.trim()) ?? 0,
        );
      default:
        break;
    }
    await _service.completeStep(stepId);
    final nextIndex = (_currentIndex + 1).clamp(0, _steps.length - 1);
    await _saveProgress(currentStepId: _steps[nextIndex]);
  }

  Future<void> _skip() async {
    final stepId = _steps[_currentIndex];
    await _service.skipStep(stepId);
    final nextIndex = (_currentIndex + 1).clamp(0, _steps.length - 1);
    await _saveProgress(currentStepId: _steps[nextIndex]);
  }

  Future<void> _askLocation() async {
    final granted = await _service.requestLocationAccess();
    if (!mounted) return;
    setState(() {
      _grantLocation = granted;
      _status = granted
          ? 'Location permission granted.'
          : 'Location permission denied or unavailable.';
    });
  }

  Future<void> _askNotifications() async {
    final granted = await _service.requestNotificationAccess();
    if (!mounted) return;
    setState(() {
      _grantNotifications = granted;
      _status = granted
          ? 'Notification permission granted.'
          : 'Notification permission denied or unavailable.';
    });
  }

  Future<void> _finish() async {
    setState(() => _isFinishing = true);
    try {
      final completed = _progress.copyWith(
        completedStepIds: {..._progress.completedStepIds, ..._steps},
        selectedGuidePackageIds: _selectEssentialGuide
            ? {LocalOfflineGuidesService.bundledPackageId}
            : <String>{},
        installChecklist: _installChecklist,
        completed: true,
        clearCurrentStepId: true,
      );
      await _service.finalize(completed);
      if (!mounted) return;
      setState(() {
        _progress = completed;
        _status = 'Setup completed.';
      });
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ScreenScaffold(
      title: 'Guided onboarding',
      subtitle:
          'Configure the basics, ask permissions contextually, and confirm any offline install before it starts.',
      children: [
        PremiumCard(
          child: Material(
            color: Colors.transparent,
            child: Stepper(
              currentStep: _currentIndex,
              controlsBuilder: (_, __) => const SizedBox.shrink(),
              physics: const NeverScrollableScrollPhysics(),
              steps: [
                Step(
                  title: const Text('Language and country'),
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _localeCode,
                        items: const [
                          DropdownMenuItem(
                              value: 'it', child: Text('Italiano')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _localeCode = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        items: const [
                          DropdownMenuItem(value: 'IT', child: Text('Italia')),
                          DropdownMenuItem(value: 'EU', child: Text('Europa')),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _countryCode = value);
                        },
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 0,
                ),
                Step(
                  title: const Text('Vehicle basics'),
                  content: Column(
                    children: [
                      TextField(
                        controller: _vehicleTypeController,
                        decoration:
                            const InputDecoration(labelText: 'Vehicle type'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lengthController,
                              decoration: const InputDecoration(
                                  labelText: 'Length (m)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _widthController,
                              decoration:
                                  const InputDecoration(labelText: 'Width (m)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                  labelText: 'Height (m)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxMassController,
                              decoration: const InputDecoration(
                                  labelText: 'Max mass (kg)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mileageController,
                        decoration:
                            const InputDecoration(labelText: 'Current mileage'),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 1,
                ),
                Step(
                  title: const Text('Location permission'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask for location only when the user wants current-position search and weather.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _askLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(
                          _grantLocation ? 'Granted' : 'Explain and request',
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 2,
                ),
                Step(
                  title: const Text('Reminder permission'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask for notifications only if the user wants document and booking reminders.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _askNotifications,
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text(
                          _grantNotifications
                              ? 'Granted'
                              : 'Explain and request',
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 3,
                ),
                Step(
                  title: const Text('Guide packages'),
                  content: CheckboxListTile(
                    value: _selectEssentialGuide,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Install CamperBoss Essential'),
                    subtitle: const Text(
                      'Emergency basics and responsible overnight reminders.',
                    ),
                    onChanged: (value) =>
                        setState(() => _selectEssentialGuide = value ?? false),
                  ),
                  isActive: _currentIndex == 4,
                ),
                Step(
                  title: const Text('Initial checklist'),
                  content: CheckboxListTile(
                    value: _installChecklist,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Create a starter departure checklist'),
                    subtitle: const Text(
                      'Only written after final confirmation. Nothing downloads automatically.',
                    ),
                    onChanged: (value) =>
                        setState(() => _installChecklist = value ?? false),
                  ),
                  isActive: _currentIndex == 5,
                ),
                Step(
                  title: const Text('Final confirmation'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Language: ${_localeCode.toUpperCase()} / $_countryCode'),
                      Text(
                          'Guide package: ${_selectEssentialGuide ? 'CamperBoss Essential' : 'Not selected'}'),
                      Text(
                          'Checklist: ${_installChecklist ? 'Starter checklist will be created' : 'No checklist seed'}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Offline package installation starts only after this confirmation.',
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 6,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _currentIndex == _steps.length - 1 ? null : _skip,
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isFinishing
                    ? null
                    : _currentIndex == _steps.length - 1
                        ? _finish
                        : _continue,
                child: Text(
                  _isFinishing
                      ? 'Applying...'
                      : _currentIndex == _steps.length - 1
                          ? 'Finish setup'
                          : 'Continue',
                ),
              ),
            ),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          SectionHeader(title: 'Status'),
          const SizedBox(height: 8),
          PremiumCard(child: Text(_status!)),
        ],
      ],
    );
  }
}
