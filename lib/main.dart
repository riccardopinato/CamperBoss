import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
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
      child: const CamperBossApp(),
    ),
  );
}

class CamperBossApp extends StatelessWidget {
  const CamperBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamperBoss',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const AppShell(),
    );
  }
}
