import 'package:flutter/material.dart';

import '../../../core/charts/stacked_capsule_bars.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pastel_card.dart';
import '../duty_vm.dart';
import '../../../core/i18n/i18n.dart';

/// Weekly comparison of main shift hours vs OT hours (Mon → Sun).
class WeeklyHoursCard extends StatelessWidget {
  const WeeklyHoursCard({
    super.key,
    required this.week,
    required this.selected,
  });

  final List<DayHours> week;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mainTotal = week.fold<double>(0, (s, d) => s + d.main);
    final otTotal = week.fold<double>(0, (s, d) => s + d.ot);
    final selectedIndex = week.indexWhere(
      (d) => d.date.day == selected.day && d.date.month == selected.month,
    );

    return PastelCard(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Fmt.hours(mainTotal + otTotal)} hrs',
                      style: text.titleLarge,
                    ),
                    Text(
                      context.tr('Week of {day}', {
                        'day':
                            '${Fmt.weekday(week.first.date)} ${week.first.date.day}',
                      }),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Legend(
                    color: AppColors.mintDeep.withValues(alpha: 0.55),
                    label: context.tr('Main {hours}h', {
                      'hours': Fmt.hours(mainTotal),
                    }),
                  ),
                  const SizedBox(height: 4),
                  _Legend(
                    color: AppColors.lavenderDeep,
                    label: 'OT ${Fmt.hours(otTotal)}h',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          StackedCapsuleBars(
            // New key per week so bars re-animate when the week changes.
            key: ValueKey(week.first.date),
            highlightIndex: selectedIndex < 0 ? null : selectedIndex,
            data: [
              for (final d in week)
                StackedBarDatum(
                  label: Fmt.weekday(d.date),
                  base: d.main,
                  top: d.ot,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
