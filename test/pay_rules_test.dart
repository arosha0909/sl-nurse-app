import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_scope.dart';
import 'package:nurse_companion/core/device_prefs.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/core/social_sign_in.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/data/models.dart';
import 'package:nurse_companion/features/dashboard/dashboard_vm.dart';
import 'package:nurse_companion/features/duty/duty_vm.dart';
import 'package:nurse_companion/main.dart';

final now = DateTime(2026, 10, 13, 12, 15);

Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(Duration(milliseconds: ms ~/ 10));
  }
}

Future<MockRepository> pump(WidgetTester tester, {int tab = 0}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = MockRepository(today: now);
  await tester.pumpWidget(
    NurseCompanionApp(
      repository: repo,
      auth: AuthController(MockAuthService(repo, signedIn: true)),
      social: FakeSocialSignIn(),
      reminders: MemoryReminderService(),
      prefs: MemoryDevicePrefs(welcomeSeen: true, guideSeen: true),
      initialTab: tab,
      today: () => now,
    ),
  );
  await settle(tester);
  return repo;
}

final visibleList = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .hitTestable()
    .first;

Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: visibleList);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('sleep day', () {
    final day = DateTime(2026, 10, 13);
    Shift shift(DateTime d, ShiftType t, {ShiftStatus? status}) => Shift(
      id: '${d.day}${t.name}',
      date: d,
      type: t,
      status: status ?? ShiftStatus.scheduled,
    );

    test('follows a night or 24-hour duty when today has no duty', () {
      final yesterday = DateTime(2026, 10, 12);
      expect(isSleepDay(day, [shift(yesterday, ShiftType.night)]), isTrue);
      expect(isSleepDay(day, [shift(yesterday, ShiftType.twentyFour)]), isTrue);
      expect(
        isSleepDay(day, [
          shift(yesterday, ShiftType.night),
          shift(day, ShiftType.off),
        ]),
        isTrue,
      );
    });

    test('not after a day duty, a swapped night, or when working today', () {
      final yesterday = DateTime(2026, 10, 12);
      expect(isSleepDay(day, [shift(yesterday, ShiftType.morning)]), isFalse);
      expect(
        isSleepDay(day, [
          shift(yesterday, ShiftType.night, status: ShiftStatus.swapped),
        ]),
        isFalse,
      );
      expect(
        isSleepDay(day, [
          shift(yesterday, ShiftType.night),
          shift(day, ShiftType.night),
        ]),
        isFalse,
      );
    });
  });

  test('leave balances use the pay-rule entitlements, with vacation', () {
    final data = DutyData.build(
      shifts: const [],
      yearLeave: [
        Shift(
          id: 'v',
          date: DateTime(2026, 3, 2),
          type: ShiftType.morning,
          status: ShiftStatus.leave,
          leaveType: LeaveType.vacation,
        ),
      ],
      user: const UserProfile(
        id: 'u',
        fullName: 'N',
        email: '',
        phone: '',
        hospitalOrWard: '',
        baseSalary: 0,
        defaultNightAllowance: 0,
        defaultOtHourlyRate: 0,
      ),
      today: now,
      entitlements: const LeaveEntitlements(casual: 21, vacation: 24, sick: 0),
    );
    final vacation = data.leave.firstWhere((l) => l.name == 'Vacation leave');
    expect(vacation.used, 1);
    expect(vacation.entitled, 24);
    expect(data.leave.map((l) => l.name), contains('Casual leave'));
  });

  test('salary scale basic is capped at the top step', () {
    const s = SalaryScale(
      code: 'X',
      name: 'X',
      initial: 50000,
      increment: 1000,
      steps: 10,
    );
    expect(s.basicAt(3), 53000);
    expect(s.basicAt(25), 60000);
  });

  testWidgets('swap a duty with a colleague and take theirs', (tester) async {
    final repo = await pump(tester);
    final upcoming = (await repo.shifts(
      from: DateTime(2026, 10, 14),
      to: DateTime(2026, 10, 14),
    )).first;

    await tester.tap(find.byTooltip('Roster'));
    await settle(tester);
    await tester.tap(find.text('14'));
    await settle(tester);
    await reveal(tester, find.textContaining('· Wed'));
    await tester.tap(find.textContaining('· Wed').first);
    await settle(tester);

    await tester.scrollUntilVisible(
      find.text('Swap with a colleague'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Swap with a colleague'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'K. Perera');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Swap'));
    await settle(tester);

    final after = (await repo.shifts(
      from: DateTime(2026, 10, 14),
      to: DateTime(2026, 10, 15),
    ));
    final given = after.firstWhere((s) => s.id == upcoming.id);
    expect(given.status, ShiftStatus.swapped);
    expect(given.swappedWith, 'K. Perera');
    expect(given.code, 'SW');
    expect(after.where((s) => s.swappedWith == 'K. Perera').length, 2);
  });

  testWidgets('pay rules: grade sets the basic salary, monthly OT mode saved', (
    tester,
  ) async {
    final repo = await pump(tester, tab: 3);
    await reveal(tester, find.text('Pay rules'));
    await tester.tap(find.text('Pay rules'));
    await settle(tester);
    expect(find.text('Salary grade'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester, 600);
    await tester.tap(find.text('Nursing Officer – Grade II (sample)').last);
    await settle(tester, 600);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Increase').first);
      await tester.pump();
    }
    expect(find.textContaining('LKR 63,600'), findsOneWidget);

    await reveal(tester, find.text('From monthly hours'));
    await tester.tap(find.text('From monthly hours'));
    await tester.pump();
    expect(find.text('Required hours a month'), findsOneWidget);
    await tester.tap(find.text('Save pay rules'));
    await settle(tester);

    expect((await repo.salaryConfig()).otMode, OtMode.monthlyHours);
    expect((await repo.salaryConfig()).gradeCode, 'NO-II');
    expect((await repo.me()).baseSalary, 63600);
  });
}
