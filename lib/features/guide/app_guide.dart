import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_settings.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../dashboard/widgets/active_duty_card.dart';

/// Where the nurse wants to go when the guide ends.
enum GuideNext { home, scanRoster, typeRoster, setPay }

/// First-run guide, shown once after the first sign-in on a device and any time later
/// from App Settings or the menu. It asks for the language first, then explains what
/// the app is for, how to get started, and the everyday routine, in that language.
class AppGuide extends StatefulWidget {
  const AppGuide({super.key});

  static Future<GuideNext?> open(BuildContext context) =>
      Navigator.of(context).push<GuideNext>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AppGuide(),
        ),
      );

  @override
  State<AppGuide> createState() => _AppGuideState();
}

class _AppGuideState extends State<AppGuide> {
  final _pages = PageController();
  int _page = 0;

  static const _count = 9; // language + 7 topics + ready

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  Future<void> _finish(GuideNext next) async {
    await AppScope.of(context).prefs.markGuideSeen();
    if (mounted) Navigator.of(context).pop(next);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final last = _page == _count - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _page > 0 ? _goTo(_page - 1) : _finish(GuideNext.home);
      },
      child: Scaffold(
        body: BackgroundWaves(
          child: SafeArea(
            child: ResponsiveContent(
              child: Column(
                children: [
                  _TopBar(
                    page: _page,
                    count: _count,
                    onSkip: () => _finish(GuideNext.home),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: [
                        _LanguagePage(
                          settings: settings,
                          onChosen: () => _goTo(1),
                        ),
                        const _WhatPage(),
                        const _WhyPage(),
                        const _RosterPage(),
                        const _PayPage(),
                        const _DutyPage(),
                        const _ChangesPage(),
                        const _MonthPage(),
                        _ReadyPage(onNext: _finish),
                      ],
                    ),
                  ),
                  if (_page > 0 && !last)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        8,
                        AppSpacing.screenPadding,
                        14,
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _goTo(_page - 1),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: Text(context.tr('Back')),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _goTo(_page + 1),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(context.tr('Next')),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.count,
    required this.onSkip,
  });

  final int page;
  final int count;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i <= page
                            ? AppColors.ink
                            : AppColors.ink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (page > 0 && page < count - 1)
            TextButton(onPressed: onSkip, child: Text(context.tr('Skip')))
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * Page layout
 * ------------------------------------------------------------------ */
class _GuidePage extends StatelessWidget {
  const _GuidePage({
    required this.art,
    required this.title,
    required this.body,
    this.eyebrow,
    this.points = const [],
    this.where,
  });

  final Widget art;
  final String? eyebrow;
  final String title;
  final String body;
  final List<(IconData, String)> points;

  /// Where to find this in the app, e.g. "Home → Quick Actions → Scan Image".
  final String? where;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        12,
        AppSpacing.screenPadding,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: art),
          const SizedBox(height: 22),
          if (eyebrow != null)
            Text(
              eyebrow!,
              style: text.labelLarge?.copyWith(
                color: AppColors.lavenderDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(title, style: text.headlineSmall),
          const SizedBox(height: 10),
          Text(body, style: text.bodyLarge?.copyWith(height: 1.45)),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final (icon, point) in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 17, color: AppColors.mintDeep),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          point,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (where != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lavender),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    size: 18,
                    color: AppColors.lavenderDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('Where: {path}', {'path': where!}),
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Soft pastel stage behind each page's illustration.
class _Stage extends StatelessWidget {
  const _Stage({required this.color, required this.child, this.fit = true});

  final Color color;
  final Widget child;

  /// Shrink a fixed-size illustration to the width of small phones. Off for
  /// illustrations that wrap onto more lines instead.
  final bool fit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 190),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    ),
    child: fit ? FittedBox(fit: BoxFit.scaleDown, child: child) : child,
  );
}

/* ------------------------------------------------------------------ *
 * 0 · Language
 * ------------------------------------------------------------------ */
class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.settings, required this.onChosen});

  final AppSettings settings;
  final VoidCallback onChosen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Center(child: AppLogo(size: 96)),
            const SizedBox(height: 22),
            // In all three languages, before one is chosen.
            Text(
              'Choose your language',
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'ඔබේ භාෂාව තෝරන්න  ·  உங்கள் மொழியைத் தேர்ந்தெடுங்கள்',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 22),
            for (final lang in [
              AppLanguage.sinhala,
              AppLanguage.english,
              AppLanguage.tamil,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LanguageCard(
                  language: lang,
                  selected: settings.language == lang,
                  onTap: () async {
                    await settings.setLanguage(lang);
                    onChosen();
                  },
                ),
              ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'You can change the language any time in App Settings.',
              ),
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  static const _greeting = {
    AppLanguage.sinhala: 'ආයුබෝවන්',
    AppLanguage.english: 'Hello',
    AppLanguage.tamil: 'வணக்கம்',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.ink : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: text.titleLarge?.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _greeting[language]!,
                      style: text.bodySmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: selected ? AppColors.mint : AppColors.textSecondary,
                size: selected ? 26 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * 1 · What it is
 * ------------------------------------------------------------------ */
class _WhatPage extends StatelessWidget {
  const _WhatPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(
      color: LogoColors.charcoal,
      child: AppLogo(size: 150, style: LogoStyle.character),
    ),
    eyebrow: context.tr('Welcome'),
    title: context.tr('What is Nurse Companion?'),
    body: context.tr(
      'A personal assistant for nurses in Sri Lanka. It keeps your duty roster, overtime, leave and salary together in one place, and does the counting for you.',
    ),
    points: [
      (
        Icons.calendar_month_rounded,
        context.tr('Your duty roster for the whole month'),
      ),
      (Icons.more_time_rounded, context.tr('Every OT hour, counted correctly')),
      (
        Icons.beach_access_rounded,
        context.tr('Leave taken and leave remaining'),
      ),
      (Icons.payments_rounded, context.tr('Your salary, before payday')),
    ],
  );
}

/* ------------------------------------------------------------------ *
 * 2 · Why
 * ------------------------------------------------------------------ */
class _WhyPage extends StatelessWidget {
  const _WhyPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(color: AppColors.mint, fit: false, child: _BenefitsArt()),
    eyebrow: context.tr('Why use it'),
    title: context.tr('Less paperwork. No missed pay.'),
    body: context.tr(
      'Most nurses track duties in a notebook and work out OT by hand. Mistakes mean lost money. Nurse Companion records everything as you work.',
    ),
    points: [
      (
        Icons.check_circle_rounded,
        context.tr('No more notebooks or calculators'),
      ),
      (
        Icons.check_circle_rounded,
        context.tr('OT on D and 24 duties is counted automatically'),
      ),
      (
        Icons.check_circle_rounded,
        context.tr('Night allowance and holiday duty are not forgotten'),
      ),
      (
        Icons.check_circle_rounded,
        context.tr('Check your payslip against your own record'),
      ),
    ],
  );
}

