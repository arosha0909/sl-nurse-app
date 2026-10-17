import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/notices.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../onboarding/progressive_prompts.dart';
import '../../core/i18n/i18n.dart';

/// Runs a check-in / check-out / OT action for [shift] with feedback, used by the
/// dashboard and the shift sheet so both behave the same:
///  - Start duty: one check-in; on a long duty, schedules the "switched to OT" alert.
///  - End duty / End OT: splits main and OT hours and shows the summary sheet.
Future<bool> runDutyAction(
  BuildContext context,
  Shift shift,
  ShiftAction action,
) async {
  final scope = AppScope.of(context);
  final repo = scope.repository;
  // Notification texts in the nurse's language, without holding on to the context.
  final tr = scope.noticeTr;
  DutySummary? summary;

  final ok = await context.runWithFeedback(() async {
    switch (action) {
      case ShiftAction.checkIn:
        final started = await repo.startDuty(shift.id);
        // A missing alert must never block the check-in itself.
        try {
          if (scope.settings.otAlerts) {
            await scope.reminders.scheduleOtTransition(
              started,
              title: tr('Main Shift Completed!'),
              body: tr(
                'Switched to Overtime (OT) Mode. Keep up the great work! 🩺',
              ),
            );
          }
        } catch (_) {}
      case ShiftAction.checkOut || ShiftAction.endOt:
        summary = (await repo.endDuty(shift.id)).summary;
        try {
          await scope.reminders.cancelOtTransition();
        } catch (_) {}
      case ShiftAction.switchToOt:
        await repo.updateShift(shift.id, ShiftUpdate(action: action));
    }
  }, success: _successMessage(context, shift, action));
  if (!ok) return false;

  scope.sync.changed();
  // Day summary and, if pay details are missing, a gentle reminder. Never blocks.
  if (summary != null) unawaited(_afterDuty(scope, shift, summary!));
  if (!context.mounted) return true;
  if (summary != null) {
    await showDutySummary(context, summary!);
  } else if (action == ShiftAction.checkIn) {
    // First check-in on this device: offer shift reminders with a single tap.
    await ProgressivePrompts.offerReminders(context);
  }
  return true;
}

/// After a duty ends: the day's earnings summary, and a pay-details reminder at most
/// once a week while basic salary or deductions are missing.
Future<void> _afterDuty(AppScope scope, Shift shift, DutySummary s) async {
  try {
    final tr = scope.noticeTr;
    final day = formatDay(shift.date);

    // Running totals for the day (a double, or a day and a night duty, add up).
    final key = 'day.$day';
    final prev = scope.prefs.read(key);
    final totals = prev == null
        ? <String, dynamic>{'hours': 0.0, 'ot': 0.0, 'pay': 0.0}
        : jsonDecode(prev) as Map<String, dynamic>;
    totals['hours'] = (totals['hours'] as num) + s.totalHours;
    totals['ot'] = (totals['ot'] as num) + s.otHours;
    totals['pay'] = (totals['pay'] as num) + s.totalPay;
    await scope.prefs.write(key, jsonEncode(totals));

    if (scope.settings.daySummary) {
      await scope.notify(
        Notice(
          id: noticeId('day:$day'),
          kind: NoticeKind.daySummary,
          title: tr("Today's summary"),
          body: tr(
            '{hours} h worked · {ot} h OT · {pay} extra earned (OT and allowances). This month so far: {month}.',
            {
              'hours': Fmt.hours((totals['hours'] as num).toDouble()),
              'ot': Fmt.hours((totals['ot'] as num).toDouble()),
              'pay': Fmt.lkr(totals['pay'] as num),
              'month': Fmt.lkr(s.monthToDateOt + s.monthToDateNight),
            },
          ),
          // Shortly after the day's last duty; a later duty that day replaces it.
          at: s.checkOut.add(const Duration(minutes: 30)),
        ),
      );
    }

    if (scope.settings.payDetailsReminder) {
      final last = int.tryParse(scope.prefs.read('payNudgeAt') ?? '');
      final now = DateTime.now();
      final due =
          last == null ||
          now.difference(DateTime.fromMillisecondsSinceEpoch(last)) >
              const Duration(days: 7);
      if (due) {
        final user = await scope.repository.me();
        final config = await scope.repository.salaryConfig();
        final noSalary = user.baseSalary <= 0 || user.salaryIsEstimate;
        final noDeductions = config.deductions.every((d) => d.amount <= 0);
        if (noSalary || noDeductions) {
          await scope.prefs.write(
            'payNudgeAt',
            '${now.millisecondsSinceEpoch}',
          );
          await scope.notify(
            Notice(
              id: noticeId('pay:$day'),
              kind: NoticeKind.payDetails,
              title: tr('Add your pay details'),
              body: noSalary
                  ? tr(
                      'Your basic salary isn\'t set yet, so your earnings are estimates. It takes a minute.',
                    )
                  : tr(
                      'Add your monthly deductions (W&OP, loans…) so your take-home pay is exact.',
                    ),
              at: now,
              route: NoticeRoute.pay,
            ),
          );
        }
      }
    }
  } catch (_) {
    // Notifications are a convenience; the duty is already saved.
  }
}

