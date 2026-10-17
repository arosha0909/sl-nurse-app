import '../../data/models.dart';

class LeaveBalance {
  const LeaveBalance({
    required this.name,
    required this.used,
    required this.entitled,
  });

  final String name;
  final double used;
  final double entitled;
}

class DayHours {
  const DayHours({required this.date, required this.main, required this.ot});

  final DateTime date;
  final double main;
  final double ot;
}

/// Duty & roster summary for the month of [month] plus the year's leave.
class DutyData {
  const DutyData({
    required this.shifts,
    required this.completedShifts,
    required this.dueShifts,
    required this.otHoursMonth,
    required this.otTrend,
    required this.leave,
    required this.nightAllowanceEarned,
    required this.noPayDays,
  });

  /// Every loaded shift (carousel window ∪ month).
  final List<Shift> shifts;

  /// Worked shifts this month up to today.
  final int completedShifts;

  /// Work shifts this month that were due by today (worked, missed or unconfirmed).
  final int dueShifts;
  final double otHoursMonth;

  /// Cumulative OT hours by day of the month so far (at least two points).
  final List<double> otTrend;
  final List<LeaveBalance> leave;
  final double nightAllowanceEarned;
  final double noPayDays;

  double get completion => dueShifts == 0 ? 0 : completedShifts / dueShifts;

  static DutyData build({
    required List<Shift> shifts,
    required List<Shift> yearLeave,
    required UserProfile user,
    required DateTime today,
    LeaveEntitlements entitlements = const LeaveEntitlements(),
  }) {
    final monthShifts = shifts
        .where((s) => s.date.year == today.year && s.date.month == today.month)
        .toList();
    final due = monthShifts.where(
      (s) => !s.date.isAfter(today) && s.isWork && !s.isLeave,
    );
    final worked = monthShifts.where((s) => s.isWorked);

    // Running OT total by day of the month, up to today (always rising, ≥ 2 points).
    final trend = List<double>.filled(today.day < 2 ? 2 : today.day, 0);
    for (final s in worked) {
      if (s.date.day <= trend.length) trend[s.date.day - 1] += s.otHours;
    }
    for (var i = 1; i < trend.length; i++) {
      trend[i] += trend[i - 1];
    }

    double count(LeaveType t) =>
        yearLeave.where((s) => s.leaveType == t).length.toDouble();
    final halfDays =
        count(LeaveType.halfDay) * 0.5; // half days come out of casual leave

    return DutyData(
      shifts: shifts,
      completedShifts: worked.where((s) => !s.date.isAfter(today)).length,
      dueShifts: due.length,
      otHoursMonth: worked.fold(0, (sum, s) => sum + s.otHours),
      otTrend: trend,
      leave: [
        // Entitlements come from the nurse's pay rules (Profile → Pay rules).
        LeaveBalance(
          name: 'Casual leave',
          used: count(LeaveType.casual) + halfDays,
          entitled: entitlements.casual.toDouble(),
        ),
        LeaveBalance(
          name: 'Vacation leave',
          used: count(LeaveType.vacation),
          entitled: entitlements.vacation.toDouble(),
        ),
        LeaveBalance(
          name: 'Sick leave',
          used: count(LeaveType.sick),
          entitled: entitlements.sick.toDouble(),
        ),
      ],
      nightAllowanceEarned:
          worked.where((s) => s.nightAllowanceApplicable).length *
          user.defaultNightAllowance,
      noPayDays: monthShifts
          .where(
            (s) =>
                s.leaveType == LeaveType.noPay ||
                s.status == ShiftStatus.missed,
          )
          .map((s) => s.date)
          .toSet()
          .length
          .toDouble(),
    );
  }

  List<Shift> on(DateTime day) =>
      shifts.where((s) => sameDay(s.date, day)).toList();

  /// Monday–Sunday hours for the week containing [day].
  List<DayHours> weekOf(DateTime day) {
    final monday = DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - DateTime.monday),
    );
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(monday.year, monday.month, monday.day + i);
          final list = on(
            d,
          ).where((s) => !s.isLeave && s.status != ShiftStatus.missed);
          return DayHours(
            date: d,
            main: list.fold(0, (sum, s) => sum + s.mainHours),
            ot: list.fold(0, (sum, s) => sum + s.otHours),
          );
        }(),
    ];
  }
}
