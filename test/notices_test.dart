import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_scope.dart';
import 'package:nurse_companion/core/device_prefs.dart';
import 'package:nurse_companion/core/notices.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/core/social_sign_in.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/data/models.dart';
import 'package:nurse_companion/main.dart';

String en(String t, [Map<String, Object?> a = const {}]) {
  var s = t;
  a.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

void main() {
  final day = DateTime(2026, 10, 13);
  final early = DateTime(2026, 10, 13, 5);

  group('duty notification planner', () {
    test('plans start, forgot-to-start, main-end and OT-end for a 24 duty', () {
      final duty = Shift(
        id: 'd24',
        date: day,
        type: ShiftType.twentyFour,
        otHours: 18,
      );
      final plan = planDutyNotices(
        [duty],
        early,
        const NoticeOptions(lead: Duration(minutes: 15)),
        en,
      );
      final at = {for (final n in plan) n.kind: n.at};
      expect(at[NoticeKind.shiftStart], DateTime(2026, 10, 13, 6, 45));
      expect(at[NoticeKind.forgotStart], DateTime(2026, 10, 13, 7, 15));
      expect(
        at[NoticeKind.mainEnd],
        DateTime(2026, 10, 13, 12, 45),
      ); // 13:00 − 15 min
      expect(
        at[NoticeKind.otEnd],
        DateTime(2026, 10, 14, 6, 45),
      ); // 07:00 +1 − 15 min
      expect(
        plan.firstWhere((n) => n.kind == NoticeKind.forgotStart).body,
        contains('Tap Start duty'),
      );
    });

    test(
      'a long lead applies to the start; end reminders stay within 30 min',
      () {
        final duty = Shift(id: 'm', date: day, type: ShiftType.morning);
        final plan = planDutyNotices(
          [duty],
          early.subtract(const Duration(hours: 2)),
          const NoticeOptions(lead: Duration(hours: 2)),
          en,
        );
        final at = {for (final n in plan) n.kind: n.at};
        expect(at[NoticeKind.shiftStart], DateTime(2026, 10, 13, 5));
        expect(at[NoticeKind.mainEnd], DateTime(2026, 10, 13, 12, 30));
        expect(at.containsKey(NoticeKind.otEnd), isFalse);
      },
    );

    test(
      'once started there is no start nudge; nothing for leave or done duties',
      () {
        final started = Shift(
          id: 's',
          date: day,
          type: ShiftType.morning,
          checkInTime: DateTime(2026, 10, 13, 7, 4),
        );
        final kinds = planDutyNotices(
          [started],
          DateTime(2026, 10, 13, 8),
          const NoticeOptions(),
          en,
        ).map((n) => n.kind);
        expect(kinds, [NoticeKind.mainEnd]);

        final quiet = planDutyNotices(
          [
            Shift(
              id: 'l',
              date: day,
              type: ShiftType.morning,
              status: ShiftStatus.leave,
              leaveType: LeaveType.sick,
            ),
            Shift(
              id: 'c',
              date: day,
              type: ShiftType.morning,
              status: ShiftStatus.completed,
            ),
            Shift(
              id: 'w',
              date: day,
              type: ShiftType.morning,
              status: ShiftStatus.swapped,
            ),
          ],
          early,
          const NoticeOptions(),
          en,
        );
        expect(quiet, isEmpty);
      },
    );

    test('switches turn each kind off', () {
      final plan = planDutyNotices(
        [Shift(id: 'n', date: day, type: ShiftType.night)],
        early,
        const NoticeOptions(forgotStart: false, endReminders: false),
        en,
      );
      expect(plan.map((n) => n.kind), [NoticeKind.shiftStart]);
    });
  });

  group('inbox', () {
    Notice notice(
      int id,
      DateTime at, {
      NoticeKind kind = NoticeKind.shiftStart,
    }) => Notice(id: id, kind: kind, title: 't$id', body: 'b', at: at);

    test(
      'shows what has happened, keeps read state, and survives a restart',
      () async {
        final prefs = MemoryDevicePrefs();
        final inbox = NoticeInbox(prefs);
        final now = DateTime(2026, 10, 13, 12);
        await inbox.replacePlanned([
          notice(1, DateTime(2026, 10, 13, 6)),
          notice(2, DateTime(2026, 10, 13, 18)),
        ], now);
        expect(inbox.visible(now).map((n) => n.id), [1]);
        expect(inbox.unread(now), 1);

        await inbox.markRead(1);
        // Re-planning later drops the future notice, keeps the shown one and its read state.
        await inbox.replacePlanned([notice(3, DateTime(2026, 10, 14, 6))], now);
        expect(inbox.visible(DateTime(2026, 10, 15)).map((n) => n.id), [3, 1]);
        expect(inbox.unread(now), 0);

        final reloaded = NoticeInbox(prefs);
        expect(reloaded.visible(DateTime(2026, 10, 15)).length, 2);
        await reloaded.markAllRead(DateTime(2026, 10, 15));
        expect(reloaded.unread(DateTime(2026, 10, 15)), 0);
      },
    );
  });

  testWidgets(
    'ending a duty posts the day summary and, if pay is missing, a reminder',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 10, 13, 13, 30);
      final repo = MockRepository(today: now, newUser: true);
      final duty = await repo.createShift(
        ShiftDraft(date: day, type: ShiftType.morning),
      );
      await repo.updateShift(
        duty.id,
        ShiftUpdate(action: ShiftAction.checkIn, at: DateTime(2026, 10, 13, 7)),
      );
      final prefs = MemoryDevicePrefs(welcomeSeen: true, guideSeen: true);
      final reminders = MemoryReminderService()..enabled = true;
      await tester.pumpWidget(
        NurseCompanionApp(
          repository: repo,
          auth: AuthController(MockAuthService(repo, signedIn: true)),
          social: FakeSocialSignIn(),
          reminders: reminders,
          prefs: prefs,
          today: () => now,
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      // Bring the duty card well clear of the floating dock, then end the duty.
      await tester.drag(
        find.byType(Scrollable).hitTestable().first,
        const Offset(0, -350),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('End duty'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      final kinds = reminders.shown.map((n) => n.kind).toList();
      expect(kinds, contains(NoticeKind.daySummary));
      expect(kinds, contains(NoticeKind.payDetails));
      final summary = reminders.shown.firstWhere(
        (n) => n.kind == NoticeKind.daySummary,
      );
      expect(summary.title, "Today's summary");
      expect(summary.body, contains('h worked'));

      // Both are in the in-app list too (the summary from its time on).
      final saved = jsonDecode(prefs.read('inbox')!) as List;
      expect(
        saved.map((j) => j['kind']),
        containsAll(['daySummary', 'payDetails']),
      );
    },
  );

  testWidgets(
    'the menu opens notifications, and a pay reminder opens Profile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 10, 13, 12);
      final repo = MockRepository(today: now);
      final prefs = MemoryDevicePrefs(welcomeSeen: true, guideSeen: true);
      await NoticeInbox(prefs).add(
        Notice(
          id: 7,
          kind: NoticeKind.payDetails,
          title: 'Add your pay details',
          body: 'Add your monthly deductions',
          at: DateTime(2026, 10, 13, 9),
          route: NoticeRoute.pay,
        ),
      );
      await tester.pumpWidget(
        NurseCompanionApp(
          repository: repo,
          auth: AuthController(MockAuthService(repo, signedIn: true)),
          social: FakeSocialSignIn(),
          reminders: MemoryReminderService(),
          prefs: prefs,
          today: () => now,
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      await tester.tap(find.bySemanticsLabel('Menu'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Notifications (1)'), findsOneWidget);
      await tester.tap(find.text('Notifications (1)'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(find.text('Add your pay details'), findsOneWidget);
      expect(
        find.text('Welcome to Nurse Companion'),
        findsOneWidget,
      ); // team message

      await tester.tap(find.text('Add your pay details'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(find.text('Pay settings'), findsOneWidget);
    },
  );
}
