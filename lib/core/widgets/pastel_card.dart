import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The base surface of the design: a softly tinted, extra-rounded card with
/// almost no elevation. Pass [onTap] to make the whole card tappable with a ripple.
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppSpacing.cardRadius,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Adds the soft ambient shadow. Useful for white cards; tinted cards read fine without.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated ? AppColors.softShadow() : null,
      ),
      child: Material(
        color: color,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
