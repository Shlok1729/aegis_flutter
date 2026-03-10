import 'package:flutter/material.dart';

class AppColors {
  static const Color darkGray = Color(0xFF121212);
  static const Color lightGray = Color(0xFF2D2D2D);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color alertRed = Color(0xFFFF1744);
  static const Color warningYellow = Color(0xFFFFEA00);
  static const Color safeGreen = Color(0xFF00E676);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
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
