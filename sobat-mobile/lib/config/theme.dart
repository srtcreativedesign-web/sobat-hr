import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  // New Blue Identity
  static const Color colorPrimary = Color(0xFF1C3ECA); // Deep Blue (#1c3eca)
  static const Color colorSecondary = Color(0xFF60A5FA); // Soft Blue (#60a5fa)
  static const Color colorTertiary = Color(
    0xFF93C5FD,
  ); // Lighter Blue (#93c5fd)

  static const Color backgroundLight = Color(
    0xFFFAFDFF,
  ); // Pale Blueish White (#fafdff)
  static const Color textDark = Color(0xFF1F2937); // Standard Dark Text
  static const Color textLight = Color(0xFF64748B); // Slate 500

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // -- Attendance Gradients --
  // 1. Default / Belum Hadir (Soft Blue Gradient)
  static const List<Color> gradientDefault = [
    Color(0xFF60A5FA), // Soft Blue
    Color(0xFF93C5FD), // Light Blue
  ];

  // 2. Working / Sedang Bekerja (Deep Blue Gradient)
  static const List<Color> gradientWorking = [
    Color(0xFF1C3ECA), // Deep Blue
    Color(0xFF4F70E6), // Slightly Lighter Deep Blue
  ];

  // 3. Finished / Sudah Selesai (Emerald/Green as before, or mixed?)
  // Keep Green for differentiation
  static const List<Color> gradientFinished = [
    Color(0xFF34D399),
    Color(0xFF6EE7B7),
  ];

  // Helper alias to avoid breaking code that uses colorCyan/colorEggplant
  // Mapping old names to new palette for compatibility
  static const Color colorCyan = colorSecondary;
  static const Color colorEggplant = colorPrimary;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: colorPrimary,
        secondary: colorSecondary,
        surface: Colors.white,
        error: error,
        tertiary: colorTertiary,
      ),
      scaffoldBackgroundColor: backgroundLight,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: colorPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorPrimary,
        ),
        iconTheme: const IconThemeData(color: colorPrimary),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textDark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100 — soft grey fill
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorSecondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: textLight),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textLight),
        floatingLabelStyle: TextStyle(
          color: colorPrimary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textLight,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
    );
  }
}
