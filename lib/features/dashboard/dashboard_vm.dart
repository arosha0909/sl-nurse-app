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
    this.sleepDay = false,
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

  /// Today is the rest day after a night / 24-hour duty that ended this morning.
  final bool sleepDay;

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
      // Yesterday may be last month (loaded for the sleep-day check).
      if (s.date.month != now.month || s.date.year != now.year) continue;
      if (s.isLeave || s.isSwapped || s.status == ShiftStatus.missed) continue;
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
      sleepDay: isSleepDay(today, monthShifts),
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

/// A sleep day: no duty today, and yesterday's duty ran overnight into this morning
/// (a Night or 24-hour duty that was worked or is still planned).
bool isSleepDay(DateTime day, List<Shift> shifts) {
  final today = shifts.where((s) => sameDay(s.date, day));
  if (today.any((s) => s.isWork && !s.isLeave)) return false;
  final yesterday = DateTime(day.year, day.month, day.day - 1);
  return shifts.any(
    (s) =>
        sameDay(s.date, yesterday) &&
        (s.type == ShiftType.night || s.type == ShiftType.twentyFour) &&
        !s.isLeave &&
        !s.isSwapped &&
        s.status != ShiftStatus.missed,
  );
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

/// Translates a step text; the default keeps English (tests, plain use).
typedef StepTranslator =
    String Function(String text, [Map<String, Object?> args]);

String _english(String text, [Map<String, Object?> args = const {}]) {
  var s = text;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// The check-in → main shift → OT stepper for a work shift.
List<ShiftStep> stepsFor(
  Shift s,
  DateTime now, [
  StepTranslator tr = _english,
]) {
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
          title: tr('Check-in done'),
          detail: tr('Signed in at {time}', {'time': Fmt.time(s.checkInTime!)}),
          status: StepStatus.done,
        )
      : ShiftStep(
          title: tr('Check in'),
          detail: now.isBefore(window.start)
              ? tr('Starts {when} · {time}', {
                  'when': Fmt.relative(window.start, now),
                  'time': Fmt.time(window.start),
                })
              : tr('Shift started at {time}', {'time': Fmt.time(window.start)}),
          status: StepStatus.active,
        );

  final ShiftStep main;
  if (s.checkOutTime != null) {
    main = ShiftStep(
      title: tr('Main shift done'),
      detail: tr('Signed out at {time}', {'time': Fmt.time(s.checkOutTime!)}),
      status: StepStatus.done,
    );
  } else if (s.checkInTime != null) {
    main = ShiftStep(
      title: now.isBefore(window.end)
          ? tr('Main shift ending')
          : tr('Main shift ended'),
      detail: now.isBefore(window.end)
          ? '${Fmt.relative(window.end, now)} · ${Fmt.time(window.end)}'
          : tr('Ended {time} · sign out', {'time': Fmt.time(window.end)}),
      status: StepStatus.active,
    );
  } else {
    main = ShiftStep(
      title: tr('Main shift'),
      detail: tr('Ends at {time}', {'time': Fmt.time(window.end)}),
      status: StepStatus.upcoming,
    );
  }

  final ShiftStep ot;
  if (s.otEndTime != null) {
    ot = ShiftStep(
      title: tr('OT done'),
      detail: tr('{hours} hrs logged', {'hours': Fmt.hours(s.otHours)}),
      status: StepStatus.done,
    );
  } else if (s.otStartTime != null) {
    ot = ShiftStep(
      title: tr('OT in progress'),
      detail: tr('Started at {time}', {'time': Fmt.time(s.otStartTime!)}),
      status: StepStatus.active,
    );
  } else if (s.hasAutoOt) {
    ot = ShiftStep(
      title: tr('OT starts automatically'),
      detail: tr('at {time} · {hours} hrs, no sign-out needed', {
        'time': Fmt.time(window.end),
        'hours': Fmt.hours(s.type.spanHours - s.standardHours),
      }),
      status: StepStatus.upcoming,
    );
  } else if (s.otHours > 0) {
    final otStart = window.end.add(const Duration(minutes: 30));
    ot = ShiftStep(
      title: tr('OT shift starting'),
      detail: tr('at {time} · {hours} hrs', {
        'time': Fmt.time(otStart),
        'hours': Fmt.hours(s.otHours),
      }),
      status: StepStatus.upcoming,
    );
  } else {
    ot = ShiftStep(
      title: tr('OT (optional)'),
      detail: tr('Switch to OT when you sign out'),
      status: StepStatus.upcoming,
    );
  }

  return [checkIn, main, ot];
}
