import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal date carousel. Inactive days are plain numbers; the selected day
/// expands into a dark capsule showing the full date.
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
  static const _itemWidth = 42.0;
  static const _activeWidth = 128.0;
  static const _gap = 6.0;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(DateSelector old) {
    super.didUpdateWidget(old);
    if (!_sameDay(old.selected, widget.selected)) _centerSelected();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerSelected({bool animate = true}) {
    if (!_controller.hasClients) return;
    final index = widget.dates.indexWhere((d) => _sameDay(d, widget.selected));
    if (index < 0) return;
    final viewport = _controller.position.viewportDimension;
    final target =
        (index * (_itemWidth + _gap) + _activeWidth / 2 - viewport / 2).clamp(
          0.0,
          _controller.position.maxScrollExtent,
        );
    if (animate) {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(target);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: widget.dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final date = widget.dates[i];
          final active = _sameDay(date, widget.selected);
          return Semantics(
            button: true,
            selected: active,
            label: Fmt.dayMonthYear(date),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => widget.onChanged(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: active ? _activeWidth : _itemWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  active ? Fmt.dayMonthYear(date) : '${date.day}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: text.labelLarge?.copyWith(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
