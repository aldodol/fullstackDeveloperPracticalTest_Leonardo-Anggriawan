import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF4F46E5);      // Indigo 600
  static const Color primaryDark = Color(0xFF4338CA);  // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  
  static const Color secondary = Color(0xFF0F172A);    // Slate 900
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);   // Slate 50
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color warningLight = Color(0xFFFFFBEB); // Amber 50
  static const Color danger = Color(0xFFEF4444);       // Red 500
  static const Color dangerLight = Color(0xFFFEF2F2);  // Red 50
  static const Color info = Color(0xFF3B82F6);         // Blue 500
  static const Color infoLight = Color(0xFFEFF6FF);    // Blue 50

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);   // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0);        // Slate 200

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
