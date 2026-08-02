import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Panneau "aeroglass" réutilisable partout dans l'appli :
/// fond flouté, bordure lumineuse en dégradé, ombres multicouches
/// pour donner un effet de profondeur (3D léger).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Ombre large et douce = effet "flottant"
          BoxShadow(
            color: AppColors.forest.withOpacity(isDark ? 0.35 : 0.16),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
          // Ombre resserrée = donne du relief proche du bord
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.55),
                        AppColors.forest.withOpacity(0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.white).withOpacity(
                  isDark ? 0.18 : 0.6,
                ),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fond dégradé animé lent type "canopée" utilisé derrière les écrans
/// d'authentification et l'accueil.
class CanopyBackground extends StatelessWidget {
  final Widget child;
  const CanopyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forest,
                  AppColors.canopy.withOpacity(0.85),
                  AppColors.leaf.withOpacity(0.55),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
