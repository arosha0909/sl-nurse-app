import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../roster/manual_roster_screen.dart';
import '../shifts/shift_sheets.dart';
import 'duty_vm.dart';
import 'widgets/date_selector.dart';
import 'widgets/duty_stat_widgets.dart';
import 'widgets/leave_summary_card.dart';
import 'widgets/weekly_hours_card.dart';
import '../../core/i18n/i18n.dart';

class DutyDetailsScreen extends StatefulWidget {
  const DutyDetailsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<DutyDetailsScreen> createState() => _DutyDetailsScreenState();
}

class _DutyDetailsScreenState extends State<DutyDetailsScreen> {
  late DateTime _today;
  late DateTime _selected;
  late List<DateTime> _dates;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _today = dayOf(AppScope.of(context).today());
    _selected = _today;
    // Two weeks back and three weeks ahead of today.
    _dates = [
      for (var i = -14; i <= 21; i++)
        DateTime(_today.year, _today.month, _today.day + i),
    ];
  }

  Future<DutyData> _load(AppScope scope) async {
    final monthStart = DateTime(_today.year, _today.month);
    final monthEnd = DateTime(_today.year, _today.month + 1, 0);
    final from = _dates.first.isBefore(monthStart) ? _dates.first : monthStart;
    final to = _dates.last.isAfter(monthEnd) ? _dates.last : monthEnd;

    final results = await Future.wait<Object>([
      scope.repository.me(),
      scope.repository.shifts(from: from, to: to),
      scope.repository.shifts(
        from: DateTime(_today.year),
        to: _today,
        status: ShiftStatus.leave,
      ),
      scope.repository.salaryConfig(),
    ]);
    return DutyData.build(
      user: results[0] as UserProfile,
      shifts: results[1] as List<Shift>,
      yearLeave: results[2] as List<Shift>,
      today: _today,
      entitlements: (results[3] as SalaryConfig).leave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final text = Theme.of(context).textTheme;

    final header = Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: context.tr('Back'),
          onPressed: widget.onBack,
        ),
        Expanded(
          child: Text(
            context.tr('Duty & Roster Details'),
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
        ),
        CircleIconButton(
          icon: Icons.edit_calendar_outlined,
          tooltip: context.tr('Edit roster'),
          onPressed: () => ManualRosterScreen.open(context),
        ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: ResponsiveContent(
        child: AsyncView<DutyData>(
          load: () => _load(scope),
          skeleton: const SkeletonList(heights: [52, 44, 70, 200, 260]),
          // Header and date bar stay pinned; the day's details scroll beneath them.
          builder: (context, data, reload) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  12,
                  AppSpacing.screenPadding,
                  12,
                ),
                child: Column(
                  children: [
                    header,
                    const SizedBox(height: 18),
                    DateSelector(
                      dates: _dates,
                      selected: _selected,
                      onChanged: (d) => setState(() => _selected = d),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      4,
                      AppSpacing.screenPadding,
                      AppSpacing.dockClearance,
                    ),
                    children: [
                      _SelectedDay(
                        date: _selected,
                        today: _today,
                        shifts: data.on(_selected),
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      DutyStatWidgets(summary: data),
                      const SizedBox(height: AppSpacing.gap),
                      WeeklyHoursCard(
                        week: data.weekOf(_selected),
                        selected: _selected,
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      LeaveSummaryCard(summary: data),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shifts on the selected date, each tappable for actions; "Add" when the day is empty.
class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.date,
    required this.today,
    required this.shifts,
  });

  final DateTime date;
  final DateTime today;
  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final upcoming = date.isAfter(today);
    final label = sameDay(date, today)
        ? context.tr('Today')
        : (upcoming ? context.tr('Upcoming') : context.tr('Past'));

    if (shifts.isEmpty) {
      return PastelCard(
        key: ValueKey(date),
        color: upcoming ? AppColors.sky : AppColors.surface,
        elevated: !upcoming,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$label · ${Fmt.weekday(date)}', style: text.bodySmall),
                  Text(context.tr('Nothing rostered'), style: text.titleSmall),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => showAddShift(context, date),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.tr('Add')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final s in shifts) ...[
          PastelCard(
            key: ValueKey(s.id),
            color: upcoming
                ? AppColors.sky
                : (s.isLeave ? AppColors.peach : AppColors.surface),
            elevated: !upcoming && !s.isLeave,
            onTap: () => showShiftActions(context, s),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label · ${Fmt.weekday(s.date)} · ${context.tr(_status(s))}',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          s.isLeave ? s.leaveType.label : s.type.label,
                        ),
                        style: text.titleSmall,
                      ),
                      if (!s.isLeave)
                        Text(s.type.timeRange, style: text.bodySmall),
                    ],
                  ),
                ),
                if (s.otHours > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '+${Fmt.hours(s.otHours)}h OT',
                      style: text.labelLarge,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (s != shifts.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  static String _status(Shift s) => switch (s.status) {
    ShiftStatus.completed => 'Completed',
    ShiftStatus.missed => 'Missed',
    ShiftStatus.leave => 'Leave',
    ShiftStatus.swapped => 'Swapped',
    ShiftStatus.scheduled => s.checkInTime != null ? 'Checked in' : 'Scheduled',
  };
}
