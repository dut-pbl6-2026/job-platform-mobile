import 'package:flutter/material.dart';

/// App color palette - Professional blue tones for job platform
class AppColors {
  AppColors._();

  // Primary colors (Figma canonical blue)
  static const Color primary = Color(0xFF0085FF);
  static const Color primaryLight = Color(0xFFE8F2FF);
  static const Color primaryDark = Color(0xFF0768E1);

  // Secondary / Accent
  static const Color secondary = Color(0xFF21996E);
  static const Color secondaryLight = Color(0xFFE6F7F0);
  static const Color accentLime = Color(0xFFDDFF7E);

  // Background & Surface
  static const Color background = Color(0xFFF3F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5FAFF);
  static const Color searchSurface = Color(0xFFF7F9FC);
  static const Color darkSurface = Color(0xFF202939);

  // Text
  static const Color textPrimary = Color(0xFF1F2B42);
  static const Color textSecondary = Color(0xFF63718A);
  static const Color textHint = Color(0xFF9AA4B2);

  // State colors
  static const Color error = Color(0xFFE30A17);
  static const Color success = Color(0xFF21996E);
  static const Color warning = Color(0xFFFFA726);

  // Border & Divider
  static const Color border = Color(0xFFE3E9F0);
  static const Color divider = Color(0xFFEBF0F5);
}

/// Dimensions measured from the canonical mobile Figma frames.
class AppDimensions {
  AppDimensions._();

  static const double screenPadding = 20;
  static const double searchHeight = 46;
  static const double bannerHeight = 69;
  static const double shortcutHeight = 86;
  static const double compactJobHeight = 100;
  static const double navigationHeight = 74;
}

/// App Theme - Material 3 Light Theme (default per SRS 7.2.2)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // Bundled Roboto supports Vietnamese and offline rendering.
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['NotoSymbols'],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: ['NotoSymbols'],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: ['NotoSymbols'],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: ['NotoSymbols'],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 14,
          color: AppColors.textHint,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        errorStyle: TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['NotoSymbols'],
          fontSize: 12,
          color: AppColors.error,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
