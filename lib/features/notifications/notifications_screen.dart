import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/i18n/i18n.dart';
import '../../core/notices.dart';
import '../../data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../roster/roster_widgets.dart';
import '../settings/app_settings_screen.dart';

/// Every notification in one place: duty reminders, OT switches, day summaries, pay
/// reminders and messages from the Nurse Companion team. Returns the route of a tapped
/// notification so the app can open it.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static Future<String?> open(BuildContext context) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? _pushOn;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final scope = AppScope.of(context);
    scope.reminders.isEnabled().then((v) {
      if (mounted) setState(() => _pushOn = v);
    });
    // Messages from the team join the list (kept read/unread across visits).
    scope.repository
        .announcements()
        .then(
          (list) => scope.inbox.mergeAnnouncements([
            for (final a in list)
              Notice(
                id: noticeId('ann:${a.id}'),
                kind: NoticeKind.announcement,
                title: a.title,
                body: a.body,
                at: a.at,
                route: NoticeRoute.inbox,
              ),
          ]),
        )
        .catchError((_) {});
  }

  Future<void> _open(Notice n) async {
    final scope = AppScope.of(context);
    await scope.inbox.markRead(n.id);
    if (!mounted || n.route == NoticeRoute.inbox) return;
    Navigator.of(context).pop(n.route);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final now = scope.today();
    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: ListenableBuilder(
              listenable: scope.inbox,
              builder: (context, _) {
                final items = scope.inbox.visible(now);
                final today = items.where((n) => sameDay(n.at, now)).toList();
                final earlier = items
                    .where((n) => !sameDay(n.at, now))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    PageHeader(
                      title: context.tr('Notifications'),
                      trailing: scope.inbox.unread(now) > 0
                          ? CircleIconButton(
                              icon: Icons.done_all_rounded,
                              tooltip: context.tr('Mark all as read'),
                              onPressed: () => scope.inbox.markAllRead(now),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    if (_pushOn == false) ...[
                      _PushOffBanner(
                        onTurnOn: () async {
                          await AppSettingsScreen.open(context);
                          final on = await scope.reminders.isEnabled();
                          if (mounted) setState(() => _pushOn = on);
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 56,
                              color: AppColors.lavenderDeep,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('No notifications yet'),
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                'Duty reminders, your daily summary and messages will appear here.',
                              ),
                              textAlign: TextAlign.center,
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    if (today.isNotEmpty) ...[
                      _Group(context.tr('Today')),
                      for (final n in today)
                        _NoticeTile(notice: n, now: now, onTap: () => _open(n)),
                    ],
                    if (earlier.isNotEmpty) ...[
                      _Group(context.tr('Earlier')),
                      for (final n in earlier)
                        _NoticeTile(notice: n, now: now, onTap: () => _open(n)),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.now,
    required this.onTap,
  });

  final Notice notice;
  final DateTime now;
  final VoidCallback onTap;

  (IconData, Color, Color) get _look => switch (notice.kind) {
    NoticeKind.shiftStart => (
      Icons.alarm_rounded,
      AppColors.sky,
      AppColors.skyDeep,
    ),
    NoticeKind.forgotStart => (
      Icons.touch_app_rounded,
      AppColors.peach,
      AppColors.peachDeep,
    ),
    NoticeKind.mainEnd || NoticeKind.otEnd => (
      Icons.timelapse_rounded,
      AppColors.lavender,
      AppColors.lavenderDeep,
    ),
    NoticeKind.otSwitch => (
      Icons.more_time_rounded,
      AppColors.peach,
      AppColors.peachDeep,
    ),
    NoticeKind.daySummary => (
      Icons.insights_rounded,
      AppColors.mint,
      AppColors.mintDeep,
    ),
    NoticeKind.payDetails => (
      Icons.account_balance_wallet_rounded,
      AppColors.peach,
      AppColors.peachDeep,
    ),
    NoticeKind.announcement => (
      Icons.campaign_rounded,
      AppColors.lavender,
      AppColors.lavenderDeep,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, bg, fg) = _look;
    final when = sameDay(notice.at, now)
        ? Fmt.time(notice.at)
        : '${Fmt.weekday(notice.at)}, ${Fmt.dayMonthYear(notice.at)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: notice.read
            ? AppColors.surface.withValues(alpha: 0.7)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 21, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: text.titleSmall?.copyWith(
                                fontWeight: notice.read
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notice.read)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.peachDeep,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(notice.body, style: text.bodySmall),
                      const SizedBox(height: 6),
                      Text(
                        when,
                        style: text.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PushOffBanner extends StatelessWidget {
  const _PushOffBanner({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_rounded,
            color: AppColors.peachDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(
                "Phone notifications are off. Reminders still appear here, but your phone won't alert you.",
              ),
              style: text.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          TextButton(onPressed: onTurnOn, child: Text(context.tr('Turn on'))),
        ],
      ),
    );
  }
}
