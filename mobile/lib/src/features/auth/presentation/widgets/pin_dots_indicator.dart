import 'package:flutter/material.dart';

const int kPinLength = 4;

/// Row of filled/empty circles representing PIN entry progress.
/// Pass a positive [shakeTick] each time you want it to play the
/// "wrong PIN" shake — any change to the value re-triggers the animation.
class PinDotsIndicator extends StatefulWidget {
  final int filledCount;
  final int shakeTick;

  const PinDotsIndicator({
    super.key,
    required this.filledCount,
    this.shakeTick = 0,
  });

  @override
  State<PinDotsIndicator> createState() => _PinDotsIndicatorState();
}

class _PinDotsIndicatorState extends State<PinDotsIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant PinDotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTick != oldWidget.shakeTick && widget.shakeTick != 0) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(kPinLength, (index) {
          final isFilled = index < widget.filledCount;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? const Color(0xFFACEC87) : Colors.transparent,
              border: Border.all(
                color: isFilled ? const Color(0xFFACEC87) : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }
}
