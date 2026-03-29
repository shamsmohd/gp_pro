import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF8F7FB);
  static const Color primary = Color(0xFF6C3CCF);
  static const Color border = Color(0xFFD9D9D9);
  static const Color textGray = Color(0xFF7C7C7C);
  static const Color icon = Color(0xFF666666);
  static const Color danger = Color(0xFFB3261E);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E22);
  static const Color darkCardSoft = Color(0xFF26262B);
  static const Color darkBorder = Color(0xFF35353B);
  static const Color darkTextGray = Color(0xFFB0B0B8);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    surface: Colors.white,
    error: AppColors.danger,
  ),
  cardColor: Colors.white,
  dividerColor: AppColors.border,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.black,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(color: AppColors.black),
    bodyMedium: TextStyle(color: AppColors.black),
    bodySmall: TextStyle(color: AppColors.textGray),
  ),
);

final ThemeData darkAppTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppColors.darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    surface: AppColors.darkCard,
    error: AppColors.danger,
  ),
  cardColor: AppColors.darkCard,
  dividerColor: AppColors.darkBorder,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: AppColors.darkTextGray),
  ),
);