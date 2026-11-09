import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeritoryColors {
  // Brand Colors
  static const Color primary = Color(0xFFFF5330); // Territory Coral / Orange
  static const Color primaryLight = Color(0xFFFFEFEB);
  static const Color primaryDark = Color(0xFFD63B19);

  // Wonder / Major Flag Gold
  static const Color majorGold = Color(0xFFF59E0B);
  static const Color majorGoldLight = Color(0xFFFEF3C7);
  static const Color majorGoldDark = Color(0xFFB45309);

  // Surface & Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A); // Midnight Navy
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Accents
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color sapphireBlue = Color(0xFF3B82F6);
  static const Color royalPurple = Color(0xFF8B5CF6);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}

class TeritoryTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: TeritoryColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TeritoryColors.primary,
        primary: TeritoryColors.primary,
        secondary: TeritoryColors.majorGold,
        surface: TeritoryColors.surface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: TeritoryColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: TeritoryColors.textPrimary),
      ),
    );
  }
}
