import 'dart:ui' as ui;

import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// The app's Gujarati monogram: a gold-edged plum diamond carrying "કો".
///
/// Drawn in code so it stays crisp at any size and costs no asset bytes.
/// With [animate], the gold edge traces itself and the letters fade in.
class BrandMark extends StatefulWidget {
  final double size;
  final bool animate;

  const BrandMark({super.key, this.size = 96, this.animate = false});

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
            painter: _BrandMarkPainter(
              progress: _controller.value,
              gold: AppTheme.gold,
              fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  final double progress;
  final Color gold;
  final String? fontFamily;

  _BrandMarkPainter({
    required this.progress,
    required this.gold,
    required this.fontFamily,
  });

  static const _plumDeep = Color(0xFF3A1460);
  static const _plumBright = Color(0xFF7B3FB0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final r = s * 0.48;

    Path rhombus(double radius) => Path()
      ..moveTo(c.dx, c.dy - radius)
      ..lineTo(c.dx + radius, c.dy)
      ..lineTo(c.dx, c.dy + radius)
      ..lineTo(c.dx - radius, c.dy)
      ..close();

    final fillIn = Curves.easeOut.transform((progress / 0.35).clamp(0, 1));
    final outer = rhombus(r);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx - r, c.dy - r),
          Offset(c.dx + r, c.dy + r),
          [
            _plumBright.withValues(alpha: fillIn),
            _plumDeep.withValues(alpha: fillIn),
          ],
        ),
    );

    // Gold edge traces itself around the diamond.
    final trace =
        Curves.easeInOutCubic.transform(((progress - 0.1) / 0.6).clamp(0, 1));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeJoin = StrokeJoin.round
      ..color = gold;
    if (trace >= 1) {
      // A closed path gets a proper join at the top corner.
      canvas.drawPath(outer, edge);
    } else {
      for (final metric in outer.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * trace), edge);
      }
    }

    // Faint inner facet.
    canvas.drawPath(
      rhombus(r * 0.78),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = gold.withValues(alpha: 0.35 * trace),
    );

    // "કો" fades and rises into place.
    final letters =
        Curves.easeOut.transform(((progress - 0.55) / 0.45).clamp(0, 1));
    if (letters == 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: 'કો',
        style: TextStyle(
          fontSize: s * 0.36,
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
        c.dy - painter.height / 2 + s * 0.02 + (1 - letters) * s * 0.06,
      ),
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.progress != progress ||
      old.gold != gold ||
      old.fontFamily != fontFamily;
}

/// "કોસ્ટિંગ માસ્ટર" with a small English line underneath.
class BrandWordmark extends StatelessWidget {
  final Color? color;
  final double scale;

  const BrandWordmark({super.key, this.color, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.onSurface;
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
