import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pastel_card.dart';
import '../../../data/models.dart';
import '../../shifts/duty_actions.dart';

/// Where a duty in progress stands at a given moment.
class DutyProgress {
  const DutyProgress({
    required this.elapsed,
    required this.main,
    required this.ot,
    required this.planned,
    required this.mainTarget,
    required this.onOt,
  });

  /// Splits the time since check-in into main shift and OT. On a long duty OT starts by
  /// itself after the main hours; on a standard shift only after "switch to OT".
  factory DutyProgress.of(Shift s, DateTime now) {
    final start = s.checkInTime ?? now;
    final elapsed = now.difference(start);
    final mainTarget = Duration(minutes: (s.standardHours * 60).round());

    Duration main;
    Duration ot;
    if (s.otStartTime != null) {
      main = (s.checkOutTime ?? s.otStartTime!).difference(start);
      ot = (s.otEndTime ?? now).difference(s.otStartTime!);
    } else if (s.hasAutoOt) {
      main = elapsed < mainTarget ? elapsed : mainTarget;
      ot = elapsed - main;
    } else {
      main = elapsed;
      ot = Duration.zero;
    }
    final plannedOt = s.hasAutoOt
        ? s.type.spanHours - s.standardHours
        : s.otHours;
    return DutyProgress(
      elapsed: elapsed,
      main: main.isNegative ? Duration.zero : main,
      ot: ot.isNegative ? Duration.zero : ot,
      planned: Duration(minutes: ((s.standardHours + plannedOt) * 60).round()),
      mainTarget: mainTarget,
      onOt: s.otInProgress || (s.hasAutoOt && elapsed >= mainTarget),
    );
  }

  final Duration elapsed;
  final Duration main;
  final Duration ot;

  /// Rostered length of the whole duty (main + planned OT).
  final Duration planned;
  final Duration mainTarget;

  /// The active timer has moved from the main shift to OT.
  final bool onOt;

  bool get mainDone => main >= mainTarget;
  Duration get mainLeft => mainDone ? Duration.zero : mainTarget - main;
}

/// Live card for a duty in progress: a ring split into main shift and OT, the current
/// phase, and End duty. Rebuilds every 30 s, so the switch from "Main Shift" to
/// "Overtime (OT) Logged" happens on screen without the nurse doing anything.
class ActiveDutyCard extends StatefulWidget {
  const ActiveDutyCard({
    super.key,
    required this.shift,
    required this.clock,
    required this.onAction,
    required this.onOpen,
  });

  final Shift shift;
  final DateTime Function() clock;
  final void Function(Shift shift, ShiftAction action) onAction;
  final void Function(Shift shift) onOpen;

  @override
  State<ActiveDutyCard> createState() => _ActiveDutyCardState();
}

class _ActiveDutyCardState extends State<ActiveDutyCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    final p = DutyProgress.of(s, widget.clock());
    final text = Theme.of(context).textTheme;
    final next = s.nextAction;
    // A standard shift whose main hours are over can carry on as OT.
    final canStayOnOt =
        !s.hasAutoOt && s.otStartTime == null && p.mainDone && !s.isLeave;

    return PastelCard(
      elevated: true,
      color: p.onOt ? AppColors.peach : AppColors.lavender,
      onTap: () => widget.onOpen(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CodeBadge(code: s.code),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.type.label,
                  style: text.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _PhaseChip(onOt: p.onOt),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SplitDutyRing(progress: p, size: 128),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(
                      color: AppColors.mintDeep,
                      label: 'Main Shift',
                      value: p.mainDone
                          ? '${formatDuration(p.main)} ✓'
                          : '${formatDuration(p.main)} · ${formatDuration(p.mainLeft)} left',
                    ),
                    const SizedBox(height: 8),
                    _Legend(
                      color: AppColors.peachDeep,
                      label: 'OT Shift',
                      value: p.ot > Duration.zero
                          ? formatDuration(p.ot)
                          : s.hasAutoOt
                          ? 'from ${Fmt.time(s.mainEnd!)}'
                          : 'not started',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Started ${Fmt.time(s.checkInTime!)}',
                      style: text.bodySmall,
                    ),
                    if (s.nightAllowanceApplicable)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Night allowance duty',
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (canStayOnOt) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onAction(s, ShiftAction.switchToOt),
                    icon: const Icon(Icons.more_time_rounded, size: 18),
                    label: const FittedBox(child: Text('Stay on OT')),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (next != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onAction(s, next),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: FittedBox(child: Text(next.label)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ring over the rostered duty: green for main-shift time, peach for OT, with a tick where
/// the main shift ends.
class SplitDutyRing extends StatelessWidget {
  const SplitDutyRing({super.key, required this.progress, this.size = 128});

  final DutyProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = progress;
    final total = math
        .max(p.planned.inMinutes, (p.main + p.ot).inMinutes)
        .clamp(1, 1 << 30);
    return Semantics(
      label:
          'Duty ${formatDuration(p.elapsed)} elapsed, main shift ${formatDuration(p.main)}, OT ${formatDuration(p.ot)}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SplitRingPainter(
            main: p.main.inMinutes / total,
            ot: p.ot.inMinutes / total,
            boundary: p.mainTarget.inMinutes / total,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(p.elapsed),
                  style: text.titleLarge?.copyWith(fontSize: 20),
                ),
                Text(
                  p.onOt ? 'OT logged' : 'Main shift',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitRingPainter extends CustomPainter {
  _SplitRingPainter({
    required this.main,
    required this.ot,
    required this.boundary,
  });

  /// Fractions of the full circle.
  final double main;
  final double ot;
  final double boundary;

  static const _stroke = 12.0;
  static const _top = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      paint..color = Colors.white.withValues(alpha: 0.75),
    );
    if (main > 0) {
      canvas.drawArc(
        rect,
        _top,
        math.pi * 2 * main.clamp(0, 1),
        false,
        paint..color = AppColors.mintDeep,
      );
    }
    if (ot > 0) {
      canvas.drawArc(
        rect,
        _top + math.pi * 2 * main.clamp(0, 1),
        math.pi * 2 * ot.clamp(0, 1 - main.clamp(0, 1)),
        false,
        paint..color = AppColors.peachDeep,
      );
    }
    // Where the main shift ends (and OT begins) on a long duty.
    if (boundary > 0 && boundary < 1) {
      final angle = _top + math.pi * 2 * boundary;
      final c = rect.center;
      final r = rect.width / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        c + dir * (r - _stroke / 2 - 2),
        c + dir * (r + _stroke / 2 + 2),
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_SplitRingPainter old) =>
      old.main != main || old.ot != ot || old.boundary != boundary;
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      code,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.onOt});

  final bool onOt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: onOt ? AppColors.peachDeep : AppColors.mintDeep,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      onOt ? 'Overtime (OT) Logged' : 'Main Shift',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.titleSmall?.copyWith(fontSize: 13)),
              Text(value, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
