import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StackedBarDatum {
  const StackedBarDatum({
    required this.label,
    required this.base,
    required this.top,
  });

  final String label;

  /// Lower segment (e.g. main shift hours).
  final double base;

  /// Upper segment (e.g. OT hours).
  final double top;

  double get total => base + top;
}

/// Capsule-shaped vertical bars on a light track, as in the reference "Kcal" chart,
/// with each bar split into two stacked segments. Tapping a bar shows its values.
class StackedCapsuleBars extends StatefulWidget {
  const StackedCapsuleBars({
    super.key,
    required this.data,
    this.baseColor = AppColors.mintDeep,
    this.topColor = AppColors.lavenderDeep,
    this.height = 170,
    this.unit = 'h',
    this.highlightIndex,
  });

  final List<StackedBarDatum> data;
  final Color baseColor;
  final Color topColor;
  final double height;
  final String unit;

  /// Bar shown as selected initially (e.g. today).
  final int? highlightIndex;

  @override
  State<StackedCapsuleBars> createState() => _StackedCapsuleBarsState();
}

class _StackedCapsuleBarsState extends State<StackedCapsuleBars> {
  late int? _selected = widget.highlightIndex;

  @override
  Widget build(BuildContext context) {
    final maxTotal = widget.data.map((d) => d.total).fold<double>(0, math.max);
    final scaleMax = maxTotal <= 0 ? 1.0 : maxTotal * 1.08;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Bars get thinner on narrow screens, but never cramped.
        final slot = constraints.maxWidth / widget.data.length;
        final barWidth = (slot * 0.62).clamp(18.0, 40.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < widget.data.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      setState(() => _selected = _selected == i ? null : i),
                  child: Semantics(
                    label:
                        '${widget.data[i].label}: ${_fmt(widget.data[i].base)} main, ${_fmt(widget.data[i].top)} OT',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _selected == i ? 1 : 0,
                          child: Text(
                            '${_fmt(widget.data[i].total)}${widget.unit}',
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Bar(
                          datum: widget.data[i],
                          scaleMax: scaleMax,
                          height: widget.height,
                          width: barWidth,
                          baseColor: widget.baseColor,
                          topColor: widget.topColor,
                          dimmed: _selected != null && _selected != i,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.data[i].label,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: _selected == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selected == i
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.datum,
    required this.scaleMax,
    required this.height,
    required this.width,
    required this.baseColor,
    required this.topColor,
    required this.dimmed,
  });

  final StackedBarDatum datum;
  final double scaleMax;
  final double height;
  final double width;
  final Color baseColor;
  final Color topColor;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width / 2.6);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final baseH = height * (datum.base / scaleMax) * t;
            final topH = height * (datum.top / scaleMax) * t;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (topH > 0)
                  Container(
                    height: topH,
                    decoration: BoxDecoration(
                      color: topColor,
                      borderRadius: radius,
                    ),
                  ),
                if (topH > 0) const SizedBox(height: 3),
                Container(
                  height: math.max(0, baseH - (topH > 0 ? 3 : 0)),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.55),
                    borderRadius: radius,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
