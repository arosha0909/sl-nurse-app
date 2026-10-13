import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Section title with an optional trailing action icon (e.g. edit).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.actionIcon,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final String? emoji;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              children: [if (emoji != null) TextSpan(text: '  $emoji')],
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actionIcon != null)
          IconButton(
            onPressed: onAction,
            tooltip: actionLabel,
            icon: Icon(actionIcon, size: 20, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

/// Rounded square icon container used at the top-left of cards.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = Colors.white,
    this.iconColor = AppColors.ink,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, size: size * 0.5, color: iconColor),
    );
  }
}

/// Small round icon button on a white disc, used in top bars.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Initials avatar. Swap [image] in once profile photos come from the API.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.image, this.size = 46});

  final String name;
  final ImageProvider? image;
  final double size;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'[\s.]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.lavender,
        foregroundImage: image,
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.lavenderDeep,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }
}

/// Centres content and caps its width on large screens, keeping phone proportions.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}
