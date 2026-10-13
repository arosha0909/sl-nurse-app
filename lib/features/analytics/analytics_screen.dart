import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/charts/progress_ring.dart';
import '../../core/network/api_client.dart';
import '../../core/charts/stacked_capsule_bars.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metric_pill.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../onboarding/progressive_prompts.dart';
import '../roster/roster_widgets.dart';

class _AnalyticsData {
  const _AnalyticsData(this.forecast, this.trends);

  final SalaryForecast forecast;

  /// Null when the nurse's plan doesn't include work trends.
  final WorkTrends? trends;
}

/// Work trends, or null if the plan doesn't include them (instead of failing the screen).
Future<WorkTrends?> _trendsIfIncluded(Future<WorkTrends> load) async {
  try {
    return await load;
  } on ApiException catch (e) {
    if (e.isPlanLocked) return null;
    rethrow;
  }
}

/// Forecast breakdown, OT outlook and workload / burnout insights.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final today = scope.today();
    final month = _month ?? DateTime(today.year, today.month);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ResponsiveContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                16,
                AppSpacing.screenPadding,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Salary Analytics', style: text.headlineSmall),
                  ),
                  MonthSwitcher(
                    month: month,
                    min: DateTime(today.year, today.month - 11),
                    max: DateTime(today.year, today.month + 1),
                    onChanged: (m) => setState(() => _month = m),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<_AnalyticsData>(
                reloadKey: month,
                skeleton: const SkeletonList(heights: [190, 160, 170, 220]),
                load: () async {
                  final r = await Future.wait<Object?>([
                    scope.repository.forecast(
                      month: month.month,
                      year: month.year,
                    ),
                    _trendsIfIncluded(scope.repository.workTrends(months: 3)),
                  ]);
                  return _AnalyticsData(
                    r[0]! as SalaryForecast,
                    r[1] as WorkTrends?,
                  );
                },
                builder: (context, data, reload) => RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      8,
                      AppSpacing.screenPadding,
                      AppSpacing.dockClearance,
                    ),
                    children: [
                      if (data.forecast.salaryIsEstimate) ...[
                        const _EstimateBanner(),
                        const SizedBox(height: AppSpacing.gap),
                      ],
                      _ProjectionCard(f: data.forecast),
                      if (data.forecast.isBasic) ...[
                        const SizedBox(height: AppSpacing.gap),
                        const _LockedCard(
                          title: 'Smart forecast',
                          message:
                              'Your plan shows a roster-based estimate. Upgrade to add your usual extra OT, absences and a confidence score.',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.gap),
                      if (data.forecast.daysElapsed > 0) ...[
                        _EarnedCard(f: data.forecast),
                        const SizedBox(height: AppSpacing.gap),
                      ],
                      _OtCard(f: data.forecast),
                      const SizedBox(height: AppSpacing.gap),
                      _PayslipCard(f: data.forecast),
                      const SizedBox(height: AppSpacing.sectionGap),
                      const SectionHeader(title: 'Workload & wellbeing'),
                      const SizedBox(height: 8),
                      if (data.trends case final trends?) ...[
                        _ShiftMixCard(t: trends),
                        const SizedBox(height: AppSpacing.gap),
                        _BurnoutCard(t: trends),
                      ] else
                        const _LockedCard(
                          title: 'Workload & burnout insights',
                          message:
                              'Shift mix, weekly hours and burnout risk are part of a higher plan.',
                        ),
                      const SizedBox(height: AppSpacing.gap),
                      _HowCalculated(f: data.forecast),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.f});

  final SalaryForecast f;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.peach,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projected take-home',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.lkr(f.projectedNet),
                        style: text.headlineMedium?.copyWith(fontSize: 30),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Likely ${Fmt.thousands(f.rangeLow)} – ${Fmt.thousands(f.rangeHigh)}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!f.isBasic)
                ProgressRing(
                  progress: f.confidencePercent / 100,
                  size: 76,
                  strokeWidth: 7,
                  color: AppColors.peachDeep,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${f.confidencePercent}%', style: text.titleSmall),
                      Text(
                        f.confidenceLevel,
                        style: text.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: 'Gross',
                  value: Fmt.lkr(f.projectedGross),
                  icon: Icons.add_card_rounded,
                  accent: AppColors.mintDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: 'Deductions',
                  value: Fmt.lkr(f.projectedDeductions),
                  icon: Icons.remove_circle_outline_rounded,
                  accent: AppColors.peachDeep,
                ),
              ),
            ],
          ),
          if (f.rosterOnlyNet != f.projectedNet) ...[
            const SizedBox(height: 10),
            Text(
              'Roster alone gives ${Fmt.lkr(f.rosterOnlyNet)}; the forecast adds your usual extra OT and absences.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _EarnedCard extends StatelessWidget {
  const _EarnedCard({required this.f});

  final SalaryForecast f;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final parts = {
      'Basic (so far)': f.earnedBreakdown['basicProRata'] ?? 0,
      'Allowances': f.earnedBreakdown['allowancesProRata'] ?? 0,
      'Overtime': f.earnedBreakdown['overtime'] ?? 0,
      'Night allowance': f.earnedBreakdown['nightAllowance'] ?? 0,
    };
    final total = parts.values.fold(0.0, (a, b) => a + b);
    return PastelCard(
      color: AppColors.mint,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earned so far', style: text.titleMedium),
          Text(
            '${f.daysElapsed} of ${f.daysInMonth} days',
            style: text.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(Fmt.lkr(f.currentEarned), style: text.headlineSmall),
          const SizedBox(height: 14),
          for (final e in parts.entries) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(Fmt.thousands(e.value), style: text.titleSmall),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : e.value / total,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                color: AppColors.mintDeep,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OtCard extends StatelessWidget {
  const _OtCard({required this.f});

  final SalaryForecast f;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final segments = [
      (label: 'Done', value: f.otCompleted, color: AppColors.ink),
      (label: 'Rostered', value: f.otScheduled, color: AppColors.lavenderDeep),
      (
        label: 'Likely extra',
        value: f.otExpectedExtra,
        color: AppColors.lavenderDeep.withValues(alpha: 0.4),
      ),
    ];
    final total = f.otTotal <= 0 ? 1.0 : f.otTotal;

    // API sends Sunday first; nurses read weeks Monday first.
    final byDay = [...f.otByWeekday.skip(1), ...f.otByWeekday.take(1)];

    return PastelCard(
      color: AppColors.lavender,
      padding: const EdgeInsets.all(20),
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
                    Text('OT this month', style: text.titleMedium),
                    Text(
                      'Likely ${Fmt.hours(f.otRangeLow)}–${Fmt.hours(f.otRangeHigh)} hrs',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Text('${Fmt.hours(f.otTotal)} hrs', style: text.headlineSmall),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              // stretch: childless ColoredBoxes would otherwise collapse to zero height.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in segments)
                    if (s.value > 0)
                      Expanded(
                        flex: (s.value / total * 1000).round(),
                        child: ColoredBox(color: s.color),
                      ),
                  if (f.otTotal <= 0)
                    const Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final s in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} ${Fmt.hours(s.value)}h',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (f.otHistoricalAverage != null) ...[
            const SizedBox(height: 12),
            Text(
              'Your usual month: ${Fmt.hours(f.otHistoricalAverage!)} hrs of OT',
              style: text.bodySmall,
            ),
          ],
          if (byDay.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('OT by weekday', style: text.titleSmall),
            const SizedBox(height: 12),
            StackedCapsuleBars(
              height: 90,
              baseColor: AppColors.lavenderDeep,
              data: [
                for (final w in byDay)
                  StackedBarDatum(
                    label: w.weekday.substring(0, 3),
                    base: w.avgHours,
                    top: 0,
                  ),
              ],
            ),
          ],
          if (f.consistentOtDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('OT habit:', style: text.bodySmall),
                for (final d in f.consistentOtDays)
                  Chip(
                    label: Text(d),
                    visualDensity: VisualDensity.compact,
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    backgroundColor: AppColors.surface,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PayslipCard extends StatelessWidget {
  const _PayslipCard({required this.f});

  final SalaryForecast f;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(
      String label,
      double amount, {
      bool minus = false,
      bool bold = false,
      String? note,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (note != null)
                    TextSpan(text: '  $note', style: text.bodySmall),
                ],
              ),
              style: (bold ? text.titleSmall : text.bodyMedium)?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${minus ? '− ' : ''}${Fmt.thousands(amount)}',
            style: bold ? text.titleMedium : text.titleSmall,
          ),
        ],
      ),
    );

    return PastelCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payslip preview', style: text.titleMedium),
          const SizedBox(height: 8),
          row('Basic salary', f.baseSalary),
          row('Allowances', f.allowances),
          row(
            'Night allowance',
            f.nightAmount,
            note: '${Fmt.hours(f.nightShifts)} shifts',
          ),
          row(
            'Overtime',
            f.otAmount,
            note: '${Fmt.hours(f.otTotal)}h × ${Fmt.thousands(f.otHourlyRate)}',
          ),
          const Divider(height: 18),
          row('Gross', f.projectedGross, bold: true),
          row('Fixed deductions', f.configuredDeductions, minus: true),
          if (f.noPayAmount > 0)
            row('No-pay deductions', f.noPayAmount, minus: true),
          const Divider(height: 18),
          row('Net (LKR)', f.projectedNet, bold: true),
        ],
      ),
    );
  }
}

