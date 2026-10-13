import 'package:flutter/material.dart';

/// Soft modern pastel palette. Every colour in the app comes from here.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFF4F3F8);
  static const surface = Colors.white;
  static const surfaceMuted = Color(
    0xFFEEEDF3,
  ); // neutral "soft grey" chart card

  // Primary / dark accent (CTAs, headings, active nav)
  static const ink = Color(0xFF2B2D42);

  // Pastel card tints
  static const lavender = Color(0xFFEAE4F8); // duty / shift summary
  static const mint = Color(
    0xFFDDF2E4,
  ); // completed OT, check-ins, positive stats
  static const peach = Color(0xFFFCECE7); // salary prediction, goal progress
  static const sky = Color(0xFFE3F2FD); // upcoming shift reminders

  // Deeper tones of the pastels, for strokes, fills and icons drawn on top of them.
  static const lavenderDeep = Color(0xFF8E7CC3);
  static const mintDeep = Color(0xFF6FAE8A);
  static const peachDeep = Color(0xFFE38B6F);
  static const skyDeep = Color(0xFF5B9BD5);

  // Text
  static const textPrimary = Color(0xFF1A1D1F);
  static const textSecondary = Color(0xFF7F828D);

  // Decorative background waves
  static const wave = Color(0xFFDCD5EE);

  /// Ambient shadow: barely visible, only to lift white surfaces off the background.
  static List<BoxShadow> softShadow([double opacity = 0.05]) => [
    BoxShadow(
      color: ink.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
