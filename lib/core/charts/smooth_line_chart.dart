import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Smooth wave line with a soft gradient fill, drawn left-to-right on first build.
///
/// Values are normalised to the chart height; [labels] (optional) render under the chart.
class SmoothLineChart extends StatelessWidget {
  const SmoothLineChart({
    super.key,
    required this.values,
    this.labels,
    this.color = AppColors.ink,
    this.fillColor,
    this.strokeWidth = 2.4,
    this.highlightLast = false,
    this.height = 90,
    this.semanticLabel,
  });

  final List<double> values;
  final List<String>? labels;
  final Color color;
  final Color? fillColor;
  final double strokeWidth;
  final bool highlightLast;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final chart = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size.infinite,
        painter: _SmoothLinePainter(
          values: values,
          color: color,
          fillColor: fillColor ?? color.withValues(alpha: 0.12),
          strokeWidth: strokeWidth,
          highlightLast: highlightLast,
          progress: progress,
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: height, width: double.infinity, child: chart),
          if (labels != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in labels!)
                  Text(
                    l,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmoothLinePainter extends CustomPainter {
  _SmoothLinePainter({
    required this.values,
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
    required this.highlightLast,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final Color fillColor;
  final double strokeWidth;
  final bool highlightLast;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    final pad = strokeWidth + (highlightLast ? 5 : 2);

    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          i / (values.length - 1) * size.width,
          pad + (1 - (values[i] - minV) / span) * (size.height - pad * 2),
        ),
    ];

    // Catmull-Rom → cubic Bézier for a smooth curve that passes through every point.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      line.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    if (highlightLast && progress > 0.98) {
      final last = points.last;
      canvas
        ..drawCircle(last, 6, Paint()..color = Colors.white)
        ..drawCircle(last, 3.6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SmoothLinePainter old) =>
      old.progress != progress || old.values != values || old.color != color;
}