class _ShiftMixCard extends StatelessWidget {
  const _ShiftMixCard({required this.t});

  final WorkTrends t;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mix = [
      (label: 'Morning', color: AppColors.peachDeep),
      (label: 'Evening', color: AppColors.lavenderDeep),
      (label: 'Night', color: AppColors.ink),
      (label: 'OffDayOT', color: AppColors.mintDeep),
    ];
    return PastelCard(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift mix · last 3 months', style: text.titleMedium),
          Text('${t.workedShifts} shifts worked', style: text.bodySmall),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              // stretch: childless ColoredBoxes would otherwise collapse to zero height.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in mix)
                    if ((t.percentages[m.label] ?? 0) > 0)
                      Expanded(
                        flex: ((t.percentages[m.label] ?? 0) * 10).round(),
                        child: ColoredBox(color: m.color),
                      ),
                  if (t.workedShifts == 0)
                    const Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final m in mix)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${m.label == 'OffDayOT' ? 'Off-day OT' : m.label} ${Fmt.hours(t.percentages[m.label] ?? 0)}%',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: 'Avg. weekly',
                  value: '${Fmt.hours(t.avgWeeklyHours)} hrs',
                  icon: Icons.calendar_view_week_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: 'OT share',
                  value: '${(t.otRatio * 100).round()}% of hours',
                  icon: Icons.more_time_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BurnoutCard extends StatelessWidget {
  const _BurnoutCard({required this.t});

  final WorkTrends t;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, accent) = switch (t.burnoutLevel) {
      'High' => (const Color(0xFFFBE1DE), const Color(0xFFD9655A)),
      'Moderate' => (AppColors.peach, AppColors.peachDeep),
      _ => (AppColors.mint, AppColors.mintDeep),
    };
    final trend = switch (t.otTrend) {
      'rising' => 'OT rising',
      'falling' => 'OT falling',
      'stable' => 'OT steady',
      _ => null,
    };

