import 'package:flutter/material.dart';

abstract final class AppColors {
  static const green = Color(0xFF24734A);
  static const greenDark = Color(0xFF185A38);
  static const greenPastel = Color(0xFFE5F3E8);
  static const greenPale = Color(0xFFF3F8F2);
  static const ink = Color(0xFF1F3328);
  static const muted = Color(0xFF66766B);
  static const canvas = Color(0xFFF7FAF6);
  static const white = Color(0xFFFFFFFF);
}

abstract final class AppTheme {
  /// Construye el tema compartido; main.dart lo aplica al MaterialApp.
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green,
      onPrimary: AppColors.white,
      secondary: AppColors.greenDark,
      onSecondary: AppColors.white,
      error: Color(0xFFB3261E),
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shadowColor: AppColors.greenDark.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7EEE7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greenPale,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1EAE1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.green,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.greenDark,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.green),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greenPale,
        selectedColor: AppColors.green,
        secondarySelectedColor: AppColors.green,
        labelStyle: const TextStyle(color: AppColors.ink),
        secondaryLabelStyle: const TextStyle(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFDCE9DD)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.greenDark,
        contentTextStyle: const TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textTheme: const TextTheme(
        headlineSmall:
            TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        titleLarge:
            TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: AppColors.ink, height: 1.45),
        bodySmall: TextStyle(color: AppColors.muted),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.green),
    );
  }
}
