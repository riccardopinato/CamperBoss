import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const CamperBossApp());
}

class CamperBossApp extends StatelessWidget {
  const CamperBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamperBoss',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}
