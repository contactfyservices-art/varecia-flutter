import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette forêt tropicale de l'Association Varecia
class AppColors {
  static const forest = Color(0xFF173A2E);
  static const canopy = Color(0xFF2D6A4F);
  static const leaf = Color(0xFF82C6A6);
  static const clay = Color(0xFFBB6B3C);
  static const cream = Color(0xFFF6F1E4);
  static const ink = Color(0xFF17211C);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.canopy,
        secondary: AppColors.clay,
        background: AppColors.cream,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700, color: AppColors.forest),
        headlineMedium: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.forest),
        titleLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.forest),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.canopy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.forest,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.leaf,
        secondary: AppColors.clay,
        background: AppColors.forest,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700, color: AppColors.cream),
        headlineMedium: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.cream),
        titleLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.cream),
      ),
    );
  }
}
