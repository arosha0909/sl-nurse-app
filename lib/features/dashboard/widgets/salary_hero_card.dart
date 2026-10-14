import 'package:flutter/material.dart';

import '../../../core/charts/smooth_line_chart.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_pill.dart';
import '../../../core/widgets/pastel_card.dart';
import '../../onboarding/progressive_prompts.dart';
import '../dashboard_vm.dart';
import '../../../core/i18n/i18n.dart';

/// Lavender hero: predicted monthly salary, weekly earnings wave and OT stats.
class SalaryHeroCard extends StatelessWidget {
  const SalaryHeroCard({
    super.key,
    required this.data,
    required this.month,
    this.onTap,
    this.onAddSalary,
  });

  final DashboardData data;
  final DateTime month;
  final VoidCallback? onTap;

  /// Shown as an "Estimate" chip while the basic salary is a typical estimate.
  final VoidCallback? onAddSalary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final forecast = data.forecast;
    return PastelCard(
      color: AppColors.lavender,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This Month's\nPredicted Salary",
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ),
              _MonthChip(label: Fmt.monthYear(month)),
            ],
          ),
          const SizedBox(height: 6),
          // Scales down instead of wrapping on very narrow screens / large text settings.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'LKR ',
                    style: text.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(text: Fmt.thousands(forecast.projectedNet)),
                ],
              ),
              style: text.headlineMedium?.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 14,
                color: AppColors.lavenderDeep,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  forecast.isBasic
                      ? context.tr('Based on your roster')
                      : '${forecast.confidencePercent}% forecast confidence',
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (forecast.salaryIsEstimate && onAddSalary != null) ...[
            const SizedBox(height: 8),
            EstimateChip(onTap: onAddSalary!),
          ],
          const SizedBox(height: 16),
          SmoothLineChart(
            values: data.weeklyEarnings,
            labels: data.weekLabels,
            color: AppColors.ink,
            fillColor: AppColors.lavenderDeep.withValues(alpha: 0.22),
            height: 78,
            highlightLast: true,
            semanticLabel:
                'Weekly earnings this month, predicted total ${Fmt.lkr(forecast.projectedNet)}',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  icon: Icons.timer_outlined,
                  label: context.tr('Completed OT'),
                  value: '${Fmt.hours(data.completedOtHours)} hrs',
                  accent: AppColors.lavenderDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  icon: Icons.trending_up_rounded,
                  label: context.tr('Avg. Daily OT'),
                  value: '${Fmt.hours(data.avgDailyOtHours)} hrs',
                  accent: AppColors.mintDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
