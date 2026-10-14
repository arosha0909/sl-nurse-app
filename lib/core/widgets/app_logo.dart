import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nurse Companion's mark: a friendly floating medical kit in a nurse cap, holding a
/// clipboard with a progress chart and "Rs.", on a charcoal rounded square.
///
/// Drawn in code so it stays crisp at any size; the launcher, iOS and web icons are
/// exported from this same painter (`flutter test tool/generate_icons.dart`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.style = LogoStyle.tile});

  final double size;
  final LogoStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Nurse Companion',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: AppLogoPainter(style: style)),
    ),
  );
}

enum LogoStyle {
  /// Charcoal rounded square (in-app, legacy launcher icons, web).
  tile,

  /// Charcoal square without rounding (iOS masks its own corners).
  square,

  /// Character only, transparent, scaled into the adaptive-icon / splash safe zone.
  character,

  /// Charcoal square with the glow and no character (adaptive-icon background layer).
  backdrop,
}

abstract final class LogoColors {
  static const charcoal = Color(0xFF2B2D42);
  static const cyan = Color(0xFFE3F2FD);
  static const peach = Color(0xFFFDE8E1);
}

class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.style = LogoStyle.tile});

  final LogoStyle style;

  static const _cyanShade = Color(0xFFC6E2FA);
  static const _peachShade = Color(0xFFF8CFC1);
  static const _peachDeep = Color(0xFFE38B6F);
  static const _skyDeep = Color(0xFF5B9BD5);
  static const _mintDeep = Color(0xFF6FAE8A);
  static const _ink = LogoColors.charcoal;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    if (style != LogoStyle.character) _tile(canvas, s);
    if (style == LogoStyle.backdrop) {
      canvas.restore();
      return;
    }

    // The character is drawn on a unit grid; the safe-zone style shrinks it so the
    // launcher's mask (circle, squircle…) never clips it.
    final scale = style == LogoStyle.character ? 0.82 : 1.0;
    // The character's visual centre sits a little low on the grid (cap above, shadow
    // below), so the safe-zone version is lifted to look centred in round masks.
    canvas.translate(
      s * (1 - scale) / 2,
      s * (1 - scale) / 2 - (style == LogoStyle.character ? s * 0.03 : 0),
    );
    canvas.scale(s * scale);
    _character(canvas, glow: style != LogoStyle.character);
    canvas.restore();
  }

  void _tile(Canvas canvas, double s) {
    final rect = Offset.zero & Size.square(s);
    final shape = style == LogoStyle.square || style == LogoStyle.backdrop
        ? RRect.fromRectAndRadius(rect, Radius.zero)
        : RRect.fromRectAndRadius(rect, Radius.circular(s * 0.225));
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3D57), Color(0xFF22233A)],
        ).createShader(rect),
    );
    // Soft cyan light behind the character.
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.52),
      s * 0.46,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LogoColors.cyan.withValues(alpha: 0.28),
                LogoColors.cyan.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(s * 0.5, s * 0.52),
                radius: s * 0.46,
              ),
            ),
    );
  }

  void _character(Canvas c, {required bool glow}) {
    // Floating shadow.
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.875),
        width: 0.42,
        height: 0.055,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: glow ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.012),
    );

    _kit(c);
    _cap(c);
    _face(c);
    _clipboard(c);
    if (glow) _sparkles(c);
  }

  /// Soft-cornered medical kit body with a glossy highlight.
  void _kit(Canvas c) {
    const body = Rect.fromLTRB(0.22, 0.38, 0.78, 0.8);
    final rrect = RRect.fromRectAndRadius(body, const Radius.circular(0.13));
    // Gentle volume: lighter on top, deeper cyan underneath.
    c.drawRRect(
      rrect.shift(const Offset(0, 0.012)),
      Paint()..color = const Color(0xFF9CC9EE).withValues(alpha: 0.55),
    );
    c.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FBFF), LogoColors.cyan, _cyanShade],
          stops: [0, 0.45, 1],
        ).createShader(body),
    );
    // Gloss.
    final gloss = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(0.27, 0.41, 0.6, 0.47),
          const Radius.circular(0.03),
        ),
      );
    c.drawPath(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTRB(0.27, 0.41, 0.6, 0.47)),
    );
    c.drawCircle(
      const Offset(0.69, 0.435),
      0.012,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  /// Classic nurse cap with a small cross, sitting on the kit like a handle.
  void _cap(Canvas c) {
    final cap = Path()
      ..moveTo(0.33, 0.405)
      ..cubicTo(0.33, 0.33, 0.35, 0.27, 0.40, 0.255)
      ..lineTo(0.60, 0.255)
      ..cubicTo(0.65, 0.27, 0.67, 0.33, 0.67, 0.405)
      ..quadraticBezierTo(0.5, 0.375, 0.33, 0.405)
      ..close();
    c.drawPath(
      cap.shift(const Offset(0, 0.008)),
      Paint()..color = _peachDeep.withValues(alpha: 0.35),
    );
    c.drawPath(
      cap,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, LogoColors.peach, _peachShade],
          stops: [0, 0.5, 1],
        ).createShader(const Rect.fromLTRB(0.33, 0.255, 0.67, 0.405)),
    );
    // Folded brim.
    c.drawPath(
      Path()
        ..moveTo(0.345, 0.36)
        ..quadraticBezierTo(0.5, 0.335, 0.655, 0.36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..strokeCap = StrokeCap.round
        ..color = _peachDeep.withValues(alpha: 0.45),
    );
    // Cross.
    final cross = Paint()..color = _peachDeep;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0.5, 0.3),
          width: 0.018,
          height: 0.058,
        ),
        const Radius.circular(0.006),
      ),
      cross,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0.5, 0.3),
          width: 0.058,
          height: 0.018,
        ),
        const Radius.circular(0.006),
      ),
      cross,
    );
  }

  /// Friendly cartoon face: shiny eyes, blush and a small smile.
  void _face(Canvas c) {
    final ink = Paint()..color = _ink;
    for (final x in [0.405, 0.575]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, 0.525), width: 0.058, height: 0.078),
        ink,
      );
      c.drawCircle(
        Offset(x - 0.011, 0.508),
        0.013,
        Paint()..color = Colors.white,
      );
      c.drawCircle(
        Offset(x + 0.01, 0.54),
        0.005,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
    final blush = Paint()
      ..color = const Color(0xFFF6B8A3).withValues(alpha: 0.85);
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.345, 0.585),
        width: 0.062,
        height: 0.034,
      ),
      blush,
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.635, 0.585),
        width: 0.062,
        height: 0.034,
      ),
      blush,
    );
    c.drawArc(
      Rect.fromCenter(
        center: const Offset(0.49, 0.575),
        width: 0.085,
        height: 0.06,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.016
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
  }

  /// Digital clipboard with a progress chart and "Rs.", held at the front.
  void _clipboard(Canvas c) {
    c.save();
    c.translate(0.655, 0.695);
    c.rotate(-0.16);
    const board = Rect.fromLTRB(-0.125, -0.13, 0.125, 0.13);
    c.drawRRect(
      RRect.fromRectAndRadius(
        board.shift(const Offset(0.006, 0.01)),
        const Radius.circular(0.035),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(0.035)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4F0), LogoColors.peach, _peachShade],
        ).createShader(board),
    );
    // Screen.
    const screen = Rect.fromLTRB(-0.1, -0.085, 0.1, 0.105);
    c.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(0.022)),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    // Clip.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0, -0.13),
          width: 0.09,
          height: 0.038,
        ),
        const Radius.circular(0.014),
      ),
      Paint()..color = _ink,
    );
    // "Rs." — laid out at a normal font size, then scaled into the unit grid.
    final rs = TextPainter(
      text: const TextSpan(
        text: 'Rs.',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 50,
          height: 1,
          color: _ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    c.save();
    c.translate(-0.085, -0.077);
    c.scale(0.001);
    rs.paint(c, Offset.zero);
    c.restore();
    // Rising bars.
    const bars = [(0.035, _skyDeep), (0.058, _mintDeep), (0.085, _peachDeep)];
    for (var i = 0; i < bars.length; i++) {
      final (h, color) = bars[i];
      final x = -0.078 + i * 0.055;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0.09 - h, 0.034, h),
          const Radius.circular(0.008),
        ),
        Paint()..color = color,
      );
    }
    // Trend line with an upward tick.
    final trend = Path()
      ..moveTo(-0.07, 0.0)
      ..lineTo(-0.015, -0.015)
      ..lineTo(0.03, -0.005)
      ..lineTo(0.08, -0.05);
    c.drawPath(
      trend,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.009
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _ink.withValues(alpha: 0.75),
    );
    c.drawCircle(const Offset(0.08, -0.05), 0.011, Paint()..color = _peachDeep);
    c.restore();

    // Little hands holding the board.
    final hand = Paint()..color = const Color(0xFFD4EAFB);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.006
      ..color = const Color(0xFF9CC9EE);
    for (final p in [const Offset(0.535, 0.735), const Offset(0.775, 0.66)]) {
      c.drawCircle(p, 0.028, hand);
      c.drawCircle(p, 0.028, outline);
    }
  }

  /// Two tiny sparkles: the "smart" in smart companion.
  void _sparkles(Canvas c) {
    void star(Offset o, double r, double alpha) {
      final p = Path()
        ..moveTo(o.dx, o.dy - r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
        ..close();
      c.drawPath(p, Paint()..color = LogoColors.cyan.withValues(alpha: alpha));
    }

    star(const Offset(0.2, 0.27), 0.032, 0.9);
    star(const Offset(0.82, 0.31), 0.022, 0.7);
    star(const Offset(0.86, 0.2), 0.014, 0.5);
  }

  @override
  bool shouldRepaint(AppLogoPainter old) => old.style != style;
}
