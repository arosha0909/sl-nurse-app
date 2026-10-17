import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../roster/manual_roster_screen.dart';
import '../roster/roster_scan_screen.dart';
import '../shifts/duty_actions.dart';
import '../shifts/shift_sheets.dart';
import '../onboarding/progressive_prompts.dart';
import 'dashboard_vm.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/next_shift_reminder.dart';
import 'widgets/quick_actions.dart';
import 'widgets/salary_hero_card.dart';
import 'widgets/today_shift_card.dart';
import '../../core/i18n/i18n.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenRoster,
    required this.onOpenSalary,
    required this.onOpenProfile,
    this.onOpenNotifications,
  });

  final VoidCallback onOpenRoster;
  final VoidCallback onOpenSalary;
  final VoidCallback onOpenProfile;
  final VoidCallback? onOpenNotifications;

  Future<DashboardData> _load(AppScope scope) async {
    final now = scope.today();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final repo = scope.repository;

    // Independent requests run in parallel.
    final results = await Future.wait<Object>([
      repo.me(),
      repo.forecast(month: now.month, year: now.year),
      // From yesterday at the latest, so a night duty ending this morning is known.
      repo.shifts(
        from: monthStart.isBefore(now) && now.day > 1
            ? monthStart
            : now.subtract(const Duration(days: 1)),
        to: monthEnd,
      ),
      repo.shifts(from: now, to: now.add(const Duration(days: 14))),
    ]);
    return DashboardData.build(
      user: results[0] as UserProfile,
      forecast: results[1] as SalaryForecast,
      monthShifts: results[2] as List<Shift>,
      upcoming: results[3] as List<Shift>,
      now: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AsyncView<DashboardData>(
      load: () => _load(scope),
      skeleton: const SkeletonList(heights: [110, 300, 190, 70, 230]),
      builder: (context, data, reload) {
        final now = scope.today();
        return SafeArea(
          bottom: false,
          child: ResponsiveContent(
            child: RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  12,
                  AppSpacing.screenPadding,
                  AppSpacing.dockClearance,
                ),
                children: [
                  DashboardHeader(
                    user: data.user,
                    onMenu: () => Scaffold.of(context).openDrawer(),
                    onAvatar: onOpenProfile,
                    onNotifications: onOpenNotifications,
                    isNewUser: scope.auth.isNewUser,
                  ),
                  const SizedBox(height: 22),
                  SalaryHeroCard(
                    data: data,
                    month: now,
                    onTap: onOpenSalary,
                    onAddSalary: () =>
                        ProgressivePrompts.ensureSalary(context, force: true),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  SectionHeader(
                    title: context.tr("Today's Shift"),
                    actionIcon: Icons.edit_outlined,
                    actionLabel: data.today == null
                        ? context.tr('Add shift')
                        : context.tr('Edit shift'),
                    onAction: () => data.today == null
                        ? showAddShift(context, dayOf(now))
                        : showShiftActions(context, data.today!),
                  ),
                  const SizedBox(height: 8),
                  TodayShiftCard(
                    shift: data.today,
                    now: now,
                    clock: scope.today,
                    sleepDay: data.sleepDay,
                    onAction: (s, a) => runDutyAction(context, s, a),
                    onOpen: (s) => showShiftActions(context, s),
                    onAdd: () => showAddShift(context, dayOf(now)),
                  ),
                  if (data.next != null) ...[
                    const SizedBox(height: AppSpacing.gap),
                    NextShiftReminder(
                      shift: data.next!,
                      now: now,
                      onTap: onOpenRoster,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sectionGap),
                  SectionHeader(title: context.tr('Quick Actions')),
                  const SizedBox(height: 8),
                  QuickActionsGrid(
                    today: data.today,
                    onScanRoster: () => RosterScanScreen.open(context),
                    onManualInput: () => ManualRosterScreen.open(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
