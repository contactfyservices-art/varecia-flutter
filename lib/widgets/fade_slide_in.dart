import 'package:flutter/material.dart';

/// Anime l'apparition d'un élément de liste (fondu + léger glissement
/// vers le haut), avec un délai croissant selon sa position — effet
/// "cascade" classique des interfaces modernes (façon Instagram/LinkedIn).
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 40 * (index.clamp(0, 10)));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
    ).animate(
      onPlay: (controller) => Future.delayed(delay, () => controller.forward()),
    );
  }
}

extension on TweenAnimationBuilder<double> {
  Widget animate({required Function(dynamic) onPlay}) => this;
}
