import '../../core/format.dart';
import '../../data/models.dart';

enum StepStatus { done, active, upcoming }

class ShiftStep {
  const ShiftStep({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final StepStatus status;
}

/// Everything the dashboard shows, derived from API data.
class DashboardData {
  const DashboardData({
    required this.user,
    required this.forecast,
    required this.weeklyEarnings,
    required this.weekLabels,
    required this.completedOtHours,
    required this.avgDailyOtHours,
    required this.today,
    required this.next,
  });

  final UserProfile user;
  final SalaryForecast forecast;
  final List<double> weeklyEarnings;
  final List<String> weekLabels;
  final double completedOtHours;
  final double avgDailyOtHours;

  /// Today's main entry (null when nothing is rostered).
  final Shift? today;

  /// Next rostered work shift after today.
  final Shift? next;

  static DashboardData build({
    required UserProfile user,
    required SalaryForecast forecast,
    required List<Shift> monthShifts,
    required List<Shift> upcoming,
    required DateTime now,
  }) {
    final today = dayOf(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Week buckets: days 1–7, 8–14, … of the month. The last bucket is usually a
    // partial week, so every bucket is scaled to a 7-day rate; otherwise the wave
    // would always "drop" at the end of the month.
    final weeks = (daysInMonth / 7).ceil();
    final bucketDays = [
      for (var w = 0; w < weeks; w++) (daysInMonth - w * 7).clamp(1, 7),
    ];
    final variable = List<double>.filled(weeks, 0);
    final completedWorkDays = <DateTime>{};
    for (final s in monthShifts) {
      if (s.isLeave || s.status == ShiftStatus.missed) continue;
      final w = ((s.date.day - 1) ~/ 7).clamp(0, weeks - 1);
      variable[w] += s.otHours * forecast.otHourlyRate;
      if (s.nightAllowanceApplicable) variable[w] += user.defaultNightAllowance;
      if (s.isWorked) completedWorkDays.add(s.date);
    }
    // The forecast's "likely extra" OT (habits not yet on the roster) is spread evenly
    // over the remaining days, so future weeks match the predicted total.
    final remainingDays = daysInMonth - today.day + 1;
    if (remainingDays > 0 && forecast.otExpectedExtra > 0) {
      final perDay =
          forecast.otExpectedExtra * forecast.otHourlyRate / remainingDays;
      for (var day = today.day; day <= daysInMonth; day++) {
        variable[((day - 1) ~/ 7).clamp(0, weeks - 1)] += perDay;
      }
    }
    final fixedPerWeek =
        (forecast.baseSalary + forecast.allowances) * 7 / daysInMonth;
    final weekly = [
      for (var w = 0; w < weeks; w++)
        fixedPerWeek + variable[w] * 7 / bucketDays[w],
    ];

    final completedOt = forecast.otCompleted;
    return DashboardData(
      user: user,
      forecast: forecast,
      weeklyEarnings: weekly,
      weekLabels: [for (var w = 1; w <= weeks; w++) 'W$w'],
      completedOtHours: completedOt,
      avgDailyOtHours: completedWorkDays.isEmpty
          ? 0
          : completedOt / completedWorkDays.length,
      today: primaryShiftOn(today, monthShifts),
      next: upcoming
          .where(
            (s) =>
                s.date.isAfter(today) && s.type != ShiftType.off && !s.isLeave,
          )
          .fold<Shift?>(
            null,
            (best, s) => best == null || s.date.isBefore(best.date) ? s : best,
          ),
    );
  }
}

/// The entry to show for a day: an in-progress or unfinished work shift first,
/// then leave, then anything else (e.g. Off).
Shift? primaryShiftOn(DateTime day, List<Shift> shifts) {
  final onDay = shifts.where((s) => sameDay(s.date, day)).toList();
  if (onDay.isEmpty) return null;
  int rank(Shift s) {
    if (s.nextAction != null) return 0;
    if (s.isWork && !s.isLeave) return 1;
    if (s.isLeave) return 2;
    return 3;
  }

  onDay.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.type.startHour.compareTo(b.type.startHour);
  });
  return onDay.first;
}

/// The check-in → main shift → OT stepper for a work shift.
List<ShiftStep> stepsFor(Shift s, DateTime now) {
  final rostered = s.type.window(s.date);
  // A standard shift ends at its rostered time; on a long duty OT starts automatically
  // once the main hours since check-in are done.
  final mainStart = s.hasAutoOt
      ? (s.checkInTime ?? rostered.start)
      : rostered.start;
  final window = (
    start: rostered.start,
    end: mainStart.add(Duration(minutes: (s.standardHours * 60).round())),
  );

  final checkIn = s.checkInTime != null
      ? ShiftStep(
          title: 'Check-in done',
          detail: 'Signed in at ${Fmt.time(s.checkInTime!)}',
          status: StepStatus.done,
        )
      : ShiftStep(
          title: 'Check in',
          detail: now.isBefore(window.start)
              ? 'Starts ${Fmt.relative(window.start, now)} · ${Fmt.time(window.start)}'
              : 'Shift started at ${Fmt.time(window.start)}',
          status: StepStatus.active,
        );

  final ShiftStep main;
  if (s.checkOutTime != null) {
    main = ShiftStep(
      title: 'Main shift done',
      detail: 'Signed out at ${Fmt.time(s.checkOutTime!)}',
      status: StepStatus.done,
    );
  } else if (s.checkInTime != null) {
    main = ShiftStep(
      title: now.isBefore(window.end)
          ? 'Main shift ending'
          : 'Main shift ended',
      detail: now.isBefore(window.end)
          ? '${Fmt.relative(window.end, now)} · ${Fmt.time(window.end)}'
          : 'Ended ${Fmt.time(window.end)} · sign out',
      status: StepStatus.active,
    );
  } else {
    main = ShiftStep(
      title: 'Main shift',
      detail: 'Ends at ${Fmt.time(window.end)}',
      status: StepStatus.upcoming,
    );
  }

  final ShiftStep ot;
  if (s.otEndTime != null) {
    ot = ShiftStep(
      title: 'OT done',
      detail: '${Fmt.hours(s.otHours)} hrs logged',
      status: StepStatus.done,
    );
  } else if (s.otStartTime != null) {
    ot = ShiftStep(
      title: 'OT in progress',
      detail: 'Started at ${Fmt.time(s.otStartTime!)}',
      status: StepStatus.active,
    );
  } else if (s.hasAutoOt) {
    ot = ShiftStep(
      title: 'OT starts automatically',
      detail:
          'at ${Fmt.time(window.end)} · ${Fmt.hours(s.type.spanHours - s.standardHours)} hrs, no sign-out needed',
      status: StepStatus.upcoming,
    );
  } else if (s.otHours > 0) {
    final otStart = window.end.add(const Duration(minutes: 30));
    ot = ShiftStep(
      title: 'OT shift starting',
      detail: 'at ${Fmt.time(otStart)} · ${Fmt.hours(s.otHours)} hrs',
      status: StepStatus.upcoming,
    );
  } else {
    ot = const ShiftStep(
      title: 'OT (optional)',
      detail: 'Switch to OT when you sign out',
      status: StepStatus.upcoming,
    );
  }

  return [checkIn, main, ot];
}
