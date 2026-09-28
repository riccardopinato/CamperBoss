import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/subscription_service.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    this.service,
    super.key,
  });

  final SubscriptionService? service;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final SubscriptionService _service =
      widget.service ?? RevenueCatSubscriptionService();

  ProSubscriptionState? _state;
  bool _loading = true;
  String? _error;
  String? _busyPackage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await _service.load();
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
      });
    } on SubscriptionFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'pro_error_generic'.tr();
      });
    }
  }

  Future<void> _purchase(ProPackage package) async {
    if (_busyPackage != null) return;
    setState(() {
      _busyPackage = package.identifier;
      _error = null;
    });

    try {
      final state = await _service.purchase(package.identifier);
      if (!mounted) return;
      setState(() => _state = state);
    } on SubscriptionFailure catch (error) {
      if (!mounted) return;
      if (!error.cancelled) {
        setState(() => _error = _localizeServiceMessage(error.message));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'pro_error_generic'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _busyPackage = null);
      }
    }
  }

  Future<void> _restore() async {
    if (_busyPackage != null) return;
    setState(() {
      _busyPackage = '__restore__';
      _error = null;
    });
    try {
      final state = await _service.restore();
      if (!mounted) return;
      setState(() => _state = state);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.isPro ? 'pro_restore_success'.tr() : 'pro_restore_empty'.tr(),
          ),
        ),
      );
    } on SubscriptionFailure catch (error) {
      if (mounted) {
        setState(() => _error = _localizeServiceMessage(error.message));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'pro_error_generic'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _busyPackage = null);
      }
    }
  }

  String _localizeServiceMessage(String message) {
    return switch (message) {
      'revenuecat_not_configured' => 'pro_not_configured'.tr(),
      'revenuecat_package_unavailable' => 'pro_package_unavailable'.tr(),
      'revenuecat_purchase_cancelled' => 'pro_purchase_cancelled'.tr(),
      'revenuecat_restore_web_unavailable' =>
        'pro_restore_web_unavailable'.tr(),
      _ => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return Scaffold(
      appBar: AppBar(title: Text('subscription_title'.tr())),
      body: ScreenScaffold(
        title: 'pro_title'.tr(),
        subtitle: 'pro_subtitle'.tr(),
        children: [
          PremiumCard(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProBadge(
                  label: state?.isPro == true
                      ? 'pro_active_badge'.tr()
                      : 'pro_badge'.tr(),
                ),
                const SizedBox(height: 16),
                Text(
                  state?.isPro == true
                      ? 'pro_active_title'.tr()
                      : 'pro_pitch_title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  state?.isPro == true
                      ? 'pro_active_body'.tr()
                      : 'pro_pitch_body'.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            PremiumCard(
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (state?.isPro == true) ...[
            PremiumCard(
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text('pro_entitlement_active'.tr())),
                ],
              ),
            ),
          ] else if (state?.isConfigured != true) ...[
            PremiumCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text('pro_not_configured'.tr())),
                ],
              ),
            ),
          ] else if (state!.packages.isEmpty) ...[
            PremiumCard(child: Text('pro_no_offerings'.tr())),
          ] else ...[
            for (final package in state.packages) ...[
              _PackageCard(
                package: package,
                busy: _busyPackage == package.identifier,
                disabled: _busyPackage != null,
                onPurchase: () => _purchase(package),
              ),
              const SizedBox(height: 12),
            ],
            TextButton.icon(
              onPressed: _busyPackage == null ? _restore : null,
              icon: _busyPackage == '__restore__'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text('pro_restore'.tr()),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'pro_store_notice'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.busy,
    required this.disabled,
    required this.onPurchase,
  });

  final ProPackage package;
  final bool busy;
  final bool disabled;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (package.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(package.description),
                ],
                const SizedBox(height: 8),
                Text(
                  package.price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: disabled ? null : onPurchase,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('pro_choose'.tr()),
          ),
        ],
      ),
    );
  }
}
