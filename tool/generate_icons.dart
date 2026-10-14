// Exports the app icon from AppLogoPainter to every platform's icon files.
//
//   flutter test tool/generate_icons.dart
//
// Android: legacy launcher icons, adaptive-icon foreground, launch-screen logo.
// iOS: AppIcon set (full-bleed square; iOS rounds the corners itself).
// Web: favicon, PWA and maskable icons.
// Not part of the normal test run (it lives in tool/, not test/).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/widgets/app_logo.dart';

Future<void> _png(String path, int px, LogoStyle style) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  AppLogoPainter(style: style).paint(canvas, ui.Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate app icons', () async {
    // Real font for "Rs." (tests otherwise render text with a placeholder font).
    final font = File(
      'assets/fonts/PlusJakartaSans-Bold.ttf',
    ).readAsBytesSync();
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(Future.value(ByteData.sublistView(font)))).load();

    const android = 'android/app/src/main/res';
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    for (final e in densities.entries) {
      // Legacy launcher icon (48 dp) and adaptive foreground (108 dp).
      await _png(
        '$android/mipmap-${e.key}/ic_launcher.png',
        (48 * e.value).round(),
        LogoStyle.tile,
      );
      await _png(
        '$android/mipmap-${e.key}/ic_launcher_foreground.png',
        (108 * e.value).round(),
        LogoStyle.character,
      );
      await _png(
        '$android/mipmap-${e.key}/ic_launcher_background.png',
        (108 * e.value).round(),
        LogoStyle.backdrop,
      );
      // Pre-Android 12 launch screen logo (160 dp).
      await _png(
        '$android/drawable-${e.key}/splash_logo.png',
        (160 * e.value).round(),
        LogoStyle.character,
      );
    }

    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents =
        jsonDecode(File('$ios/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final image
        in (contents['images'] as List).cast<Map<String, dynamic>>()) {
      final points = double.parse((image['size'] as String).split('x').first);
      final scale = double.parse(
        (image['scale'] as String).replaceAll('x', ''),
      );
      await _png(
        '$ios/${image['filename']}',
        (points * scale).round(),
        LogoStyle.square,
      );
    }

    await _png('web/favicon.png', 32, LogoStyle.tile);
    await _png('web/icons/Icon-192.png', 192, LogoStyle.tile);
    await _png('web/icons/Icon-512.png', 512, LogoStyle.tile);
    await _png('web/icons/Icon-maskable-192.png', 192, LogoStyle.square);
    await _png('web/icons/Icon-maskable-512.png', 512, LogoStyle.square);

    // How launchers show the adaptive icon: 108 dp layers, 72 dp visible through a mask.
    for (final circle in [true, false]) {
      const px = 432;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      const visible = px * 72 / 108;
      const inset = (px - visible) / 2;
      final mask = ui.Rect.fromLTWH(inset, inset, visible, visible);
      canvas.clipRRect(
        ui.RRect.fromRectAndRadius(
          mask,
          ui.Radius.circular(circle ? visible / 2 : visible * 0.3),
        ),
      );
      for (final style in [LogoStyle.backdrop, LogoStyle.character]) {
        AppLogoPainter(
          style: style,
        ).paint(canvas, const ui.Size.square(px * 1.0));
      }
      final image = await recorder.endRecording().toImage(px, px);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/icon_preview/adaptive_${circle ? 'circle' : 'squircle'}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    // Previews for review.
    await _png('build/icon_preview/tile_512.png', 512, LogoStyle.tile);
    await _png('build/icon_preview/tile_96.png', 96, LogoStyle.tile);
    await _png(
      'build/icon_preview/character_512.png',
      512,
      LogoStyle.character,
    );
  });
}
