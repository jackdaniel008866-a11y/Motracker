// Motracker — App Theme

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================
  // Color Palette
  // ============================================
  
  // Primary colors
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color surfaceDark = Color(0xFF1B2838);
  static const Color cardDark = Color(0xFF233044);
  static const Color cardDarkAlt = Color(0xFF2A3A52);
  
  // Accent colors
  static const Color accent = Color(0xFF00D09C); // Emerald green
  static const Color accentLight = Color(0xFF00E6AC);
  static const Color accentDark = Color(0xFF00B386);
  
  // Semantic colors
  static const Color income = Color(0xFF00D09C); // Green
  static const Color expense = Color(0xFFFF6B6B); // Red/coral
  static const Color warning = Color(0xFFFFBE0B); // Amber
  static const Color info = Color(0xFF4CC9F0); // Sky blue
  
  // Text colors
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);
  
  // ============================================
  // Theme Data
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: primaryDark,
        secondary: accentLight,
        onSecondary: primaryDark,
        surface: surfaceDark,
        onSurface: textPrimary,
        error: expense,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: primaryDark,
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
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
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: expense, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: primaryDark,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        elevation: 0,
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A3A52),
        thickness: 1,
        space: 0,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  // ============================================
  // Glassmorphism Decoration
  // ============================================
  
  static BoxDecoration get glassCard => BoxDecoration(
    color: cardDark.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get glassCardAccent => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: 0.15),
        accent.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: accent.withValues(alpha: 0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration incomeGradientCard() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        income.withValues(alpha: 0.15),
        income.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: income.withValues(alpha: 0.2),
      width: 1,
    ),
  );

  static BoxDecoration expenseGradientCard() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        expense.withValues(alpha: 0.15),
        expense.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: expense.withValues(alpha: 0.2),
      width: 1,
    ),
  );
}
