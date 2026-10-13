import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A compact "label / value" stat, e.g. `Completed OT · 32 hrs`.
///
/// [tinted] wraps it in a translucent white capsule so it reads on any pastel card.
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent = AppColors.ink,
    this.tinted = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.bodySmall?.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (!tinted) return content;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}
