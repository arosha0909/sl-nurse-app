// End-to-end contract test against a running sl-nurse-api.
//
//   API_BASE_URL=http://localhost:4000 flutter test test_live/
//
// Not part of `flutter test` (it lives outside test/) because it needs a live server.
// Uses the app's real ApiClient / ApiRepository / ApiAuthService, so it verifies the
// JSON contracts and the view models against genuine responses.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/network/api_client.dart';
import 'package:nurse_companion/core/network/token_store.dart';
import 'package:nurse_companion/data/api_repository.dart';
import 'package:nurse_companion/data/models.dart';
import 'package:nurse_companion/features/dashboard/dashboard_vm.dart';
import 'package:nurse_companion/features/duty/duty_vm.dart';

void main() {
  final base = Platform.environment['API_BASE_URL'] ?? 'http://localhost:4000';
  final tokens = MemoryTokenStore();
  final api = ApiClient(baseUrl: base, tokens: tokens);
  final repo = ApiRepository(api);
  final auth = ApiAuthService(api);
  final now = DateTime.now();
  final today = dayOf(now);
  final email = 'live${now.millisecondsSinceEpoch}@example.lk';
  // Unique mobile per run: 07X XXX XXXX built from the clock.
  final mobile =
      '07${(now.millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}';

  test(
    '3-field sign-up → estimate → progressive profile → pay config',
    () async {
      final result = await auth.register(
        RegisterRequest(
          fullName: 'Live Test Nurse',
          emailOrPhone: email,
          password: 'Passw0rd!',
        ),
      );
      expect(result.isNewUser, isTrue);
      expect(result.user.salarySetup, OnboardingState.pending);
      expect(result.user.workplaceSetup, OnboardingState.pending);
      expect(result.user.salaryIsEstimate, isTrue);
      expect(await auth.restore(), isNotNull);

      // Forecast works immediately, on the admin-configured typical salary.
      final estimate = await repo.forecast(
        month: today.month,
        year: today.year,
      );
      expect(estimate.salaryIsEstimate, isTrue);
      expect(estimate.baseSalary, greaterThan(0));

      // Skip, then later supply: supplying data completes the step.
      expect(
        (await repo.updateProfile({
          'onboarding': {'salary': 'skipped'},
        })).salarySetup,
        OnboardingState.skipped,
      );
      final paid = await repo.updateProfile({
        'baseSalary': 96000,
        'defaultNightAllowance': 750,
        'phone': mobile,
      });
      expect(paid.salarySetup, OnboardingState.completed);
      expect(paid.salaryIsEstimate, isFalse);
      expect(
        (await repo.forecast(
          month: today.month,
          year: today.year,
        )).salaryIsEstimate,
        isFalse,
      );

      final updated = await repo.updateProfile({'hospitalOrWard': 'Ward 12'});
      expect(updated.hospitalOrWard, 'Ward 12');
      expect(updated.workplaceSetup, OnboardingState.completed);
      expect(updated.defaultNightAllowance, 750);

      final config = await repo.salaryConfig();
      final saved = await repo.updateSalaryConfig(
        config.copyWith(
          allowances: [const NamedAmount('COLA', 7800)],
          deductions: [const NamedAmount('W&OP', 4800)],
        ),
      );
      expect(saved.allowances.single.amount, 7800);
    },
  );

  test('roster import, shift workflow and duty view model', () async {
    // Three months of history plus this month, via the bulk endpoint.
    final drafts = <ShiftDraft>[];
    for (var offset = -95; offset <= 20; offset++) {
      final date = DateTime(today.year, today.month, today.day + offset);
      if (date.weekday >= DateTime.saturday) continue;
      drafts.add(
        ShiftDraft(
          date: date,
          type: date.weekday == DateTime.wednesday
              ? ShiftType.night
              : ShiftType.morning,
          status: offset < 0 ? ShiftStatus.completed : ShiftStatus.scheduled,
          otHours: offset < 0 && date.weekday == DateTime.friday ? 3 : 0,
        ),
      );
    }
    final bulk = await repo.bulkShifts(drafts);
    expect(bulk.inserted, drafts.length);

    final month = await repo.shifts(
      from: DateTime(today.year, today.month),
      to: DateTime(today.year, today.month + 1, 0),
    );
    expect(month, isNotEmpty);

    // Workflow on today's shift (create one if today is a weekend).
    var shift =
        month.where((s) => sameDay(s.date, today)).firstOrNull ??
        await repo.createShift(
          ShiftDraft(date: today, type: ShiftType.evening),
        );
    shift = await repo.updateShift(
      shift.id,
      ShiftUpdate(
        action: ShiftAction.checkIn,
        at: now.subtract(const Duration(hours: 6)),
      ),
    );
    expect(shift.nextAction, ShiftAction.checkOut);
    shift = await repo.updateShift(
      shift.id,
      ShiftUpdate(
        action: ShiftAction.switchToOt,
        at: now.subtract(const Duration(hours: 2)),
      ),
    );
    expect(shift.otInProgress, isTrue);
    shift = await repo.updateShift(
      shift.id,
      ShiftUpdate(action: ShiftAction.endOt, at: now),
    );
    expect(shift.otHours, 2);
    expect(shift.status, ShiftStatus.completed);

    // Leave toggle rules as the dashboard sends them.
    final leave = await repo.updateShift(
      shift.id,
      const ShiftUpdate(leaveType: LeaveType.casual, otHours: 0),
    );
    expect(leave.isLeave, isTrue);
    final back = await repo.updateShift(
      shift.id,
      const ShiftUpdate(
        status: ShiftStatus.scheduled,
        leaveType: LeaveType.none,
      ),
    );
    expect(back.isLeave, isFalse);

    final duty = DutyData.build(
      user: await repo.me(),
      shifts: await repo.shifts(
        from: today.subtract(const Duration(days: 14)),
        to: today.add(const Duration(days: 21)),
      ),
      yearLeave: await repo.shifts(
        from: DateTime(today.year),
        to: today,
        status: ShiftStatus.leave,
      ),
      today: today,
    );
    expect(duty.weekOf(today), hasLength(7));
  });

  test('roster scan: on-device text and image upload', () async {
    final text = await repo.scanRoster(
      month: today.month,
      year: today.year,
      rawText: '01 M\n02 N OT 4\n03 CL',
    );
    expect(text.shifts, hasLength(3));
    expect(text.shifts[1].otHours, 4);
    expect(text.shifts[2].leaveType, LeaveType.casual);

    // Minimal JPEG signature; the server's mock OCR returns a sample month.
    final jpeg = [0xff, 0xd8, 0xff, 0xe0, 0, 16, 74, 70, 73, 70, 0, 1];
    final image = await repo.scanRoster(
      month: today.month,
      year: today.year,
      imageBytes: jpeg,
      filename: 'roster.jpg',
      mimeType: 'image/jpeg',
    );
    expect(image.shifts.length, greaterThanOrEqualTo(28));
    expect(image.provider, 'mock');

    await expectLater(
      repo.scanRoster(
        month: today.month,
        year: today.year,
        imageBytes: [1, 2, 3, 4],
        mimeType: 'image/jpeg',
      ),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
    );
  });

  test('analytics endpoints parse and feed the dashboard', () async {
    final forecast = await repo.forecast(month: today.month, year: today.year);
    expect(forecast.monthsWithData, greaterThanOrEqualTo(2));
    expect(forecast.consistentOtDays, contains('Friday'));
    expect(forecast.projectedNet, greaterThan(0));

    final trends = await repo.workTrends();
    expect(trends.workedShifts, greaterThan(0));
    expect(trends.burnoutLevel, isIn(['Low', 'Moderate', 'High']));

    final data = DashboardData.build(
      user: await repo.me(),
      forecast: forecast,
      monthShifts: await repo.shifts(
        from: DateTime(today.year, today.month),
        to: DateTime(today.year, today.month + 1, 0),
      ),
      upcoming: await repo.shifts(
        from: today,
        to: today.add(const Duration(days: 14)),
      ),
      now: now,
    );
    expect(data.weeklyEarnings.length, greaterThanOrEqualTo(4));
    expect(data.user.firstName, 'Live');
  });

  test(
    'validation errors surface per field; logout ends the session',
    () async {
      await expectLater(
        auth.register(
          const RegisterRequest(
            fullName: 'X Y',
            emailOrPhone: '123',
            password: 'Passw0rd!',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fieldErrors.keys,
            'fields',
            contains('phone'),
          ),
        ),
      );
      // The same mobile can't open a second account.
      await expectLater(
        auth.register(
          RegisterRequest(
            fullName: 'Copy Cat',
            emailOrPhone: mobile,
            password: 'Passw0rd!',
          ),
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );

      await auth.logout();
      expect(await tokens.read(), isNull);
      expect(await auth.restore(), isNull);
      await expectLater(
        auth.login(email, 'wrong-pass1'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
      final again = await auth.login(email, 'Passw0rd!');
      expect(again.user.hospitalOrWard, 'Ward 12');
      expect(again.isNewUser, isFalse);
      // Same account, signing in with the mobile number instead.
      final byPhone = await auth.login(mobile, 'Passw0rd!');
      expect(byPhone.user.email, email);

      // Social providers are off until client IDs are configured on the API.
      expect(await auth.enabledProviders(), isEmpty);
    },
  );
}