    return PastelCard(
      color: bg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: t.burnoutScore / 100,
                size: 72,
                strokeWidth: 7,
                color: accent,
                child: Text('${t.burnoutScore}', style: text.titleLarge),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Burnout risk', style: text.bodyMedium),
                    Text(t.burnoutLevel, style: text.headlineSmall),
                    if (trend != null) Text(trend, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (t.burnoutReasons.isEmpty)
            Text(
              'Your recent workload looks balanced. Keep it up!',
              style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
            )
          else
            for (final r in t.burnoutReasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 7, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
          Text(
            t.disclaimer,
            style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _HowCalculated extends StatelessWidget {
  const _HowCalculated({required this.f});

  final SalaryForecast f;

  static const _factorLabels = {
    'monthElapsed': 'Month already worked',
    'rosterCoverage': 'Roster filled in',
    'otConsistency': 'OT consistency',
    'attendanceReliability': 'Attendance',
    'historyDepth': 'History available',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('How is this calculated?', style: text.titleSmall),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in f.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '⚠  $w',
                  style: text.bodyMedium?.copyWith(color: AppColors.peachDeep),
                ),
              ),
            for (final a in f.assumptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('•  $a', style: text.bodyMedium),
              ),
            const SizedBox(height: 8),
            Text('Confidence factors', style: text.titleSmall),
            const SizedBox(height: 8),
            for (final e in f.confidenceFactors.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        _factorLabels[e.key] ?? e.key,
                        style: text.bodySmall,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown while forecasts use the typical salary estimate (the nurse skipped the prompt).
class _EstimateBanner extends StatelessWidget {
  const _EstimateBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.sky,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.skyDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These figures use a typical nursing salary. Add yours for exact predictions.',
              style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () =>
                ProgressivePrompts.ensureSalary(context, force: true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// A feature the nurse's subscription plan doesn't include: explains instead of failing.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.lavenderDeep,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(message, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