class _BenefitsArt extends StatelessWidget {
  const _BenefitsArt();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color bg, Color fg) => Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: fg, size: 30),
    );
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        tile(Icons.menu_book_rounded, AppColors.surface, AppColors.peachDeep),
        const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.mintDeep,
          size: 30,
        ),
        tile(Icons.phone_iphone_rounded, AppColors.ink, Colors.white),
        tile(
          Icons.more_time_rounded,
          AppColors.surface,
          AppColors.lavenderDeep,
        ),
        tile(Icons.nightlight_round, AppColors.surface, AppColors.skyDeep),
        tile(Icons.payments_rounded, AppColors.surface, AppColors.mintDeep),
      ],
    );
  }
}

/* ------------------------------------------------------------------ *
 * 3 · Step 1: roster
 * ------------------------------------------------------------------ */
class _RosterPage extends StatelessWidget {
  const _RosterPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(color: AppColors.peach, child: _RosterArt()),
    eyebrow: context.tr('Step 1 · Once a month'),
    title: context.tr('Add your duty roster'),
    body: context.tr(
      'Take a photo of your ward roster and the app reads it, or type it day by day with the same codes your ward uses. A month takes about a minute.',
    ),
    points: [
      (
        Icons.photo_camera_rounded,
        context.tr('Scan: photo of the roster, check, save'),
      ),
      (
        Icons.edit_calendar_rounded,
        context.tr('Type: tap each day and choose 7, 1, N, D, 24, DO or leave'),
      ),
      (
        Icons.auto_fix_high_rounded,
        context.tr('“Fill rota” fills a repeating pattern in one tap'),
      ),
    ],
    where: context.tr('Home → Quick Actions → Scan Image or Manual Input'),
  );
}

class _RosterArt extends StatelessWidget {
  const _RosterArt();

