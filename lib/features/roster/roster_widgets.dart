import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';

/// What a nurse can put on a roster day, using Sri Lankan ward codes. Leave and absence
/// sit in the Morning slot, as the API expects.
enum RosterCode {
  morning('7', 'Morning', ShiftType.morning, LeaveType.none),
  evening('1', 'Evening', ShiftType.evening, LeaveType.none),
  night('N', 'Night', ShiftType.night, LeaveType.none),
  day('D', 'Day duty, 12 h', ShiftType.day, LeaveType.none),
  shortDuty('8D', 'Short duty, 8 h', ShiftType.short, LeaveType.none),
  twentyFour('24', '24-hour duty', ShiftType.twentyFour, LeaveType.none),
  off('DO', 'Day off', ShiftType.off, LeaveType.none),
  casual('CL', 'Casual leave', ShiftType.morning, LeaveType.casual),
  vacation('VL', 'Vacation leave', ShiftType.morning, LeaveType.vacation),
  sick('SL', 'Sick leave', ShiftType.morning, LeaveType.sick),
  noPay('NP', 'No-pay leave', ShiftType.morning, LeaveType.noPay),
  publicHoliday(
    'PH',
    'Public holiday',
    ShiftType.morning,
    LeaveType.publicHoliday,
  ),
  absent('A', 'Absent', ShiftType.morning, LeaveType.none);

  const RosterCode(this.short, this.label, this.type, this.leave);
  final String short;
  final String label;
  final ShiftType type;
  final LeaveType leave;

  bool get isLeave => leave != LeaveType.none;

  /// Not a working duty: leave, absence or a day off.
  bool get isRest => isLeave || this == absent || this == off;

  static RosterCode of(
    ShiftType type,
    LeaveType leave, [
    ShiftStatus status = ShiftStatus.scheduled,
  ]) {
    if (status == ShiftStatus.missed) return RosterCode.absent;
    if (leave == LeaveType.none) {
      return values.firstWhere(
        (c) => c.type == type && !c.isLeave && c != absent,
      );
    }
    return values.firstWhere(
      (c) => c.leave == leave,
      orElse: () => RosterCode.casual,
    );
  }

  static RosterCode ofShift(Shift s) => of(s.type, s.leaveType, s.status);

  Color get color => switch (this) {
    RosterCode.morning => AppColors.peach,
    RosterCode.evening => AppColors.lavender,
    RosterCode.night || RosterCode.twentyFour => AppColors.sky,
    RosterCode.day || RosterCode.shortDuty => AppColors.peach,
    RosterCode.off => AppColors.surfaceMuted,
    RosterCode.absent => AppColors.surfaceMuted,
    _ => AppColors.mint,
  };

  ShiftDraft draft(DateTime date, {double otHours = 0, ShiftStatus? status}) =>
      ShiftDraft(
        date: date,
        type: type,
        leaveType: leave,
        status: isLeave
            ? ShiftStatus.leave
            : this == absent
            ? ShiftStatus.missed
            : (status ?? ShiftStatus.scheduled),
        otHours: isRest ? 0 : otHours,
      );
}

/// Compact coloured code badge (M / E / N / Off / CL …) that opens a picker.
class RosterCodeButton extends StatelessWidget {
  const RosterCodeButton({
    super.key,
    required this.code,
    required this.onChanged,
    this.allowClear = false,
  });

  final RosterCode? code;
  final ValueChanged<RosterCode?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      tooltip: 'Change shift',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v) => onChanged(v is RosterCode ? v : null),
      itemBuilder: (_) => [
        for (final c in RosterCode.values)
          PopupMenuItem(
            value: c,
            child: Row(
              children: [
                _Badge(code: c),
                const SizedBox(width: 12),
                Text(c.label),
              ],
            ),
          ),
        if (allowClear)
          const PopupMenuItem(value: 'clear', child: Text('Clear day')),
      ],
      child: _Badge(code: code),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.code});

  final RosterCode? code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: code?.color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: code == null
            ? Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        code?.short ?? '—',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

/// ‹ Oct 2026 › month switcher.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.min,
    this.max,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? min;
  final DateTime? max;

  @override
  Widget build(BuildContext context) {
    final prev = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous month',
            visualDensity: VisualDensity.compact,
            onPressed: min != null && prev.isBefore(min!)
                ? null
                : () => onChanged(prev),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            Fmt.monthYear(month),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          IconButton(
            tooltip: 'Next month',
            visualDensity: VisualDensity.compact,
            onPressed: max != null && next.isAfter(max!)
                ? null
                : () => onChanged(next),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Back button + centred title used by pushed full-screen pages.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        trailing ?? const SizedBox(width: 48),
      ],
    );
  }
}
