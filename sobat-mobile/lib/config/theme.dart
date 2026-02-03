import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  // Swapped: Primary is now Cyan, Secondary is now Dark Eggplant
  static const Color colorCyan = Color(
    0xFFA9EAE2,
  ); // Was secondary, now Primary
  static const Color colorEggplant = Color(
    0xFF462E37,
  ); // Was primary, now Secondary
  static const Color tertiarySage = Color(0xFF729892); // Web Admin Gradient End

  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF4B5563); // Darkened from 0xFF6B7280

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // -- Attendance Gradients (Softer/Pastel) --
  // 1. Default / Belum Hadir (Cyan like Navbar)
  static const List<Color> gradientDefault = [
    Color(0xFFA9EAE2), // Cyan Primary
    Color(0xFF86D6CC), // Slightly darker cyan for gradient
  ];

  // 2. Working / Sedang Bekerja (Soft Blue)
  static const List<Color> gradientWorking = [
    Color(0xFF60A5FA), // Blue 400
    Color(0xFF93C5FD), // Blue 300
  ];

  // 3. Finished / Sudah Selesai (Soft Sage/Emerald)
  static const List<Color> gradientFinished = [
    Color(0xFF34D399), // Emerald 400
    Color(0xFF6EE7B7), // Emerald 300
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: colorCyan, // SWAPPED
        secondary: colorEggplant, // SWAPPED
        surface: Colors.white,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundLight,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorCyan, // SWAPPED
        foregroundColor: colorEggplant, // SWAPPED
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorEggplant, // SWAPPED
        ),
        iconTheme: const IconThemeData(color: colorEggplant), // SWAPPED
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
          backgroundColor: colorCyan, // SWAPPED
          foregroundColor: colorEggplant, // SWAPPED
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: colorCyan, width: 2), // SWAPPED
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: textLight),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textLight),
        floatingLabelStyle: const TextStyle(color: colorCyan), // SWAPPED
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        color: Colors.white,
      ),
    );
  }
}