  @override
  Widget build(BuildContext context) {
    const codes = [
      ('7', AppColors.surface),
      ('7', AppColors.surface),
      ('1', AppColors.lavender),
      ('1', AppColors.lavender),
      ('N', AppColors.sky),
      ('24', AppColors.sky),
      ('DO', AppColors.surfaceMuted),
    ];
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              SizedBox(
                width: 40,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: text.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (code, color) in codes)
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  code,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Pill(icon: Icons.photo_camera_rounded, label: context.tr('Scan')),
            const SizedBox(width: 10),
            _Pill(icon: Icons.keyboard_rounded, label: context.tr('Type')),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ *
 * 4 · Step 2: pay
 * ------------------------------------------------------------------ */
class _PayPage extends StatelessWidget {
  const _PayPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(color: AppColors.lavender, child: _PayArt()),
    eyebrow: context.tr('Step 2 · Once'),
    title: context.tr('Set your pay details'),
    body: context.tr(
      'Enter your basic salary, night allowance and monthly allowances such as COLA. Then check the Pay rules match your hospital. You do this once; change it when your salary changes.',
    ),
    points: [
      (
        Icons.account_balance_wallet_rounded,
        context.tr('Basic salary, or pick your grade'),
      ),
      (
        Icons.add_card_rounded,
        context.tr('Allowances and deductions (COLA, W&OP…)'),
      ),
      (
        Icons.rule_rounded,
        context.tr('Pay rules: OT, holiday duty and leave days'),
      ),
    ],
    where: context.tr('Profile → Pay settings'),
  );
}

class _PayArt extends StatelessWidget {
  const _PayArt();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow(0.08),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          line(context.tr('Basic salary'), 'LKR ✓'),
          line(context.tr('Night allowance'), 'LKR ✓'),
          line('COLA · W&OP', 'LKR ✓'),
          const Divider(height: 14),
          line(context.tr('Pay rules'), '✓'),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * 5 · Every duty
 * ------------------------------------------------------------------ */
class _DutyPage extends StatelessWidget {
  const _DutyPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(color: AppColors.sky, child: _DutyArt()),
    eyebrow: context.tr('Every duty · Daily'),
    title: context.tr('Start and end each duty with one tap'),
    body: context.tr(
      'When you arrive, tap Start duty. When you leave, tap End duty. The app records the time, splits main shift and OT, and shows what you earned.',
    ),
    points: [
      (
        Icons.play_circle_rounded,
        context.tr('Start duty: one tap at the start of your shift'),
      ),
      (
        Icons.more_time_rounded,
        context.tr(
          'On D and 24 duties OT starts by itself after the main hours, with a reminder',
        ),
      ),
      (
        Icons.stop_circle_rounded,
        context.tr('End duty: see main hours, OT and pay for the duty'),
      ),
    ],
    where: context.tr('Home → Today\'s Shift'),
  );
}

class _DutyArt extends StatelessWidget {
  const _DutyArt();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SplitDutyRing(
          size: 132,
          progress: DutyProgress(
            elapsed: Duration(hours: 9),
            main: Duration(hours: 6),
            ot: Duration(hours: 3),
            planned: Duration(hours: 12),
            mainTarget: Duration(hours: 6),
            onOt: true,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pill(
              icon: Icons.circle,
              label: context.tr('Main Shift'),
              dot: AppColors.mintDeep,
            ),
            const SizedBox(height: 8),
            _Pill(
              icon: Icons.circle,
              label: context.tr('OT Shift'),
              dot: AppColors.peachDeep,
            ),
            const SizedBox(height: 8),
            Text('D · 07:00 – 19:00', style: text.bodySmall),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ *
 * 6 · When plans change
 * ------------------------------------------------------------------ */
class _ChangesPage extends StatelessWidget {
  const _ChangesPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: _Stage(
      color: AppColors.peach,
      fit: false,
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _Pill(icon: Icons.beach_access_rounded, label: context.tr('Casual')),
          _Pill(icon: Icons.sick_rounded, label: context.tr('Sick')),
          _Pill(icon: Icons.money_off_rounded, label: context.tr('No-pay')),
          _Pill(icon: Icons.swap_horiz_rounded, label: context.tr('Swap')),
          _Pill(
            icon: Icons.celebration_rounded,
            label: context.tr('Public holiday duty'),
          ),
          _Pill(icon: Icons.bedtime_rounded, label: context.tr('Sleep day')),
        ],
      ),
    ),
    eyebrow: context.tr('When plans change'),
    title: context.tr('Leave, swaps and holidays'),
    body: context.tr(
      'Tap any duty to change it. Your leave balance and salary update straight away.',
    ),
    points: [
      (
        Icons.beach_access_rounded,
        context.tr(
          'Missed a duty? Mark Casual, Sick or No-pay leave in one tap',
        ),
      ),
      (
        Icons.swap_horiz_rounded,
        context.tr(
          'Swapped with a colleague? Record who took it and the duty you took',
        ),
      ),
      (
        Icons.celebration_rounded,
        context.tr('Worked a public holiday? Switch on Public holiday duty'),
      ),
      (
        Icons.bedtime_rounded,
        context.tr('After a night duty the next day shows as your sleep day'),
      ),
    ],
    where: context.tr('Home → Today\'s Shift, or Roster → tap a day'),
  );
}

/* ------------------------------------------------------------------ *
 * 7 · Every month
 * ------------------------------------------------------------------ */
class _MonthPage extends StatelessWidget {
  const _MonthPage();

