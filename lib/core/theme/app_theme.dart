import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColors.daySurface;
    final background = isDark ? AppColors.night : AppColors.day;
    final navigationBackground =
        isDark ? AppColors.charcoal : AppColors.daySurface;
    final onSurface = isDark ? AppColors.text : AppColors.dayText;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: brightness,
      primary: isDark ? AppColors.moss : AppColors.forest,
      secondary: AppColors.gold,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: navigationBackground,
        indicatorColor: isDark
            ? AppColors.forest.withValues(alpha: 0.56)
            : AppColors.daySurfaceSoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceSoft : AppColors.daySurfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
