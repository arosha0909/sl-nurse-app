import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pastel_card.dart';
import '../../../data/models.dart';
import '../dashboard_vm.dart';

/// "Today's Activity"-style card: a shift tile on the left and the
/// check-in → main shift → OT workflow on the right, with the next action button.
class TodayShiftCard extends StatelessWidget {
  const TodayShiftCard({
    super.key,
    required this.shift,
    required this.now,
    required this.onAction,
    required this.onOpen,
    required this.onAdd,
  });

  final Shift? shift;
  final DateTime now;
  final void Function(Shift shift, ShiftAction action) onAction;
  final void Function(Shift shift) onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = shift;
    if (s == null) return _EmptyToday(onAdd: onAdd);
    if (s.isLeave || s.type == ShiftType.off && s.otHours == 0) {
      return _RestDay(shift: s, onOpen: () => onOpen(s));
    }

    return PastelCard(
      elevated: true,
      padding: const EdgeInsets.all(10),
      onTap: () => onOpen(s),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On very narrow screens the tile moves above the stepper.
          final stacked = constraints.maxWidth < 330;
          final tile = _ShiftTile(shift: s, compact: stacked);
          final steps = _StepList(
            steps: stepsFor(s, now),
            next: s.nextAction,
            onNext: s.nextAction == null
                ? null
                : () => onAction(s, s.nextAction!),
          );
          if (stacked) {
            return Column(children: [tile, const SizedBox(height: 10), steps]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: constraints.maxWidth * 0.34, child: tile),
                const SizedBox(width: 10),
                Expanded(child: steps),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      elevated: true,
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.event_busy_rounded,
            color: AppColors.lavender,
            iconColor: AppColors.lavenderDeep,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No shift today', style: text.titleSmall),
                Text('Add one to track check-in and OT', style: text.bodySmall),
              ],
            ),
          ),
          FilledButton(onPressed: onAdd, child: const Text('Add')),
        ],
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  const _RestDay({required this.shift, required this.onOpen});

  final Shift shift;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final leave = shift.isLeave;
    return PastelCard(
      color: leave ? AppColors.peach : AppColors.mint,
      onTap: onOpen,
      child: Row(
        children: [
          IconBadge(
            icon: leave ? Icons.beach_access_rounded : Icons.weekend_rounded,
            iconColor: leave ? AppColors.peachDeep : AppColors.mintDeep,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave
                      ? 'On ${shift.leaveType.label.toLowerCase()}'
                      : 'Day off',
                  style: text.titleSmall,
                ),
                Text(
                  leave
                      ? 'Rest well, nothing to check in today'
                      : 'Enjoy your rest day',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({required this.shift, required this.compact});

  final Shift shift;
  final bool compact;

  IconData get _icon => switch (shift.type) {
    ShiftType.morning => Icons.wb_sunny_rounded,
    ShiftType.evening => Icons.wb_twilight_rounded,
    ShiftType.night => Icons.nightlight_round,
    ShiftType.off => Icons.weekend_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final align = compact ? TextAlign.start : TextAlign.center;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.innerRadius),
      child: Container(
        color: AppColors.lavender.withValues(alpha: 0.55),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative blobs, echoing the reference tile.
            Positioned(
              right: -26,
              bottom: -34,
              child: _blob(78, AppColors.lavenderDeep.withValues(alpha: 0.18)),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: _blob(64, AppColors.lavenderDeep.withValues(alpha: 0.10)),
            ),
            Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: AppColors.peachDeep),
                ),
                const SizedBox(height: 12),
                Text(
                  shift.type.label,
                  style: text.titleSmall,
                  textAlign: align,
                ),
                const SizedBox(height: 4),
                Text(
                  shift.type.timeRange.replaceFirst(' – ', '\nto '),
                  style: text.bodySmall?.copyWith(fontSize: 11, height: 1.35),
                  textAlign: align,
                ),
                if (shift.otHours > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${Fmt.hours(shift.otHours)}h OT',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (!compact) const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _StepList extends StatelessWidget {
  const _StepList({
    required this.steps,
    required this.next,
    required this.onNext,
  });

  final List<ShiftStep> steps;
  final ShiftAction? next;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppSpacing.innerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              index: i + 1,
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
          if (next != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: FittedBox(child: Text(next!.label)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.isLast,
  });

  final int index;
  final ShiftStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = step.status == StepStatus.upcoming;

    return Semantics(
      label: 'Step $index, ${step.title}, ${step.detail}, ${step.status.name}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                _Marker(status: step.status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: step.status == StepStatus.done
                            ? AppColors.mintDeep.withValues(alpha: 0.6)
                            : AppColors.lavenderDeep.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${step.title}',
                      style: text.titleSmall?.copyWith(
                        fontSize: 13,
                        color: muted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.detail,
                      style: text.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.status});

  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      StepStatus.done => Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.mintDeep,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
      ),
      StepStatus.active => const _PulsingDot(),
      StepStatus.upcoming => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.lavenderDeep.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    };
  }
}

/// Gently pulsing marker for the step in progress.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) _c.stop();
    return SizedBox.square(
      dimension: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lavenderDeep.withValues(
              alpha: 0.18 + 0.17 * _c.value,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
