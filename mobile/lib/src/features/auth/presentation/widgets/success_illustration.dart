import 'package:flutter/material.dart';

/// Animated hero for success screens: the illustration eases in with a
/// gentle overshoot, a soft "breathing" halo glows behind it on loop,
/// and a checkmark badge bounces in once the illustration has settled.
/// Deliberately restrained — no confetti, just enough motion to feel alive.
class SuccessIllustration extends StatefulWidget {
  final String assetPath;
  final double height;

  const SuccessIllustration({
    super.key,
    required this.assetPath,
    this.height = 220,
  });

  @override
  State<SuccessIllustration> createState() => _SuccessIllustrationState();
}

class _SuccessIllustrationState extends State<SuccessIllustration> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final illustrationFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    final illustrationScale = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack));
    final badgeScale = CurvedAnimation(parent: _entrance, curve: const Interval(0.55, 1.0, curve: Curves.elasticOut));

    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _pulse]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Slow breathing halo behind the illustration.
            Opacity(
              opacity: 0.5 + (_pulse.value * 0.2),
              child: Transform.scale(
                scale: 1 + (_pulse.value * 0.05),
                child: Container(
                  width: widget.height,
                  height: widget.height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC8E6A0).withValues(alpha: 0.4),
                        const Color(0xFFACEC87).withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: illustrationFade.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.85 + (illustrationScale.value * 0.15),
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                  height: widget.height,
                ),
              ),
            ),
            Positioned(
              bottom: widget.height * 0.06,
              right: widget.height * 0.1,
              child: Transform.scale(
                scale: badgeScale.value < 0 ? 0.0 : badgeScale.value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFACEC87),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF1D3108), size: 20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
