import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pastel_card.dart';
import '../../../data/models.dart';

/// Soft blue reminder for the next rostered shift.
class NextShiftReminder extends StatelessWidget {
  const NextShiftReminder({
    super.key,
    required this.shift,
    required this.now,
    required this.onTap,
  });

  final Shift shift;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = shift.type.window(shift.date).start;
    final tomorrow = sameDay(
      shift.date,
      DateTime(now.year, now.month, now.day + 1),
    );
    final when = tomorrow
        ? 'Tomorrow'
        : '${Fmt.weekday(shift.date)} ${shift.date.day}';

    return PastelCard(
      color: AppColors.sky,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.skyDeep,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Up next · $when', style: text.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${shift.type.label} · ${Fmt.time(start)}',
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (shift.otHours > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+${Fmt.hours(shift.otHours)}h OT',
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
