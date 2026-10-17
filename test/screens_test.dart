import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_scope.dart';
import 'package:nurse_companion/core/app_settings.dart';
import 'package:nurse_companion/core/config.dart';
import 'package:nurse_companion/core/i18n/i18n.dart';
import 'package:nurse_companion/core/device_prefs.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/core/social_sign_in.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/data/models.dart';
import 'package:nurse_companion/features/dashboard/widgets/active_duty_card.dart';
import 'package:nurse_companion/features/duty/widgets/date_selector.dart';
import 'package:nurse_companion/main.dart';

/// Phone and tablet sizes. A RenderFlex overflow throws in tests, so pumping
/// every screen at each size catches layout bugs.
const sizes = {
  'small phone (320x640)': Size(320, 640),
  'phone (390x844)': Size(390, 844),
  'tablet (820x1180)': Size(820, 1180),
};

/// Tuesday 13 Oct 2026, 12:15: the demo's morning shift is checked in and ending soon.
final now = DateTime(2026, 10, 13, 12, 15);

/// The visible tab's vertical list. IndexedStack keeps every tab mounted,
/// so the default finder would match several scrollables.
final visibleList = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .hitTestable()
    .first;

/// Services the last [pumpApp] call used, for assertions.
late MemoryReminderService reminders;
late FakeSocialSignIn social;

/// Pumps the dashboard over a repository the test prepared.
Future<void> pumpWithRepo(WidgetTester tester, MockRepository repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  reminders = MemoryReminderService();
  social = FakeSocialSignIn();
  await tester.pumpWidget(
    NurseCompanionApp(
      repository: repo,
      auth: AuthController(MockAuthService(repo, signedIn: true)),
      social: social,
      reminders: reminders,
      today: () => now,
    ),
  );
  await settle(tester);
}

Future<MockRepository> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  int tab = 0,
  bool signedIn = true,
  bool newUser = false,
  bool remindersSupported = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = MockRepository(today: now, newUser: newUser);
  reminders = MemoryReminderService(supported: remindersSupported);
  social = FakeSocialSignIn();
  await tester.pumpWidget(
    NurseCompanionApp(
      repository: repo,
      auth: AuthController(MockAuthService(repo, signedIn: signedIn)),
      social: social,
      reminders: reminders,
      initialTab: tab,
      today: () => now,
    ),
  );
  await settle(tester);
  return repo;
}

/// The pulsing step marker animates forever, so pump a fixed time instead of pumpAndSettle.
Future<void> settle(
  WidgetTester tester, [
  Duration d = const Duration(seconds: 2),
]) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(d ~/ 10);
  }
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: visibleList);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Scrolls [finder] into view (clear of the floating dock) and taps it.
Future<void> revealAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  final screenHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  if (tester.getCenter(finder).dy > screenHeight - 140) {
    await tester.drag(visibleList, const Offset(0, -160));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.tap(finder);
}

