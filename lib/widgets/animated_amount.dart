import 'package:costing_master/domain/money.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// A rupee amount that counts smoothly to its new value whenever it changes.
class AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final int decimals;
  final bool gujaratiDigits;
  final TextAlign? textAlign;

  const AnimatedAmount(
    this.value, {
    super.key,
    this.style,
    this.decimals = 2,
    this.gujaratiDigits = false,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.decelerate,
      builder: (context, animated, _) => Text(
        formatRupees(animated,
            decimals: decimals, gujaratiDigits: gujaratiDigits),
        style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()]) ??
            const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
