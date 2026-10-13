import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/data/models.dart';
import 'package:nurse_companion/features/dashboard/dashboard_vm.dart';
import 'package:nurse_companion/features/dashboard/widgets/active_duty_card.dart';
import 'package:nurse_companion/features/duty/duty_vm.dart';

void main() {
  group('long duties', () {
    final day = DateTime(2026, 10, 13);
    Shift duty(ShiftType type, {double? main, DateTime? checkIn}) => Shift(
      id: 'd1',
      date: day,
      type: type,
      standardHours: main,
      checkInTime: checkIn,
    );

    test('reads the new API fields and roster codes', () {
      final s = Shift.fromJson({
        'id': 'x',
        'date': '2026-10-13',
        'shiftType': 'TwentyFour',
        'status': 'Scheduled',
        'leaveType': 'None',
        'isOT': true,
        'otHours': 18,
        'standardHours': 6,
        'nightAllowanceApplicable': true,
      });
      expect(s.type, ShiftType.twentyFour);
      expect(s.code, '24');
      expect(s.hasAutoOt, isTrue);
      expect(s.nightAllowanceApplicable, isTrue);
      expect(
        Shift.fromJson({
          'id': 'y',
          'date': '2026-10-13',
          'shiftType': 'Morning',
          'status': 'Leave',
          'leaveType': 'Vacation',
        }).code,
        'VL',
      );
    });

    test('a D duty worked as a 12-hour main shift has no automatic OT', () {
      expect(duty(ShiftType.day).hasAutoOt, isTrue);
      expect(duty(ShiftType.day, main: 12).hasAutoOt, isFalse);
      expect(duty(ShiftType.morning).hasAutoOt, isFalse);
    });

    test('progress moves from main shift to OT after the main hours', () {
      final s = duty(ShiftType.twentyFour, checkIn: DateTime(2026, 10, 13, 7));
      final early = DutyProgress.of(s, DateTime(2026, 10, 13, 10));
      expect(early.onOt, isFalse);
      expect(early.mainLeft, const Duration(hours: 3));
      expect(early.planned, const Duration(hours: 24));

      final later = DutyProgress.of(s, DateTime(2026, 10, 14, 1, 30));
      expect(later.onOt, isTrue);
      expect(later.main, const Duration(hours: 6));
      expect(later.ot, const Duration(hours: 12, minutes: 30));
    });

    test('a standard shift stays on the main shift until switched to OT', () {
      final s = duty(ShiftType.morning, checkIn: DateTime(2026, 10, 13, 7));
      final p = DutyProgress.of(s, DateTime(2026, 10, 13, 13, 20));
      expect(p.onOt, isFalse);
      expect(p.mainDone, isTrue);
      expect(p.ot, Duration.zero);
    });

    test('the OT alert fires when the main hours are done', () {
      final s = duty(
        ShiftType.twentyFour,
        checkIn: DateTime(2026, 10, 13, 7, 5),
      );
      expect(
        otTransitionAt(s, DateTime(2026, 10, 13, 8)),
        DateTime(2026, 10, 13, 13, 5),
      );
      expect(otTransitionAt(s, DateTime(2026, 10, 13, 14)), isNull);
      expect(
        otTransitionAt(
          duty(ShiftType.morning, checkIn: DateTime(2026, 10, 13, 7)),
          DateTime(2026, 10, 13, 8),
        ),
        isNull,
      );
    });

    test('the stepper explains automatic OT before check-in', () {
      final steps = stepsFor(duty(ShiftType.day), DateTime(2026, 10, 13, 6));
      expect(steps.last.title, 'OT starts automatically');
      expect(steps.last.detail, contains('01:00 PM'));
    });
  });

  group('model parsing (real API shapes)', () {
    test(
      'Shift.fromJson reads dates as local calendar days and instants as local time',
      () {
        final s = Shift.fromJson({
          'id': '6acd',
          'userId': 'u1',
          'date': '2026-10-13',
          'shiftType': 'Evening',
          'status': 'Completed',
          'leaveType': 'None',
          'isOT': true,
          'otHours': 3.75,
          'checkInTime': '2026-10-13T07:30:00.000Z',
          'otStartTime': '2026-10-13T13:30:00.000Z',
          'otEndTime': '2026-10-13T17:15:00.000Z',
          'createdAt': '2026-10-13T03:56:00.840Z',
        });
        expect(s.date, DateTime(2026, 10, 13));
        expect(s.type, ShiftType.evening);
        expect(s.otHours, 3.75);
        expect(s.checkInTime!.isUtc, isFalse);
        expect(s.otInProgress, isFalse);
        expect(s.nextAction, ShiftAction.checkOut);
      },
    );

    test('SalaryForecast.fromJson maps the predict-salary payload', () {
      final f = SalaryForecast.fromJson({
        'period': {
          'month': 10,
          'year': 2026,
          'daysInMonth': 31,
          'daysElapsed': 12,
          'daysRemaining': 19,
        },
        'currentEarned': {
          'amount': 25975.81,
          'gross': 25975.81,
          'noPayDeducted': 0,
          'breakdown': {
            'basicProRata': 23225.81,
            'allowancesProRata': 0,
            'overtime': 2250,
            'nightAllowance': 500,
          },
        },
        'projectedTotalSalary': {
          'gross': 67625,
          'deductions': 0,
          'net': 67625,
          'range': {'low': 66974, 'high': 68276},
          'breakdown': {
            'baseSalary': 60000,
            'allowances': 0,
            'nightAllowance': {'expectedShifts': 4, 'amount': 2000},
            'overtime': {
              'expectedHours': 15,
              'hourlyRate': 375,
              'amount': 5625,
            },
            'deductions': {
              'configured': 0,
              'noPay': {
                'incurredDays': 0,
                'markedDays': 0,
                'expectedDays': 0,
                'dailyRate': 2000,
                'amount': 0,
              },
            },
          },
          'rosterOnlyNet': 64250,
        },
        'predictedOtHours': {
          'completed': 6,
          'scheduled': 0,
          'expectedExtra': 9,
          'total': 15,
          'range': {'low': 13.3, 'high': 16.7},
          'historicalMonthlyAverage': 12.5,
        },
        'confidenceScore': {
          'percent': 92,
          'level': 'High',
          'factors': {
            'monthElapsed': 0.39,
            'rosterCoverage': 0.74,
            'otConsistency': 0.87,
            'attendanceReliability': 1,
            'historyDepth': 1,
          },
        },
        'historicalPatterns': {
          'monthsWithData': 3,
          'otByWeekday': [
            {
              'weekday': 'Friday',
              'avgOtHoursPerWorkDay': 3,
              'frequency': 1,
              'sampleDays': 13,
              'consistent': true,
            },
          ],
          'consistentOtDays': ['Friday'],
        },
        'assumptions': ['a'],
        'warnings': [],
      });
      expect(f.projectedNet, 67625);
      expect(f.otExpectedExtra, 9);
      expect(f.confidenceLevel, 'High');
      expect(f.consistentOtDays, ['Friday']);
      expect(f.earnedBreakdown['overtime'], 2250);
    });

    test('ShiftUpdate only sends fields that were set', () {
      expect(const ShiftUpdate(action: ShiftAction.switchToOt).toJson(), {
        'action': 'SWITCH_TO_OT',
      });
      expect(
        const ShiftUpdate(leaveType: LeaveType.casual, otHours: 0).toJson(),
        {'leaveType': 'Casual', 'otHours': 0.0},
      );
    });
  });

  group('stepsFor', () {
    final day = DateTime(2026, 10, 13);
    final base = Shift(
      id: '1',
      date: day,
      type: ShiftType.morning,
      otHours: 3,
      isOT: true,
    );

    test('before check-in: check in is the active step', () {
      final steps = stepsFor(base, DateTime(2026, 10, 13, 6, 30));
      expect(steps.map((s) => s.status), [
        StepStatus.active,
        StepStatus.upcoming,
        StepStatus.upcoming,
      ]);
      expect(steps.first.detail, 'Starts in 30 min · 07:00 AM');
      expect(steps.last.detail, 'at 01:30 PM · 3 hrs');
    });

    test('checked in: main shift counts down to the end', () {
      final s = base.copyWith(checkInTime: DateTime(2026, 10, 13, 6, 52));
      final steps = stepsFor(s, DateTime(2026, 10, 13, 12, 15));
      expect(steps[0].title, 'Check-in done');
      expect(steps[0].detail, 'Signed in at 06:52 AM');
      expect(steps[1].detail, 'in 45 min · 01:00 PM');
      expect(steps[1].status, StepStatus.active);
    });

    test('OT in progress after switching', () {
      final s = base.copyWith(
        checkInTime: DateTime(2026, 10, 13, 7),
        checkOutTime: DateTime(2026, 10, 13, 13),
        otStartTime: DateTime(2026, 10, 13, 13),
      );
      final steps = stepsFor(s, DateTime(2026, 10, 13, 14));
      expect(steps.map((e) => e.status), [
        StepStatus.done,
        StepStatus.done,
        StepStatus.active,
      ]);
      expect(s.nextAction, ShiftAction.endOt);
    });
  });

  group('view models from the demo repository', () {
    final today = DateTime(2026, 10, 13);
    final repo = MockRepository(today: today);

    test(
      'dashboard: today is the checked-in morning shift and the next shift is tomorrow',
      () async {
        final data = DashboardData.build(
          user: await repo.me(),
          forecast: await repo.forecast(month: 10, year: 2026),
          monthShifts: await repo.shifts(
            from: DateTime(2026, 10),
            to: DateTime(2026, 10, 31),
          ),
          upcoming: await repo.shifts(from: today, to: DateTime(2026, 10, 27)),
          now: DateTime(2026, 10, 13, 12, 15),
        );
        expect(data.today!.type, ShiftType.morning);
        expect(data.today!.nextAction, ShiftAction.checkOut);
        expect(data.next!.date, DateTime(2026, 10, 14));
        expect(data.weeklyEarnings, hasLength(5)); // 31 days → 5 week buckets
        expect(data.weekLabels.first, 'W1');
        expect(data.avgDailyOtHours, greaterThan(0));
      },
    );

    test('duty: completion, leave balances and week hours', () async {
      final data = DutyData.build(
        user: await repo.me(),
        shifts: await repo.shifts(
          from: DateTime(2026, 9, 29),
          to: DateTime(2026, 11, 3),
        ),
        yearLeave: await repo.shifts(
          from: DateTime(2026),
          to: today,
          status: ShiftStatus.leave,
        ),
        today: today,
      );
      expect(data.completion, inInclusiveRange(0.0, 1.0));
      expect(data.dueShifts, greaterThan(0));
      expect(data.leave.first.name, 'Casual leave');
      expect(
        data.leave.first.used,
        2,
      ); // seeded casual leaves on day −9 and −40
      final week = data.weekOf(today);
      expect(week.first.date.weekday, DateTime.monday);
      expect(week, hasLength(7));
    });
  });

  group('shift reminders', () {
    test('one per upcoming rostered work shift, an hour before it starts', () {
      final now = DateTime(2026, 10, 13, 12, 15);
      final shifts = [
        Shift(
          id: 'past',
          date: DateTime(2026, 10, 13),
          type: ShiftType.morning,
        ), // 06:00 already passed
        Shift(
          id: 'eve',
          date: DateTime(2026, 10, 13),
          type: ShiftType.evening,
        ), // 12:00 just passed
        Shift(id: 'night', date: DateTime(2026, 10, 13), type: ShiftType.night),
        Shift(id: 'off', date: DateTime(2026, 10, 14), type: ShiftType.off),
        Shift(
          id: 'leave',
          date: DateTime(2026, 10, 15),
          type: ShiftType.morning,
          status: ShiftStatus.leave,
          leaveType: LeaveType.casual,
        ),
        Shift(id: 'm16', date: DateTime(2026, 10, 16), type: ShiftType.morning),
      ];
      final planned = plannedReminders(shifts, now);
      expect(planned.map((r) => r.shift.id), ['night', 'm16']);
      expect(planned.first.at, DateTime(2026, 10, 13, 18));
      expect(planned.last.at, DateTime(2026, 10, 16, 6));
    });
  });

  group('progressive profile parsing', () {
    test('accounts from before onboarding existed count as complete', () {
      final legacy = UserProfile.fromJson({
        'id': '1',
        'fullName': 'A B',
        'email': 'a@b.lk',
        'baseSalary': 60000,
      });
      expect(legacy.salarySetup, OnboardingState.completed);
      expect(legacy.salaryIsEstimate, isFalse);
    });

    test(
      'a phone-only new account uses the estimate and shows its mobile as contact',
      () {
        final fresh = UserProfile.fromJson({
          'id': '2',
          'fullName': 'Kumari Silva',
          'phone': '+94712345678',
          'baseSalary': 0,
          'onboarding': {'salary': 'skipped', 'workplace': 'pending'},
          'providers': ['google'],
          'hasPassword': false,
        });
        expect(fresh.salaryIsEstimate, isTrue);
        expect(fresh.workplaceSetup, OnboardingState.pending);
        expect(fresh.contact, '+94712345678');
        expect(fresh.providers, [SignInProvider.google]);
      },
    );

    test('register request sends email or phone from one box', () {
      expect(
        const RegisterRequest(
          fullName: 'A',
          emailOrPhone: ' a@b.lk ',
          password: 'p',
        ).toJson(),
        {'fullName': 'A', 'email': 'a@b.lk', 'password': 'p'},
      );
      expect(
        const RegisterRequest(
          fullName: 'A',
          emailOrPhone: '0771234567',
          password: 'p',
        ).toJson()['phone'],
        '0771234567',
      );
    });
  });
}
