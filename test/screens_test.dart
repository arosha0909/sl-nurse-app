import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_scope.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/core/social_sign_in.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/data/models.dart';
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
final visibleList = find.byType(Scrollable).hitTestable().first;

/// Services the last [pumpApp] call used, for assertions.
late MemoryReminderService reminders;
late FakeSocialSignIn social;

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
        expect(find.text('Get Started'), findsOneWidget);
      });
    });
  }

  testWidgets('sign in from the welcome screen opens the dashboard', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    await tester.tap(find.text('I already have an account'));
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
    await tester.tap(find.text('Get Started'));
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

  testWidgets('today card: checking out completes the main shift', (
    tester,
  ) async {
    final repo = await pumpApp(tester);
    expect(find.text('2. Main shift ending'), findsOneWidget);
    await revealAndTap(tester, find.widgetWithText(FilledButton, 'Check out'));
    await settle(tester);
    expect(find.text('Signed out. Shift completed'), findsOneWidget);
    expect(find.text('2. Main shift done'), findsOneWidget);
    final today = (await repo.shifts(from: now, to: now)).first;
    expect(today.checkOutTime, isNotNull);
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

  testWidgets('selecting a future date shows that day as upcoming', (
    tester,
  ) async {
    await pumpApp(tester, tab: 1);
    await tester.tap(find.text('14'));
    await settle(tester, const Duration(milliseconds: 800));
    expect(find.text('14 Oct 2026'), findsOneWidget);
    expect(find.textContaining('Upcoming · Wed'), findsWidgets);
  });

  testWidgets('sign out from the menu returns to welcome', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Menu'));
    await settle(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text('Sign out'));
    await settle(tester);
    expect(find.text('Get Started'), findsOneWidget);
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
      await tester.tap(find.text('Get Started'));
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
      await tester.tap(find.text('Get Started'));
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
      await revealAndTap(tester, find.widgetWithText(FilledButton, 'Check in'));
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
      await revealAndTap(
        tester,
        find.widgetWithText(FilledButton, 'Check out'),
      );
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
