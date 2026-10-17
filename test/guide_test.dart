import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_scope.dart';
import 'package:nurse_companion/core/app_settings.dart';
import 'package:nurse_companion/core/device_prefs.dart';
import 'package:nurse_companion/core/i18n/i18n.dart';
import 'package:nurse_companion/core/reminders.dart';
import 'package:nurse_companion/core/social_sign_in.dart';
import 'package:nurse_companion/data/mock_repository.dart';
import 'package:nurse_companion/main.dart';

final now = DateTime(2026, 10, 13, 12, 15);

Future<void> settle(WidgetTester tester, [int ms = 1200]) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(Duration(milliseconds: ms ~/ 10));
  }
}

/// Signed in for the first time on this device: the guide opens over the app.
Future<MemoryDevicePrefs> pumpFirstRun(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = MockRepository(today: now);
  final prefs = MemoryDevicePrefs(welcomeSeen: true);
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
  return prefs;
}

Future<void> next(WidgetTester tester, AppLanguage lang) async {
  await tester.tap(find.text(translate(lang, 'Next')));
  await settle(tester, 600);
}

void main() {
  testWidgets('first sign-in asks the language, then guides in that language', (
    tester,
  ) async {
    final prefs = await pumpFirstRun(tester);
    expect(find.text('Choose your language'), findsOneWidget);

    await tester.tap(find.text('සිංහල'));
    await settle(tester);
    // Page 1 is now in Sinhala.
    expect(
      find.text(translate(AppLanguage.sinhala, 'What is Nurse Companion?')),
      findsOneWidget,
    );
    expect(prefs.read('language'), 'si');

    for (var i = 0; i < 7; i++) {
      await next(tester, AppLanguage.sinhala);
    }
    expect(
      find.text(translate(AppLanguage.sinhala, "You're ready!")),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text(translate(AppLanguage.sinhala, 'Go to my dashboard')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.text(translate(AppLanguage.sinhala, 'Go to my dashboard')),
    );
    await settle(tester);

    expect(prefs.guideSeen, isTrue);
    expect(find.text('Choose your language'), findsNothing);
    expect(
      find.byTooltip(translate(AppLanguage.sinhala, 'Home')),
      findsOneWidget,
    );
  });

  testWidgets('skip ends the guide and it does not come back', (tester) async {
    final prefs = await pumpFirstRun(tester);
    await tester.tap(find.text('English'));
    await settle(tester);
    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(prefs.guideSeen, isTrue);
    expect(find.text('What is Nurse Companion?'), findsNothing);
  });

  testWidgets('the last page can start the roster right away', (tester) async {
    await pumpFirstRun(tester);
    await tester.tap(find.text('English'));
    await settle(tester);
    for (var i = 0; i < 7; i++) {
      await next(tester, AppLanguage.english);
    }
    await tester.scrollUntilVisible(
      find.text('Type my roster'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Type my roster'));
    await settle(tester);
    expect(find.text('Manual Roster'), findsOneWidget);
  });

  // A RenderFlex overflow fails the test, so this checks every page's layout.
  for (final lang in AppLanguage.values) {
    testWidgets('every guide page fits a small phone in ${lang.code}', (
      tester,
    ) async {
      await pumpFirstRun(tester, size: const Size(320, 640));
      await tester.tap(find.text(lang.nativeName));
      await settle(tester);
      for (var i = 0; i < 7; i++) {
        await next(tester, lang);
      }
      expect(find.text(translate(lang, "You're ready!")), findsOneWidget);
    });
  }
}
