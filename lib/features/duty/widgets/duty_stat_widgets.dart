import 'package:flutter/material.dart';

import '../../../core/charts/progress_ring.dart';
import '../../../core/charts/smooth_line_chart.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pastel_card.dart';
import '../duty_vm.dart';

/// Two equal-height widgets: completed duty ring (green) and OT trend (purple).
class DutyStatWidgets extends StatelessWidget {
  const DutyStatWidgets({super.key, required this.summary});

  final DutyData summary;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _CompletedDutyCard(summary: summary)),
          const SizedBox(width: 14),
          Expanded(child: _OtLoggedCard(summary: summary)),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(height: 1.25),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ],
    );
  }
}

class _CompletedDutyCard extends StatelessWidget {
  const _CompletedDutyCard({required this.summary});

  final DutyData summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = (summary.completion * 100).round();
    return PastelCard(
      color: AppColors.mint,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _CardTitle(
            title: 'Completed\nDuty',
            icon: Icons.verified_outlined,
            iconColor: AppColors.mintDeep,
          ),
          const SizedBox(height: 14),
          // Fixed size: LayoutBuilder can't report intrinsic height inside IntrinsicHeight.
          FittedBox(
            child: ProgressRing(
              progress: summary.completion,
              size: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$pct%', style: text.titleLarge),
                  Text(
                    'Completed',
                    style: text.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary.dueShifts == 0
                ? 'No shifts due yet'
                : '${summary.completedShifts} of ${summary.dueShifts} shifts',
            style: text.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtLoggedCard extends StatelessWidget {
  const _OtLoggedCard({required this.summary});

  final DutyData summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.lavender,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'OT Hours\nLogged',
            icon: Icons.more_time_rounded,
            iconColor: AppColors.lavenderDeep,
          ),
          const Spacer(),
          const SizedBox(height: 10),
          // Dotted guide lines behind the trend, like the reference heart-rate card.
          Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _DottedGridPainter()),
              ),
              SmoothLineChart(
                values: summary.otTrend,
                color: AppColors.lavenderDeep,
                fillColor: Colors.transparent,
                height: 64,
                highlightLast: true,
                semanticLabel: 'OT hours trend this month',
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Center(
            child: Text.rich(
              TextSpan(
                text: Fmt.hours(summary.otHoursMonth),
                style: text.titleLarge,
                children: [TextSpan(text: '  Hours', style: text.bodySmall)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedGridPainter extends CustomPainter {
  const _DottedGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lavenderDeep.withValues(alpha: 0.25);
    for (var row = 0; row < 4; row++) {
      final y = size.height * (row + 0.5) / 4;
      for (double x = 0; x < size.width; x += 6) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