String? _successMessage(
  BuildContext context,
  Shift shift,
  ShiftAction action,
) => switch (action) {
  ShiftAction.checkIn =>
    shift.hasAutoOt
        ? context.tr(
            'Duty started. OT begins automatically after {hours} hrs',
            {'hours': Fmt.hours(shift.standardHours)},
          )
        : context.tr('Duty started. Have a good shift!'),
  ShiftAction.switchToOt => context.tr('Main shift signed out. OT started'),
  // The summary sheet says it all.
  ShiftAction.checkOut || ShiftAction.endOt => null,
};

/// "7h 05m"
String formatDuration(Duration d) {
  final minutes = d.inMinutes < 0 ? 0 : d.inMinutes;
  return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}

/// Bottom sheet shown after "End duty": the split between main shift and OT, and pay.
Future<void> showDutySummary(BuildContext context, DutySummary summary) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DutySummarySheet(summary: summary),
    );

class DutySummarySheet extends StatelessWidget {
  const DutySummarySheet({super.key, required this.summary});

  final DutySummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = summary;
    final nextDay = !sameDay(s.checkIn, s.checkOut);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.mintDeep,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Duty completed'),
                          style: text.titleLarge,
                        ),
                        Text(
                          '${s.code} · ${Fmt.time(s.checkIn)} – ${Fmt.time(s.checkOut)}${nextDay ? ' (+1)' : ''}',
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HoursTile(
                      label: context.tr('Main Shift'),
                      hours: s.mainHours,
                      color: AppColors.mint,
                      ink: AppColors.mintDeep,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HoursTile(
                      label: context.tr('Logged OT'),
                      hours: s.otHours,
                      color: AppColors.peach,
                      ink: AppColors.peachDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PastelCard(
                color: s.nightAllowanceApplicable
                    ? AppColors.sky
                    : AppColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 20,
                      color: s.nightAllowanceApplicable
                          ? AppColors.ink
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.nightAllowanceApplicable
                            ? context.tr(
                                'Night allowance applied (10 PM – 6 AM)',
                              )
                            : context.tr('No night allowance on this duty'),
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PayRow(label: context.tr('OT pay'), value: Fmt.lkr(s.otPay)),
              if (s.nightAllowanceApplicable)
                _PayRow(
                  label: context.tr('Night allowance'),
                  value: Fmt.lkr(s.nightAllowance),
                ),
              const Divider(height: 20),
              _PayRow(
                label: context.tr('Earned on this duty'),
                value: Fmt.lkr(s.totalPay),
                bold: true,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'This month so far: {ot} OT · {night} night allowance',
                  {
                    'ot': Fmt.lkr(s.monthToDateOt),
                    'night': Fmt.lkr(s.monthToDateNight),
                  },
                ),
                style: text.bodySmall,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('Done')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoursTile extends StatelessWidget {
  const _HoursTile({
    required this.label,
    required this.hours,
    required this.color,
    required this.ink,
  });

  final String label;
  final double hours;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: ink)),
          const SizedBox(height: 4),
          Text('${Fmt.hours(hours)} hrs', style: text.headlineSmall),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = bold ? text.titleMedium : text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