void main() {
  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets('dashboard', (tester) async {
        await pumpApp(tester, size: entry.value);
        expect(find.text('Hello Nurse Dilani,'), findsOneWidget);
        expect(find.textContaining('148,500'), findsOneWidget);
        expect(find.text("Today's Shift"), findsOneWidget);
        await scrollTo(tester, find.text('Leave & OT Tracker'));
        expect(find.text('Scan Image (OCR)'), findsOneWidget);
      });

      testWidgets('duty details', (tester) async {
        await pumpApp(tester, size: entry.value, tab: 1);
        expect(find.text('Duty & Roster Details'), findsOneWidget);
        expect(find.text('13 Oct 2026'), findsOneWidget);
        await scrollTo(tester, find.text('Leave & Allowance Summary'));
        expect(find.text('Casual leave'), findsOneWidget);
      });

      testWidgets('salary analytics', (tester) async {
        await pumpApp(tester, size: entry.value, tab: 2);
        expect(find.text('Projected take-home'), findsOneWidget);
        await scrollTo(tester, find.text('Burnout risk'));
        expect(find.text('Moderate'), findsOneWidget);
      });

      testWidgets('profile', (tester) async {
        await pumpApp(tester, size: entry.value, tab: 3);
        expect(find.text('Pay settings'), findsOneWidget);
        await scrollTo(tester, find.text('Sign out'));
      });

      testWidgets('welcome', (tester) async {
        await pumpApp(tester, size: entry.value, signedIn: false);
        expect(find.text('Use email or mobile'), findsOneWidget);
      });
    });
  }

  testWidgets('sign in from the welcome screen opens the dashboard', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    // Get Started goes straight to sign-in.
    await tester.tap(find.text('Use email or mobile'));
    await settle(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email or mobile'),
      '077 123 4567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Passw0rd!',
    );
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(find.text('Hello Nurse Dilani,'), findsOneWidget);
  });

  testWidgets('register validates fields like the API', (tester) async {
    await pumpApp(tester, signedIn: false);
    await tester.tap(find.text('New here? Create an account'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email or mobile'),
      '12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await revealAndTap(tester, find.text('Create account'));
    await settle(tester, const Duration(milliseconds: 500));
    expect(
      find.text('Enter an email or a mobile like 077 123 4567'),
      findsOneWidget,
    );
    expect(find.text('At least 8 characters'), findsOneWidget);
    // Phase 1 asks for nothing else: no salary, ward or rate fields.
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(
      find.textContaining('salary', findRichText: true),
      findsWidgets,
    ); // only the reassurance note
    expect(
      find.widgetWithText(TextFormField, 'Monthly basic salary (LKR)'),
      findsNothing,
    );
  });

  testWidgets('today card: a duty in progress shows the live main-shift ring', (
    tester,
  ) async {
    final repo = await pumpApp(tester);
    // Checked in at 06:52, now 12:15: still on the main shift.
    expect(find.byType(SplitDutyRing), findsOneWidget);
    expect(find.text('Main Shift'), findsWidgets);
    expect(find.textContaining('left'), findsOneWidget);

    await revealAndTap(tester, find.text('End duty'));
    await settle(tester);
    expect(find.text('Duty completed'), findsOneWidget);
    final today = (await repo.shifts(from: now, to: now)).first;
    expect(today.checkOutTime, isNotNull);
    expect(today.status, ShiftStatus.completed);
  });

  testWidgets('24-hour duty: one check-in, automatic OT, split at check-out', (
    tester,
  ) async {
    final repo = MockRepository(today: now);
    for (final s in await repo.shifts(from: now, to: now)) {
      await repo.deleteShift(s.id);
    }
    final duty = await repo.createShift(
      ShiftDraft(date: now, type: ShiftType.twentyFour),
    );
    expect(duty.otHours, 18);
    // Started at 05:00, so by 12:15 the 6-hour main shift is over.
    await repo.updateShift(
      duty.id,
      ShiftUpdate(action: ShiftAction.checkIn, at: DateTime(2026, 10, 13, 5)),
    );
    await pumpWithRepo(tester, repo);

    expect(find.text('Overtime (OT) Logged'), findsOneWidget);
    expect(find.text('Sign out & start OT'), findsNothing);
    expect(find.text('Stay on OT'), findsNothing);

    await revealAndTap(tester, find.text('End duty'));
    await settle(tester);
    expect(find.text('Duty completed'), findsOneWidget);
    expect(find.text('Main Shift'), findsWidgets);
    expect(find.text('Logged OT'), findsOneWidget);

    final done = (await repo.shifts(from: now, to: now)).single;
    expect(done.calculatedMainHours, 6);
    expect(done.otStartTime, DateTime(2026, 10, 13, 11));
  });

  testWidgets('a skipped duty is marked as leave in one tap', (tester) async {
    final repo = MockRepository(today: now);
    for (final s in await repo.shifts(from: now, to: now)) {
      await repo.deleteShift(s.id);
    }
    await repo.createShift(ShiftDraft(date: now, type: ShiftType.day));
    await pumpWithRepo(tester, repo);

    await revealAndTap(tester, find.text('D · Day Duty (12h)'));
    await settle(tester);
    expect(
      find.text('Skipped this duty? Mark leave in one tap'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sick'));
    await settle(tester);

    final today = (await repo.shifts(from: now, to: now)).single;
    expect(today.leaveType, LeaveType.sick);
    expect(today.otHours, 0);
  });

  testWidgets('add a D duty worked entirely as a main shift', (tester) async {
    final repo = MockRepository(today: now);
    for (final s in await repo.shifts(from: now, to: now)) {
      await repo.deleteShift(s.id);
    }
    await pumpWithRepo(tester, repo);

    await tester.tap(find.text('Add'));
    await settle(tester);
    await tester.tap(find.text('D  Day Duty (12h)'));
    await settle(tester, const Duration(milliseconds: 300));
    expect(find.text('6 h + 6 h OT'), findsOneWidget);
    await tester.tap(find.text('12 h, no OT'));
    await settle(tester, const Duration(milliseconds: 300));
    await revealAndTap(tester, find.widgetWithText(FilledButton, 'Add shift'));
    await settle(tester);

    final today = (await repo.shifts(from: now, to: now)).single;
    expect(today.type, ShiftType.day);
    expect(today.standardHours, 12);
    expect(today.otHours, 0);
    expect(today.hasAutoOt, isFalse);
  });

  testWidgets('casual leave toggle saves and blocks OT extension', (
    tester,
  ) async {
    final repo = await pumpApp(tester);
    await scrollTo(tester, find.text('Casual Leave'));
    await revealAndTap(tester, find.text('Casual Leave'));
    await settle(tester);
    expect(find.text('Casual Leave saved for today'), findsOneWidget);
    final today = (await repo.shifts(from: now, to: now)).first;
    expect(today.isLeave, isTrue);
    expect(today.otHours, 0);

    await tester.tap(find.text('OT +1 hr'), warnIfMissed: false);
    await settle(tester, const Duration(milliseconds: 500));
    expect(find.text('OT +1 hr saved for today'), findsNothing);
  });

  testWidgets('roster import: paste text → review → save', (tester) async {
    final repo = await pumpApp(tester);
    await scrollTo(tester, find.text('Scan Image (OCR)'));
    await tester.tap(find.text('Scan Image (OCR)'));
    await settle(tester);
    expect(find.text('Scan Roster'), findsOneWidget);

    await tester.tap(find.text('Paste roster text instead'));
    await settle(tester, const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, '01 M\n02 N');
    await tester.tap(find.text('Read'));
    await settle(tester);

    expect(find.text('Review Roster'), findsOneWidget);
    expect(find.text('1 to check'), findsOneWidget);
    final before = (await repo.shifts(
      from: DateTime(2026, 10),
      to: DateTime(2026, 10, 31),
    )).length;
    await tester.tap(find.text('Replace days I already entered'));
    await tester.tap(find.textContaining('Save 31 shifts'));
    await settle(tester);
    expect(find.textContaining('Roster saved'), findsOneWidget);
    final after = (await repo.shifts(
      from: DateTime(2026, 10),
      to: DateTime(2026, 10, 31),
    )).length;
    expect(after, greaterThanOrEqualTo(before));
  });

  testWidgets('dock switches tabs and back returns home', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Roster'));
    await settle(tester, const Duration(milliseconds: 600));
    expect(find.text('Duty & Roster Details'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester, const Duration(milliseconds: 600));
    expect(find.text('Hello Nurse Dilani,').hitTestable(), findsOneWidget);
  });

  testWidgets('manual roster explains itself from the help icon', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(320, 640));
    await scrollTo(tester, find.text('Manual Input'));
    await revealAndTap(tester, find.text('Manual Input'));
    await settle(tester);
    await tester.tap(find.byTooltip('How to add your roster'));
    await settle(tester, const Duration(milliseconds: 800));
    expect(find.text('How to add your roster'), findsOneWidget);
    expect(find.text('3. Fill a whole month fast'), findsOneWidget);
    final sheet = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Got it'),
      200,
      scrollable: sheet,
    );
    expect(find.textContaining('24-hour duty'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await settle(tester, const Duration(milliseconds: 800));
    expect(find.text('How to add your roster'), findsNothing);
  });

  for (final lang in ['si', 'ta']) {
    testWidgets('every tab fits a small phone in $lang', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MockRepository(today: now);
      final prefs = MemoryDevicePrefs(welcomeSeen: true, guideSeen: true)
        ..values['language'] = lang;
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
      await settle(tester);
      // A RenderFlex overflow fails the test, so visiting each tab checks the layout.
      final language = AppLanguage.parse(lang);
      for (final tab in ['Roster', 'Salary Analytics', 'Profile', 'Home']) {
        await tester.tap(find.byTooltip(translate(language, tab)));
        await settle(tester);
      }
      await tester.tap(find.byTooltip(translate(language, 'Profile')));
      await settle(tester);
      await tester.tap(find.byTooltip(translate(language, 'App settings')));
      await settle(tester);
      expect(find.text(translate(language, 'App Settings')), findsOneWidget);
    });
  }

  testWidgets('gear opens App Settings; language and clock apply everywhere', (
    tester,
  ) async {
    await pumpApp(tester, tab: 3);
    await tester.tap(find.byTooltip('App settings'));
    await settle(tester);
    expect(find.text('App Settings'), findsOneWidget);
    expect(find.text('Shift reminders'), findsOneWidget);

    await tester.tap(find.text('සිංහල'));
    await settle(tester);
    expect(find.text('යෙදුම් සැකසුම්'), findsOneWidget); // App Settings
    expect(find.text('භාෂාව'), findsOneWidget); // Language

    await tester.tap(find.text('தமிழ்'));
    await settle(tester);
    expect(find.text('மொழி'), findsOneWidget);

    await tester.tap(find.text('English'));
    await settle(tester);
    await scrollTo(tester, find.text('24-hour clock'));
    expect(find.text('Times show as 07:30 PM'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    expect(find.text('Times show as 19:30'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await settle(tester);
  });

  testWidgets('swiping the dates selects the day under the fixed centre', (
    tester,
  ) async {
    await pumpApp(tester, tab: 1);
    expect(find.text('13 Oct 2026'), findsOneWidget);
    final centre = tester.getCenter(find.text('13 Oct 2026'));
    // Two days' worth to the left, no fling.
    await tester.timedDrag(
      find.byType(DateSelector),
      const Offset(-92, 0),
      const Duration(milliseconds: 600),
    );
    await settle(tester, const Duration(milliseconds: 800));
    expect(find.text('15 Oct 2026'), findsOneWidget);
    // The capsule itself never moved.
    expect(tester.getCenter(find.text('15 Oct 2026')), centre);
  });

  testWidgets('selecting a future date shows that day as upcoming', (
    tester,
  ) async {
    await pumpApp(tester, tab: 1);
    await tester.tap(find.text('14'));
    await settle(tester, const Duration(milliseconds: 800));
    expect(find.text('14 Oct 2026'), findsOneWidget);
    expect(find.textContaining('Upcoming · Wed'), findsWidgets);
  });

  testWidgets(
    'after signing in once, sign out goes to sign-in (not welcome) with the id remembered',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.bySemanticsLabel('Menu'));
      await settle(tester, const Duration(milliseconds: 600));
      await tester.tap(find.text('Sign out'));
      await settle(tester);
      expect(find.text('Use email or mobile'), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Enter your password to continue.'), findsOneWidget);
      expect(find.text('Not you?'), findsOneWidget);
      // The start page has no back button.
      expect(find.byTooltip('Back'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Passw0rd!',
      );
      await tester.tap(find.text('Sign in'));
      await settle(tester);
      expect(find.text('Hello Nurse Dilani,'), findsOneWidget);
    },
  );

  testWidgets('Google leads on Get Started and signs in with one tap', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    final google = tester.getTopLeft(find.text('Continue with Google'));
    final email = tester.getTopLeft(find.text('Use email or mobile'));
    expect(google.dy, lessThan(email.dy)); // Google comes first
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(social.requested, [SignInProvider.google]);
    expect(
      find.textContaining('Nurse Dilani'),
      findsOneWidget,
    ); // on the dashboard
  });

  testWidgets('quick test login signs in with one tap', (tester) async {
    await pumpApp(tester, signedIn: false);
    await tester.tap(find.text('Use email or mobile'));
    await settle(tester);
    expect(find.text('Quick test login'), findsOneWidget);
    expect(find.text('On a 24 h duty now'), findsOneWidget);
    await tester.tap(find.text('Kasun'));
    await settle(tester);
    expect(find.text('Hello Nurse Dilani,'), findsOneWidget);
  });

  test('quick login is offered only for local API hosts', () {
    expect(AppConfig.isLocalHost('localhost'), isTrue);
    expect(AppConfig.isLocalHost('10.0.2.2'), isTrue);
    expect(AppConfig.isLocalHost('192.168.0.100'), isTrue);
    expect(AppConfig.isLocalHost('172.20.1.5'), isTrue);
    expect(AppConfig.isLocalHost('api.slnurse.lk'), isFalse);
    expect(AppConfig.isLocalHost('172.32.1.5'), isFalse);
    expect(AppConfig.isLocalHost('8.8.8.8'), isFalse);
  });

  testWidgets('a returning device never shows the welcome screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockRepository(today: now);
    await tester.pumpWidget(
      NurseCompanionApp(
        repository: repo,
        auth: AuthController(MockAuthService(repo, signedIn: false)),
        social: FakeSocialSignIn(),
        reminders: MemoryReminderService(),
        prefs: MemoryDevicePrefs(
          welcomeSeen: true,
          lastLoginId: '077 123 4567',
        ),
        today: () => now,
      ),
    );
    await settle(tester);
    expect(find.text('Use email or mobile'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('077 123 4567'), findsOneWidget);

    // Sign-up from the start page, and back again.
    await tester.tap(find.text('New here? Create an account'));
    await settle(tester);
    await revealAndTap(tester, find.text('Already registered? Sign in'));
    await settle(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('line charts finish drawing', (tester) async {
    await pumpApp(tester);
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .where((p) => p.runtimeType.toString() == '_SmoothLinePainter')
        .toList();
    expect(painters, isNotEmpty);
    for (final p in painters) {
      expect((p as dynamic).progress, 1.0);
    }
  });

  group('progressive profiling', () {
    testWidgets('3-field sign-up lands on the dashboard with a welcome', (
      tester,
    ) async {
      await pumpApp(tester, signedIn: false);
      await tester.tap(find.text('New here? Create an account'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name'),
        'Kumari Silva',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or mobile'),
        '071 234 5678',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Passw0rd!',
      );
      await revealAndTap(tester, find.text('Create account'));
      await settle(tester);
      expect(find.text('Welcome, Nurse Kumari!'), findsOneWidget);
      expect(find.text("Let's simplify your duty life."), findsOneWidget);
      expect(find.text('Estimate · add your salary'), findsOneWidget);
      expect(find.text('No shift today'), findsOneWidget);
    });

    testWidgets('Google sign-up is one tap', (tester) async {
      await pumpApp(tester, signedIn: false);
      await tester.tap(find.text('Use email or mobile'));
      await settle(tester);
      await tester.tap(find.text('Continue with Google'));
      await settle(tester);
      expect(social.requested, [SignInProvider.google]);
      expect(find.text('Welcome, Nurse Dilani!'), findsOneWidget);
    });

    testWidgets(
      'salary tab asks for pay details once; skipping keeps the estimate',
      (tester) async {
        final repo = await pumpApp(tester, newUser: true);
        await tester.tap(find.byTooltip('Salary Analytics'));
        await settle(tester);
        expect(find.text('Make your salary exact'), findsOneWidget);
        await tester.tap(find.text('Skip for now (Use Default Estimate)'));
        await settle(tester);
        expect((await repo.me()).salarySetup, OnboardingState.skipped);
        expect(find.textContaining('typical nursing salary'), findsOneWidget);

        // Not asked again on the next visit.
        await tester.tap(find.byTooltip('Home'));
        await settle(tester, const Duration(milliseconds: 600));
        await tester.tap(find.byTooltip('Salary Analytics'));
        await settle(tester);
        expect(find.text('Make your salary exact'), findsNothing);
      },
    );

    testWidgets('entering salary removes the estimate', (tester) async {
      final repo = await pumpApp(tester, newUser: true);
      await tester.tap(find.byTooltip('Salary Analytics'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Base salary (LKR / month)'),
        '68000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'OT rate (LKR / hour)'),
        '450',
      );
      await tester.tap(find.text('Save & predict'));
      await settle(tester);
      final me = await repo.me();
      expect(me.baseSalary, 68000);
      expect(me.defaultOtHourlyRate, 450);
      expect(me.salarySetup, OnboardingState.completed);
      expect(find.textContaining('typical nursing salary'), findsNothing);
      expect(find.textContaining('68,000'), findsWidgets);
    });

    testWidgets('scan roster asks for hospital & ward first (2 steps)', (
      tester,
    ) async {
      final repo = await pumpApp(tester, newUser: true);
      await scrollTo(tester, find.text('Scan Image (OCR)'));
      await tester.tap(find.text('Scan Image (OCR)'));
      await settle(tester);
      expect(find.text('Select your primary hospital'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'karapitiya');
      await settle(tester, const Duration(milliseconds: 300));
      await tester.tap(find.text('Teaching Hospital, Karapitiya'));
      await settle(tester, const Duration(milliseconds: 300));
      expect(find.text('Which ward?'), findsOneWidget);
      await tester.tap(find.text('ICU'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Ward number (optional)'),
        '12',
      );
      await tester.tap(find.text('Save & continue'));
      await settle(tester);
      expect(
        (await repo.me()).hospitalOrWard,
        'Ward 12 · ICU · Teaching Hospital, Karapitiya',
      );
      // …and the nurse carries on to the scanner.
      expect(find.text('Scan Roster'), findsOneWidget);
    });

    testWidgets(
      'skipping the ward prompt still opens the feature, and it is not asked again',
      (tester) async {
        final repo = await pumpApp(tester, newUser: true);
        await tester.tap(find.text('Add'));
        await settle(tester);
        await tester.tap(find.text('Skip'));
        await settle(tester);
        expect(
          find.text('Add shift'),
          findsWidgets,
        ); // the add-shift sheet opened
        expect((await repo.me()).workplaceSetup, OnboardingState.skipped);
      },
    );

    testWidgets('first check-in offers reminders; one tap schedules them', (
      tester,
    ) async {
      await pumpApp(tester, newUser: true);
      // Add today's morning shift, then check in.
      await tester.tap(find.text('Add'));
      await settle(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Add shift'));
      await settle(tester);
      await revealAndTap(
        tester,
        find.widgetWithText(FilledButton, 'Start duty'),
      );
      await settle(tester);
      expect(find.text('Never miss a shift'), findsOneWidget);
      await tester.tap(find.text('Turn on reminders'));
      await settle(tester);
      expect(reminders.enabled, isTrue);
      expect(reminders.offered, isTrue);
    });

    testWidgets('no reminders offer where notifications are unsupported', (
      tester,
    ) async {
      await pumpApp(tester, remindersSupported: false);
      await revealAndTap(tester, find.text('End duty'));
      await settle(tester);
      expect(find.text('Never miss a shift'), findsNothing);
    });

    testWidgets('existing accounts are never prompted', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Salary Analytics'));
      await settle(tester);
      expect(find.text('Make your salary exact'), findsNothing);
      expect(
        find.text('Hello Nurse Dilani,'),
        findsNothing,
      ); // on the analytics tab now
    });
  });
}
