import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared spacing and radius tokens.
abstract final class AppSpacing {
  static const screenPadding = 20.0;
  static const cardPadding = 18.0;
  static const gap = 14.0;
  static const sectionGap = 26.0;

  static const cardRadius = 26.0;
  static const innerRadius = 18.0;

  /// Content is centred and capped at this width on tablets, desktop and web.
  static const maxContentWidth = 520.0;

  /// Room reserved at the bottom of scroll views so content clears the floating dock.
  static const dockClearance = 120.0;
}

abstract final class AppTheme {
  /// Bundled in assets/fonts (see pubspec.yaml), so no network is needed.
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lavenderDeep,
        primary: AppColors.ink,
        onPrimary: Colors.white,
        surface: AppColors.surface,
      ),
    );

    final text = base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    const buttonText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      splashFactory: InkSparkle.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.25),
          minimumSize: const Size(0, 44),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 44),
          shape: const StadiumBorder(),
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.lavenderDeep,
            width: 1.4,
          ),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}
