import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// The logo keeps its own gold whatever app theme is chosen.
const brandGold = Color(0xFFC9A227);

/// The app's Gujarati monogram: a gold-edged, rounded diamond carrying "કો",
/// filled with the theme's hero colours.
///
/// Drawn in code so it stays crisp at any size and costs no asset bytes; the
/// launcher icons are rendered from it too (see `tool/render_icons_test.dart`).
/// With [animate], the mark pops in, its edge traces itself, the letters
/// rise and a light sweeps across, in under a second.
class BrandMark extends StatefulWidget {
  final double size;
  final bool animate;

  const BrandMark({super.key, this.size = 96, this.animate = false});

  /// Length of the [animate] sequence.
  static const animationDuration = Duration(milliseconds: 900);

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BrandMark.animationDuration,
    value: widget.animate ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate && !_controller.isAnimating && _controller.value == 0) {
      if (Motion.of(context, Motion.slow) == Duration.zero) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: BrandMarkPainter(
              progress: _controller.value,
              fill: context.brand,
              fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the brand mark at animation [progress] (1 is the finished mark).
///
/// With [fill] null it draws only the outline and letters in [gold]: the
/// one-colour layer Android tints for themed launcher icons.
class BrandMarkPainter extends CustomPainter {
  final double progress;
  final Color gold;
  final BrandColors? fill;
  final String? fontFamily;

  const BrandMarkPainter({
    this.progress = 1,
    this.gold = brandGold,
    required this.fill,
    this.fontFamily,
  });

  /// [progress] within the part of the timeline from [begin] to [end].
  double _phase(double begin, double end, Curve curve) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final fill = this.fill;

    // Pops in slightly larger than its final size and settles.
    final pop = _phase(0, 0.45, Curves.easeOutBack);
    final scale = 0.85 + 0.15 * pop;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..scale(scale)
      ..translate(-c.dx, -c.dy);

    final outer = _roundedDiamond(c, s * 0.47, s * 0.09);
    if (fill != null) {
      final fillIn = _phase(0, 0.3, Curves.easeOut);
      canvas.drawPath(
        outer,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(c.dx - s / 2, c.dy - s / 2),
            Offset(c.dx + s / 2, c.dy + s / 2),
            [
              fill.heroEnd.withValues(alpha: fillIn),
              fill.heroStart.withValues(alpha: fillIn),
            ],
          ),
      );
      // A soft highlight on the upper half, like light on a cut stone.
      canvas.drawPath(
        outer,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(c.dx, c.dy - s / 2),
            c,
            [
              Colors.white.withValues(alpha: 0.16 * fillIn),
              Colors.white.withValues(alpha: 0),
            ],
          ),
      );
    }

    // The gold edge traces itself around the diamond.
    final trace = _phase(0.1, 0.65, Curves.easeInOutCubic);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = gold;
    if (trace >= 1) {
      canvas.drawPath(outer, edge);
    } else if (trace > 0) {
      for (final metric in outer.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * trace), edge);
      }
    }

    // Inner facet.
    canvas.drawPath(
      _roundedDiamond(c, s * 0.37, s * 0.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..color = gold.withValues(alpha: (fill == null ? 1 : 0.5) * trace),
    );

    // "કો" fades and rises into place.
    final letters = _phase(0.5, 0.85, Curves.easeOut);
    if (letters > 0) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'કો',
          style: TextStyle(
            fontSize: s * 0.4,
            fontWeight: FontWeight.w800,
            fontFamily: fontFamily,
            color: gold.withValues(alpha: letters),
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          c.dx - painter.width / 2,
          c.dy - painter.height / 2 + s * 0.02 + (1 - letters) * s * 0.05,
        ),
      );
      painter.dispose();
    }

    // One light sweep across the finished mark.
    final sweep = _phase(0.7, 1, Curves.easeInOut);
    if (fill != null && sweep > 0 && sweep < 1) {
      final x = c.dx - s + sweep * s * 2;
      canvas
        ..save()
        ..clipPath(outer)
        ..drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x - s * 0.25, c.dy - s * 0.25),
              Offset(x + s * 0.25, c.dy + s * 0.25),
              [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0),
              ],
              const [0, 0.5, 1],
            ),
        )
        ..restore();
    }
    canvas.restore();
  }

  /// A square with rounded corners standing on one corner, reaching
  /// [halfDiagonal] from [c] (less the rounding) in each direction.
  static Path _roundedDiamond(Offset c, double halfDiagonal, double radius) {
    final side = halfDiagonal * math.sqrt2;
    final square = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: side, height: side),
          Radius.circular(radius)));
    // Rotate 45° about the centre (column-major 4x4 matrix).
    const k = math.sqrt1_2;
    return square.transform(Float64List.fromList([
      k, k, 0, 0, //
      -k, k, 0, 0, //
      0, 0, 1, 0, //
      c.dx - k * c.dx + k * c.dy, c.dy - k * c.dx - k * c.dy, 0, 1,
    ]));
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress ||
      old.gold != gold ||
      old.fill != fill ||
      old.fontFamily != fontFamily;
}

/// "કોસ્ટિંગ માસ્ટર" with a small English line underneath.
class BrandWordmark extends StatelessWidget {
  final Color? color;
  final double scale;

  const BrandWordmark({super.key, this.color, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'કોસ્ટિંગ માસ્ટર',
          style: TextStyle(
            fontSize: 30 * scale,
            fontWeight: FontWeight.w800,
            color: fg,
            height: 1.2,
          ),
        ),
        Text(
          'COSTING MASTER',
          style: TextStyle(
            fontSize: 11 * scale,
            letterSpacing: 4 * scale,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
