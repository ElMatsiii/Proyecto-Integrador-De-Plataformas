import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema de la app inspirado en la identidad visual de la UCN.
/// Azul institucional y acentos tierra/desierto del manual UCN.
class AppTheme {
  AppTheme._();

  static ColorScheme _lightScheme() => ColorScheme.fromSeed(
        seedColor: AppColors.seedBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.seedBlue,
        onPrimary: Colors.white,
        secondary: AppColors.terracotta,
        tertiary: AppColors.teal,
        surface: AppColors.lightSurface,
        error: AppColors.ucnRed,
        outline: AppColors.outline,
      );

  static ColorScheme _darkScheme() => ColorScheme.fromSeed(
        seedColor: AppColors.seedBlue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFA9C7FF),
        onPrimary: const Color(0xFF00305F),
        secondary: const Color(0xFFE0A56B),
        tertiary: const Color(0xFF7FD0DF),
        surface: AppColors.darkSurface,
        error: const Color(0xFFFFB4AB),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme(),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: GoogleFonts.sourceSans3TextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme(),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.sourceSans3TextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
