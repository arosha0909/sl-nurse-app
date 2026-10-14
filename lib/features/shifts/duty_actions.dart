import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
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
  DutySummary? summary;

  final ok = await context.runWithFeedback(() async {
    switch (action) {
      case ShiftAction.checkIn:
        final started = await repo.startDuty(shift.id);
        // A missing alert must never block the check-in itself.
        try {
          if (scope.settings.otAlerts) {
            await scope.reminders.scheduleOtTransition(started);
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
  if (!context.mounted) return true;
  if (summary != null) {
    await showDutySummary(context, summary!);
  } else if (action == ShiftAction.checkIn) {
    // First check-in on this device: offer shift reminders with a single tap.
    await ProgressivePrompts.offerReminders(context);
  }
  return true;
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
                'This month so far: ${Fmt.lkr(s.monthToDateOt)} OT · ${Fmt.lkr(s.monthToDateNight)} night allowance',
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
