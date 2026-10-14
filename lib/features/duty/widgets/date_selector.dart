import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal date picker with a fixed centre: the dark capsule showing the full date
/// never moves, and only the day numbers slide underneath it. Whatever date stops in
/// the centre is selected; tapping a date slides it into the centre.
class DateSelector extends StatefulWidget {
  const DateSelector({
    super.key,
    required this.dates,
    required this.selected,
    required this.onChanged,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  static const _extent = 46.0;
  static const _capsuleWidth = 132.0;
  static const _height = 44.0;

  /// Neighbours are pushed aside so they clear the capsule: half the capsule plus a
  /// small gap, minus where they would sit anyway.
  static const _push = _capsuleWidth / 2 + 6 - _extent / 2;

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _indexOf(widget.selected) * _extent,
  );

  /// Date currently under the capsule (follows the finger while dragging).
  late int _centre = _indexOf(widget.selected);

  int _indexOf(DateTime d) =>
      widget.dates.indexWhere((x) => _sameDay(x, d)).clamp(0, 1 << 30);

  @override
  void didUpdateWidget(DateSelector old) {
    super.didUpdateWidget(old);
    final index = _indexOf(widget.selected);
    if (index != _centre && _controller.hasClients) _animateTo(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) => _controller.animateTo(
    index * _extent,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  void _onScroll() {
    final index = (_controller.offset / _extent).round().clamp(
      0,
      widget.dates.length - 1,
    );
    if (index != _centre) {
      setState(() => _centre = index);
      HapticFeedback.selectionClick();
    }
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification) _onScroll();
    // Select once the dates have come to rest on a day.
    if (n is ScrollEndNotification &&
        !_sameDay(widget.dates[_centre], widget.selected)) {
      widget.onChanged(widget.dates[_centre]);
    }
    return false;
  }

  /// Maps a tap to the date drawn there. Days beside the capsule are drawn pushed
  /// outwards, so the list's own hit testing would pick the wrong one.
  void _onTapUp(TapUpDetails d, double width) {
    final fromCentre = d.localPosition.dx - width / 2;
    if (fromCentre.abs() <= _capsuleWidth / 2) return; // the selected day
    final unpushed = fromCentre - fromCentre.sign * _push;
    final offset = _controller.hasClients ? _controller.offset : 0.0;
    final index = ((offset + unpushed) / _extent).round().clamp(
      0,
      widget.dates.length - 1,
    );
    widget.onChanged(widget.dates[index]);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, c) {
          final side = (c.maxWidth - _extent) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (d) => _onTapUp(d, c.maxWidth),
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onNotification,
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const _SnapToDayPhysics(
                      extent: _extent,
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: side),
                    itemExtent: _extent,
                    itemCount: widget.dates.length,
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final offset = _controller.hasClients
                            ? _controller.offset
                            : _centre * _extent;
                        final dx = i * _extent - offset;
                        final t = (dx.abs() / _extent).clamp(0.0, 1.0);
                        return Transform.translate(
                          offset: Offset(dx.sign * _push * t, 0),
                          // Hidden under the capsule as it reaches the centre.
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      // Selected straight away; didUpdateWidget slides it to the centre.
                      child: _Day(
                        date: widget.dates[i],
                        onTap: () => widget.onChanged(widget.dates[i]),
                      ),
                    ),
                  ),
                ),
              ),
              // The fixed centre: always here, only its date changes.
              IgnorePointer(
                child: Container(
                  width: _capsuleWidth,
                  height: _height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      Fmt.dayMonthYear(widget.dates[_centre]),
                      key: ValueKey(_centre),
                      maxLines: 1,
                      style: text.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: Fmt.dayMonthYear(date),
      excludeSemantics: true,
      // Taps are resolved by the selector; this keeps screen readers working.
      onTap: onTap,
      child: Center(
        child: Text(
          '${date.day}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Flings carry on naturally but always come to rest exactly on a day.
class _SnapToDayPhysics extends ScrollPhysics {
  const _SnapToDayPhysics({required this.extent, super.parent});

  final double extent;

  @override
  _SnapToDayPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapToDayPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    // Where a free fling would stop, rounded to the nearest day.
    final travel = FrictionSimulation(0.135, position.pixels, velocity);
    final target = (travel.finalX / extent).round() * extent;
    final clamped = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((clamped - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 120, ratio: 1),
      position.pixels,
      clamped,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
