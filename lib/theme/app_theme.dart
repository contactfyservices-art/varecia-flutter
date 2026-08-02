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

/// Transitions douces (fondu + léger glissement) entre chaque page,
/// appliquées automatiquement partout dans l'appli.
final _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: const _FadeSlideTransitionsBuilder(),
    TargetPlatform.iOS: const _FadeSlideTransitionsBuilder(),
  },
);

class _FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.canopy,
        secondary: AppColors.clay,
        background: AppColors.cream,
        onBackground: AppColors.ink,
        onSurface: AppColors.ink,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700, color: AppColors.forest),
        headlineMedium: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.forest),
        titleLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.forest),
        bodyLarge: const TextStyle(color: AppColors.ink),
        bodyMedium: const TextStyle(color: AppColors.ink),
        bodySmall: TextStyle(color: AppColors.ink.withOpacity(0.65)),
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
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: AppColors.forest,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.leaf,
        secondary: AppColors.clay,
        background: AppColors.forest,
        onBackground: AppColors.cream,
        onSurface: AppColors.cream,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700, color: AppColors.cream),
        headlineMedium: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.cream),
        titleLarge: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600, color: AppColors.cream),
        // Contraste corrigé : texte clair garanti sur fond sombre,
        // au lieu de dépendre des couleurs par défaut de Flutter.
        bodyLarge: const TextStyle(color: AppColors.cream),
        bodyMedium: const TextStyle(color: AppColors.cream),
        bodySmall: TextStyle(color: AppColors.cream.withOpacity(0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leaf,
          foregroundColor: AppColors.forest,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
