import 'package:flutter/material.dart';

class AppColors {
  // Cozy Dark Palette
  static const Color darkGray = Color(0xFF121212);
  static const Color lightGray = Color(0xFF1E1E1E);
  static const Color neonBlue = Color(0xFF4FC3F7);
  static const Color alertRed = Color(0xFFFF6B6B);
  static const Color warningYellow = Color(0xFFFFD166);
  static const Color safeGreen = Color(0xFF6BCB77);
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFFB0B0B0);
}

class AegisTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkGray,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGray,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.neonBlue),
        titleTextStyle: TextStyle(
          color: AppColors.neonBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonBlue,
        secondary: AppColors.safeGreen,
        error: AppColors.alertRed,
        background: AppColors.darkGray,
        surface: AppColors.lightGray,
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightGray,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColors.neonBlue,
          foregroundColor: AppColors.darkGray,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.neonBlue,
      ),

      dividerColor: AppColors.lightGray,

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.lightGray,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}