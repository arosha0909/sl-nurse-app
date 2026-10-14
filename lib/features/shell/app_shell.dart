import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/floating_nav_bar.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../duty/duty_details_screen.dart';
import '../onboarding/progressive_prompts.dart';
import '../profile/profile_screen.dart';
import '../roster/manual_roster_screen.dart';
import '../roster/roster_scan_screen.dart';
import '../../core/i18n/i18n.dart';

/// Root scaffold: tab content over the wave background, the floating dock on top,
/// and the side menu.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _tab = widget.initialTab;

  static const _items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Roster',
    ),
    NavItem(
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Salary Analytics',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  DataSync? _sync;
  bool _rescheduling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = AppScope.of(context).sync;
    if (!identical(sync, _sync)) {
      _sync?.removeListener(_rescheduleReminders);
      _sync = sync..addListener(_rescheduleReminders);
      _rescheduleReminders();
    }
  }

  @override
  void dispose() {
    _sync?.removeListener(_rescheduleReminders);
    super.dispose();
  }

  /// Keeps shift reminders in step with the roster after any change (no-op if turned off).
  Future<void> _rescheduleReminders() async {
    if (_rescheduling) return;
    _rescheduling = true;
    try {
      await AppScope.of(context).rescheduleReminders();
    } catch (_) {
      // Offline: keep the reminders already scheduled.
    } finally {
      _rescheduling = false;
    }
  }

  void _go(int tab) {
    setState(() => _tab = tab);
    // Salary tab ("Predict salary"): ask for basic salary & OT rate the first time.
    if (tab == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ProgressivePrompts.ensureSalary(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onOpenRoster: () => _go(1),
        onOpenSalary: () => _go(2),
        onOpenProfile: () => _go(3),
      ),
      DutyDetailsScreen(onBack: () => _go(0)),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      // Android back from another tab returns Home before leaving the app.
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        drawer: _AppDrawer(
          current: _tab,
          onTab: _go,
          // The shell's context outlives the drawer, which is gone once it closes.
          onScan: () => RosterScanScreen.open(context),
          onManual: () => ManualRosterScreen.open(context),
        ),
        body: BackgroundWaves(
          child: Stack(
            children: [
              // IndexedStack keeps each tab's scroll position and state.
              Positioned.fill(
                child: IndexedStack(index: _tab, children: pages),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: FloatingNavBar(
                          items: _items,
                          currentIndex: _tab,
                          onTap: _go,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.current,
    required this.onTab,
    required this.onScan,
    required this.onManual,
  });

  final int current;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.auth.user;
    final text = Theme.of(context).textTheme;

    Widget item(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool selected = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        title: Text(
          label,
          style: text.titleSmall?.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: selected,
        selectedTileColor: AppColors.ink,
        shape: const StadiumBorder(),
        onTap: () {
          Navigator.pop(context); // close drawer first
          onTap();
        },
      ),
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  UserAvatar(name: user?.fullName ?? 'Nurse', size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.hospitalOrWard ?? '',
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            item(
              Icons.home_outlined,
              context.tr('Home'),
              () => onTab(0),
              selected: current == 0,
            ),
            item(
              Icons.calendar_month_outlined,
              context.tr('Duty & roster'),
              () => onTab(1),
              selected: current == 1,
            ),
            item(
              Icons.bar_chart_rounded,
              context.tr('Salary analytics'),
              () => onTab(2),
              selected: current == 2,
            ),
            item(
              Icons.person_outline_rounded,
              context.tr('Profile & settings'),
              () => onTab(3),
              selected: current == 3,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(),
            ),
            item(Icons.document_scanner_outlined, 'Scan roster', onScan),
            item(
              Icons.edit_calendar_outlined,
              context.tr('Enter roster manually'),
              onManual,
            ),
            const Spacer(),
            item(Icons.logout_rounded, 'Sign out', () => scope.auth.logout()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
