import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double height;
  final double borderRadius;
  const ShimmerLoading({super.key, this.height = 90, this.borderRadius = 16});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _ctrl.value * 2, 0),
              end: Alignment(1 + _ctrl.value * 2, 0),
              colors: [
                Colors.grey.withOpacity(0.15),
                Colors.grey.withOpacity(0.35),
                Colors.grey.withOpacity(0.15),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) => const ShimmerLoading()),
    );
  }
}
