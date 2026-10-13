import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Subtle hand-drawn-looking curves behind the content, as in the reference design.
class BackgroundWaves extends StatelessWidget {
  const BackgroundWaves({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _WavePainter())),
          ),
        ),
        child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.wave.withValues(alpha: 0.7);

    final top = Path()
      ..moveTo(-w * 0.1, h * 0.08)
      ..cubicTo(w * 0.35, -h * 0.05, w * 0.55, h * 0.22, w * 1.1, h * 0.02);
    final middle = Path()
      ..moveTo(w * 1.1, h * 0.38)
      ..cubicTo(w * 0.7, h * 0.30, w * 0.25, h * 0.62, -w * 0.1, h * 0.48);
    final loop = Path()
      ..moveTo(-w * 0.1, h * 0.86)
      ..cubicTo(w * 0.3, h * 0.70, w * 0.95, h * 1.02, w * 0.55, h * 0.80)
      ..cubicTo(w * 0.35, h * 0.68, w * 0.85, h * 0.62, w * 1.1, h * 0.74);

    canvas
      ..drawPath(top, paint)
      ..drawPath(middle, paint..color = AppColors.wave.withValues(alpha: 0.45))
      ..drawPath(loop, paint..color = AppColors.wave.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
