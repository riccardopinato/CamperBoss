import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/offline_guides_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../data/models/guide_models.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_screen.dart';

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
  String _localeCode = 'en';
  String _countryCode = 'EU';
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

  Future<void> _load() async {
    try {
      final progress = await _service.loadProgress();
      if (!mounted) return;
      final deviceCode = context.locale.languageCode;
      setState(() {
        _progress = progress.currentStepId == null && !progress.completed
            ? progress.copyWith(currentStepId: _steps.first)
            : progress;
        _localeCode = progress.localeCode ?? deviceCode;
        _countryCode = progress.countryCode ?? 'EU';
        _installChecklist = progress.installChecklist;
        _selectEssentialGuide = progress.selectedGuidePackageIds.contains(
          LocalOfflineGuidesService.bundledPackageId,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = 'setup_error_load'.tr();
      });
    }
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
          ? 'setup_location_granted'.tr()
          : 'setup_location_denied'.tr();
    });
  }

  Future<void> _askNotifications() async {
    final granted = await _service.requestNotificationAccess();
    if (!mounted) return;
    setState(() {
      _grantNotifications = granted;
      _status = granted
          ? 'setup_notifications_granted'.tr()
          : 'setup_notifications_denied'.tr();
    });
  }

  Future<void> _openVehicleProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
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
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'setup_error_finish'.tr());
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
      title: 'setup_title'.tr(),
      subtitle: 'setup_subtitle'.tr(),
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
                  title: Text('setup_language_country'.tr()),
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _localeCode,
                        items: [
                          DropdownMenuItem(value: 'en', child: Text('language_english'.tr())),
                          DropdownMenuItem(value: 'it', child: Text('language_italian'.tr())),
                          DropdownMenuItem(value: 'de', child: Text('language_german'.tr())),
                          DropdownMenuItem(value: 'fr', child: Text('language_french'.tr())),
                          DropdownMenuItem(value: 'es', child: Text('language_spanish'.tr())),
                          DropdownMenuItem(value: 'pt', child: Text('language_portuguese'.tr())),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _localeCode = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        items: [
                          DropdownMenuItem(value: 'IT', child: Text('setup_country_italy'.tr())),
                          DropdownMenuItem(value: 'EU', child: Text('setup_country_europe'.tr())),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _countryCode = value);
                        },
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 0,
                ),
                Step(
                  title: Text('setup_vehicle'.tr()),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('setup_vehicle_body'.tr()),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _openVehicleProfile,
                        icon: const Icon(Icons.directions_bus_outlined),
                        label: Text('setup_vehicle_open'.tr()),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 1,
                ),
                Step(
                  title: Text('setup_location'.tr()),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('setup_location_body'.tr()),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _askLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(
                          _grantLocation
                              ? 'permission_granted'.tr()
                              : 'permission_explain_request'.tr(),
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 2,
                ),
                Step(
                  title: Text('setup_notifications'.tr()),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('setup_notifications_body'.tr()),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _askNotifications,
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text(
                          _grantNotifications
                              ? 'permission_granted'.tr()
                              : 'permission_explain_request'.tr(),
                        ),
                      ),
                    ],
                  ),
                  isActive: _currentIndex == 3,
                ),
                Step(
                  title: Text('setup_guides'.tr()),
                  content: CheckboxListTile(
                    value: _selectEssentialGuide,
                    contentPadding: EdgeInsets.zero,
                    title: Text('setup_guides_install'.tr()),
                    subtitle: Text('setup_guides_body'.tr()),
                    onChanged: (value) =>
                        setState(() => _selectEssentialGuide = value ?? false),
                  ),
                  isActive: _currentIndex == 4,
                ),
                Step(
                  title: Text('setup_checklist'.tr()),
                  content: CheckboxListTile(
                    value: _installChecklist,
                    contentPadding: EdgeInsets.zero,
                    title: Text('setup_checklist_create'.tr()),
                    subtitle: Text('setup_checklist_body'.tr()),
                    onChanged: (value) =>
                        setState(() => _installChecklist = value ?? false),
                  ),
                  isActive: _currentIndex == 5,
                ),
                Step(
                  title: Text('setup_confirmation'.tr()),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('setup_summary_language'.tr(
                        namedArgs: {
                          'language': _localeCode.toUpperCase(),
                          'country': _countryCode,
                        },
                      )),
                      Text(
                        _selectEssentialGuide
                            ? 'setup_summary_guide_yes'.tr()
                            : 'setup_summary_guide_no'.tr(),
                      ),
                      Text(
                        _installChecklist
                            ? 'setup_summary_checklist_yes'.tr()
                            : 'setup_summary_checklist_no'.tr(),
                      ),
                      const SizedBox(height: 12),
                      Text('setup_confirmation_body'.tr()),
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
                child: Text('skip'.tr()),
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
                      ? 'setup_applying'.tr()
                      : _currentIndex == _steps.length - 1
                          ? 'setup_finish'.tr()
                          : 'continue'.tr(),
                ),
              ),
            ),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          SectionHeader(title: 'status'.tr()),
          const SizedBox(height: 8),
          PremiumCard(child: Text(_status!)),
        ],
      ],
    );
  }
}