  @override
  Widget build(BuildContext context) => _GuidePage(
    art: const _Stage(color: AppColors.mint, child: _MonthArt()),
    eyebrow: context.tr('Every month'),
    title: context.tr('Know your salary before payday'),
    body: context.tr(
      'The Salary tab works out your expected take-home pay from your roster, OT, allowances and leave, and shows a payslip preview to check against the real one.',
    ),
    points: [
      (
        Icons.payments_rounded,
        context.tr('Projected take-home pay and a payslip preview'),
      ),
      (
        Icons.event_available_rounded,
        context.tr('Leave used and remaining for the year'),
      ),
      (Icons.favorite_rounded, context.tr('Weekly hours and burnout warnings')),
    ],
    where: context.tr('Bottom bar → Salary Analytics and Roster'),
  );
}

class _MonthArt extends StatelessWidget {
  const _MonthArt();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('Projected take-home'), style: text.bodyMedium),
        const SizedBox(height: 4),
        Text('LKR ••••••', style: text.headlineMedium),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in const [34.0, 48.0, 40.0, 62.0, 56.0, 76.0])
              Container(
                width: 18,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintDeep.withValues(alpha: 0.35 + h / 200),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ *
 * 8 · Ready
 * ------------------------------------------------------------------ */
class _ReadyPage extends StatelessWidget {
  const _ReadyPage({required this.onNext});

  final ValueChanged<GuideNext> onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final routine = [
      (
        Icons.calendar_month_rounded,
        context.tr('Once a month'),
        context.tr('Add your roster'),
      ),
      (
        Icons.touch_app_rounded,
        context.tr('Every duty'),
        context.tr('Tap Start duty and End duty'),
      ),
      (
        Icons.edit_note_rounded,
        context.tr('When it happens'),
        context.tr('Record leave, swaps and holiday duty'),
      ),
      (
        Icons.payments_rounded,
        context.tr('Any time'),
        context.tr('Check your salary and leave'),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.mintDeep,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('You\'re ready!'),
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'Your whole routine, in four steps. The app does the counting.',
            ),
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: AppColors.softShadow(0.06),
            ),
            child: Column(
              children: [
                for (final (icon, period, what) in routine)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.lavender,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 19,
                            color: AppColors.lavenderDeep,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(period, style: text.bodySmall),
                              Text(what, style: text.titleSmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.savings_rounded, color: AppColors.mintDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      'What you get: every OT hour and allowance counted, your leave always up to date, and your salary known before payday.',
                    ),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('Start now'), style: text.titleMedium),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => onNext(GuideNext.scanRoster),
            icon: const Icon(Icons.photo_camera_rounded, size: 18),
            label: Text(context.tr('Scan my roster')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onNext(GuideNext.typeRoster),
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: Text(context.tr('Type my roster')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onNext(GuideNext.setPay),
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
            label: Text(context.tr('Set my pay')),
          ),
          TextButton(
            onPressed: () => onNext(GuideNext.home),
            child: Text(context.tr('Go to my dashboard')),
          ),
          Text(
            context.tr(
              'You can open this guide again from App Settings or the menu.',
            ),
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.dot});

  final IconData icon;
  final String label;
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: dot != null ? 10 : 16, color: dot ?? AppColors.ink),
        const SizedBox(width: 6),
        // Long translations wrap instead of overflowing on small phones.
        Flexible(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
