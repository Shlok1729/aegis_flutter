import 'package:flutter/material.dart';

class AppColors {
static const Color darkGray = Color(0xFFF5F5F5);
static const Color lightGray = Color(0xFFE0E0E0);
static const Color neonBlue = Color(0xFF2979FF);
static const Color alertRed = Color(0xFFE53935);
static const Color warningYellow = Color(0xFFFFC107);
static const Color safeGreen = Color(0xFF43A047);
static const Color textPrimary = Color(0xFF212121);
static const Color textSecondary = Color(0xFF757575);
}

class AegisTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGray,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.neonBlue),
        titleTextStyle: TextStyle(
          color: AppColors.neonBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonBlue,
          foregroundColor: AppColors.darkGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
