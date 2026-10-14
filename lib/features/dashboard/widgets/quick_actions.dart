import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pastel_card.dart';
import '../../../data/models.dart';
import '../../../core/i18n/i18n.dart';

/// Two quick-action cards side by side; stacked on narrow screens.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.today,
    required this.onScanRoster,
    required this.onManualInput,
  });

  /// Today's shift, which the Leave & OT toggles edit. Null disables them.
  final Shift? today;
  final VoidCallback onScanRoster;
  final VoidCallback onManualInput;

  @override
  Widget build(BuildContext context) {
    final tracker = _LeaveOtTrackerCard(shift: today);
    _RosterCard roster({required bool stretch}) => _RosterCard(
      onScan: onScanRoster,
      onManual: onManualInput,
      stretch: stretch,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              roster(stretch: false),
              const SizedBox(height: AppSpacing.gap),
              tracker,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: roster(stretch: true)),
              const SizedBox(width: AppSpacing.gap),
              Expanded(child: tracker),
            ],
          ),
        );
      },
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.onScan,
    required this.onManual,
    required this.stretch,
  });

  final VoidCallback onScan;
  final VoidCallback onManual;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.peach,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.document_scanner_outlined,
            iconColor: AppColors.peachDeep,
          ),
          const SizedBox(height: 12),
          Text(context.tr('Monthly Roster'), style: text.titleMedium),
          const SizedBox(height: 2),
          Text('Import next month\'s duties', style: text.bodySmall),
          // Pin buttons to the bottom when side by side. A Spacer would break the
          // stacked layout, where the scroll view gives unbounded height.
          if (stretch) const Spacer(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            // No icons: at half-card width the label needs all the room.
            child: FilledButton(
              onPressed: onScan,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: FittedBox(child: Text(context.tr('Scan Image (OCR)'))),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onManual,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: FittedBox(child: Text(context.tr('Manual Input'))),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Toggle { casualLeave, noPay, otExtension }

extension on _Toggle {
  String get label => switch (this) {
    _Toggle.casualLeave => 'Casual Leave',
    _Toggle.noPay => 'No-Pay',
    _Toggle.otExtension => 'OT +1 hr',
  };

  IconData get icon => switch (this) {
    _Toggle.casualLeave => Icons.beach_access_outlined,
    _Toggle.noPay => Icons.money_off_rounded,
    _Toggle.otExtension => Icons.more_time_rounded,
  };
}

/// Quick edits to today's shift, saved immediately with Undo.
///
/// Mirrors the API rules: the two leave types are mutually exclusive, and a leave
/// day can't carry OT. The leave toggles reflect the saved shift; the OT toggle
/// tracks this session's one-hour extension.
class _LeaveOtTrackerCard extends StatefulWidget {
  const _LeaveOtTrackerCard({required this.shift});

  final Shift? shift;

  @override
  State<_LeaveOtTrackerCard> createState() => _LeaveOtTrackerCardState();
}

class _LeaveOtTrackerCardState extends State<_LeaveOtTrackerCard> {
  bool _extended = false;
  _Toggle? _busy;

  @override
  void didUpdateWidget(_LeaveOtTrackerCard old) {
    super.didUpdateWidget(old);
    if (old.shift?.id != widget.shift?.id) _extended = false;
  }

  bool _isOn(_Toggle t, Shift s) => switch (t) {
    _Toggle.casualLeave => s.leaveType == LeaveType.casual,
    _Toggle.noPay => s.leaveType == LeaveType.noPay,
    _Toggle.otExtension => _extended,
  };

  Future<void> _toggle(_Toggle t) async {
    final s = widget.shift!;
    final scope = AppScope.of(context);
    final on = !_isOn(t, s);

    final ShiftUpdate change;
    final ShiftUpdate undo;
    if (t == _Toggle.otExtension) {
      change = ShiftUpdate(otHours: (s.otHours + (on ? 1 : -1)).clamp(0, 16));
      undo = ShiftUpdate(otHours: s.otHours);
    } else {
      final leave = t == _Toggle.casualLeave
          ? LeaveType.casual
          : LeaveType.noPay;
      change = on
          ? ShiftUpdate(leaveType: leave, otHours: 0)
          : const ShiftUpdate(
              status: ShiftStatus.scheduled,
              leaveType: LeaveType.none,
            );
      undo = s.isLeave
          ? ShiftUpdate(leaveType: s.leaveType, otHours: 0)
          : ShiftUpdate(
              status: s.status,
              leaveType: LeaveType.none,
              otHours: s.otHours,
            );
    }

    setState(() => _busy = t);
    try {
      await scope.repository.updateShift(s.id, change);
      if (t == _Toggle.otExtension) _extended = on;
      scope.sync.changed();
      if (!mounted) return;
      context.showMessage(
        on
            ? context.tr('{item} saved for today', {
                'item': context.tr(t.label),
              })
            : context.tr('{item} removed', {'item': context.tr(t.label)}),
        action: SnackBarAction(
          label: context.tr('Undo'),
          textColor: AppColors.lavender,
          onPressed: () async {
            await scope.repository.updateShift(s.id, undo);
            if (t == _Toggle.otExtension && mounted) {
              setState(() => _extended = !on);
            }
            scope.sync.changed();
          },
        ),
      );
    } catch (e) {
      if (mounted) context.showMessage('$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = widget.shift;
    final workDay = s != null && s.type != ShiftType.off;

    return PastelCard(
      color: AppColors.mint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.event_available_rounded,
            iconColor: AppColors.mintDeep,
          ),
          const SizedBox(height: 12),
          Text(context.tr('Leave & OT Tracker'), style: text.titleMedium),
          const SizedBox(height: 2),
          Text(
            workDay
                ? context.tr('Quick log for today')
                : context.tr('No duty today to log'),
            style: text.bodySmall,
          ),
          const SizedBox(height: 14),
          for (final t in _Toggle.values) ...[
            _TogglePill(
              label: context.tr(t.label),
              icon: t.icon,
              selected: workDay && _isOn(t, s),
              busy: _busy == t,
              enabled:
                  workDay &&
                  _busy == null &&
                  !(t == _Toggle.otExtension && s.isLeave),
              onTap: () => _toggle(t),
            ),
            if (t != _Toggle.values.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return Semantics(
      toggled: selected,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled || busy || selected ? 1 : 0.4,
        child: Material(
          color: selected ? AppColors.ink : Colors.white.withValues(alpha: 0.7),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // The leading icon doubles as the state indicator, leaving
                    // the label the full width of the half-card.
                    SizedBox.square(
                      dimension: 17,
                      child: busy
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: selected
                                  ? Colors.white
                                  : AppColors.mintDeep,
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                selected ? Icons.check_circle_rounded : icon,
                                key: ValueKey(selected),
                                size: 17,
                                color: selected
                                    ? AppColors.mint
                                    : AppColors.mintDeep,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
