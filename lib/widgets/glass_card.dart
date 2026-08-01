import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Panneau "aeroglass" réutilisable partout dans l'appli :
/// fond flouté, bordure fine lumineuse, ombre douce.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.blur = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : AppColors.forest)
                .withOpacity(isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (isDark ? Colors.white : AppColors.canopy)
                  .withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
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
