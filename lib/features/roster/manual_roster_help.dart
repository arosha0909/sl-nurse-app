import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'roster_widgets.dart';

/// "How to add your roster" guide for the manual roster screen.
Future<void> showManualRosterHelp(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ManualRosterHelp(),
    );

class ManualRosterHelp extends StatelessWidget {
  const ManualRosterHelp({super.key});

  static const _steps = [
    (
      icon: Icons.calendar_month_rounded,
      title: 'Pick the month',
      body: 'Use ‹ › at the top. You can go up to 3 months back or ahead.',
    ),
    (
      icon: Icons.touch_app_rounded,
      title: 'Set each day',
      body:
          'Tap the code badge on the right of a day and choose its duty, '
          'leave or day off. Choose “Clear day” to remove it.',
    ),
    (
      icon: Icons.auto_fix_high_rounded,
      title: 'Fill a whole month fast',
      body:
          '“Fill rota” fills empty days with 7 7 1 1 N N DO, starting on the '
          'day you pick. Days you already set are never overwritten.',
    ),
    (
      icon: Icons.save_rounded,
      title: 'Save',
      body:
          'Changed days get a purple dot. Tap “Save” at the bottom to keep '
          'them; leaving without saving discards them.',
    ),
    (
      icon: Icons.lock_outline_rounded,
      title: 'Locked days',
      body:
          'A day with more than one entry (e.g. Morning + Evening) is locked '
          'here. Change it from Duty & Roster details instead.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How to add your roster', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Type your duty roster day by day. It takes about a minute '
                'for a whole month.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 18),
              for (final (i, s) in _steps.indexed)
                _Step(
                  number: i + 1,
                  icon: s.icon,
                  title: s.title,
                  body: s.body,
                ),
              const SizedBox(height: 6),
              Text('Duty codes', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                'The same codes as your ward roster.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 10),
              for (final c in RosterCode.values) _CodeRow(code: c),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: AppColors.peachDeep,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'D and 24 duties include their OT automatically '
                        '(6 h + 6 h and 6 h + 18 h). Have a photo of the roster? '
                        'Use Scan Roster instead and fix only what it misreads.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.lavenderDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. $title', style: text.titleSmall),
                const SizedBox(height: 2),
                Text(body, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final RosterCode code;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: code.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              code.short,
              style: text.labelLarge?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              code.isRest
                  ? code.label
                  : '${code.label} · ${code.type.timeRange}',
              style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
