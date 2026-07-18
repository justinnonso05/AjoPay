import 'package:flutter/material.dart';

/// Fades and slides [child] upward into place. Multiple instances can
/// share one [controller] with different [start]/[end] windows to
/// stagger a sequence of elements off a single animation run.
class FadeSlideIn extends StatelessWidget {
  final Animation<double> controller;
  final double start;
  final double end;
  final double distance;
  final Widget child;

  const FadeSlideIn({
    super.key,
    required this.controller,
    required this.child,
    this.start = 0,
    this.end = 1,
    this.distance = 20,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * distance),
            child: child,
          ),
        );
      },
    );
  }
}
