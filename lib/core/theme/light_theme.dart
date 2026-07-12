import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class LightTheme {
  LightTheme._();

  static ThemeData get theme {
    final colorScheme = ColorScheme.light(
      primary: AppConstants.primaryGreen,
      secondary: AppConstants.primaryAccent,
      tertiary: AppConstants.fareAmber,
      error: AppConstants.errorRed,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A2E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.backgroundLight,

      // Typography
      textTheme: GoogleFonts.hindSiliguriTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.hindSiliguri(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.hindSiliguri(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.hindSiliguri(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.hindSiliguri(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.hindSiliguri(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.hindSiliguri(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withValues(alpha: 0.7),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
