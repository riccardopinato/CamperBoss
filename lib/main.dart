import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/app_system_services.dart';
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
      child: const ProviderScope(child: CamperBossApp()),
    ),
  );

  unawaited(AppSystemServices.instance.initialize());
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
