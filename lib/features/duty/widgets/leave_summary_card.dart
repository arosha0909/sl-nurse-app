import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_pill.dart';
import '../../../core/widgets/pastel_card.dart';
import '../duty_vm.dart';
import '../../../core/i18n/i18n.dart';

/// Peach summary of leave balances and allowances.
class LeaveSummaryCard extends StatelessWidget {
  const LeaveSummaryCard({super.key, required this.summary});

  final DutyData summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.peach,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Leave & Allowance Summary'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 14),
          for (final leave in summary.leave) ...[
            _LeaveBar(leave: leave),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  icon: Icons.nightlight_round,
                  label: context.tr('Night allowance'),
                  value: Fmt.lkr(summary.nightAllowanceEarned),
                  accent: AppColors.peachDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  icon: Icons.money_off_rounded,
                  label: context.tr('No-pay days'),
                  value: Fmt.hours(summary.noPayDays),
                  accent: AppColors.peachDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveBar extends StatelessWidget {
  const _LeaveBar({required this.leave});

  final LeaveBalance leave;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ratio = leave.entitled == 0
        ? 0.0
        : (leave.used / leave.entitled).clamp(0.0, 1.0);
    return Semantics(
      label:
          '${leave.name}: ${Fmt.hours(leave.used)} of ${Fmt.hours(leave.entitled)} days used',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leave.name,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  text: Fmt.hours(leave.used),
                  style: text.titleSmall,
                  children: [
                    TextSpan(
                      text: ' / ${Fmt.hours(leave.entitled)} Days',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                color: AppColors.peachDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
