import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/app_system_services.dart';
import 'core/services/restore_recovery_bootstrap.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: RestoreRecoveryGate(),
      ),
    ),
  );
}

class RestoreRecoveryGate extends StatefulWidget {
  const RestoreRecoveryGate({super.key});

  @override
  State<RestoreRecoveryGate> createState() => _RestoreRecoveryGateState();
}

class _RestoreRecoveryGateState extends State<RestoreRecoveryGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    // Native recovery completes before any product surface can read canonical
    // data. Web uses a no-op bootstrap.
    await recoverInterruptedRestoreIfNeeded();
    await AppSystemServices.instance.initialize();
  }

  void _retry() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              appBar: AppBar(title: Text('backup_title'.tr())),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restore_page_outlined, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'backup_failed_safe'.tr(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const CamperBossApp();
      },
    );
  }
}

class CamperBossApp extends StatelessWidget {
  const CamperBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = context.locale.toLanguageTag();
    return MaterialApp(
      title: 'CamperBoss',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      initialRoute: '/',
      routes: camperBossRoutes(),
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const AppShell(),
      ),
    );
  }
}
