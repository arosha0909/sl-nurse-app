import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../onboarding/progressive_prompts.dart';
import 'duty_actions.dart';
import '../../core/i18n/i18n.dart';

/// Opens the actions sheet for [shift]. Returns true if something changed.
Future<bool?> showShiftActions(BuildContext context, Shift shift) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShiftActionsSheet(shift: shift),
    );

/// Opens the "add shift" sheet for [date]. Returns true if a shift was created.
/// First time only, asks for the primary hospital/ward (skippable) before adding.
Future<bool?> showAddShift(BuildContext context, DateTime date) async {
  await ProgressivePrompts.ensureWorkplace(context);
  if (!context.mounted) return null;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddShiftSheet(date: date),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: text.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: text.bodyMedium),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Workflow actions + status/OT edits + delete for one shift.
class ShiftActionsSheet extends StatefulWidget {
  const ShiftActionsSheet({super.key, required this.shift});

  final Shift shift;

  @override
  State<ShiftActionsSheet> createState() => _ShiftActionsSheetState();
}

class _ShiftActionsSheetState extends State<ShiftActionsSheet> {
  late double _ot = widget.shift.otHours;
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() task,
    String success, {
    bool checkedIn = false,
  }) async {
    setState(() => _busy = true);
    final scope = AppScope.of(context);
    final ok = await context.runWithFeedback(task, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      scope.sync.changed();
      final navigator = Navigator.of(context);
      navigator.pop(true);
      // First check-in on this device: offer shift reminders (from the page below the sheet).
      if (checkedIn) await ProgressivePrompts.offerReminders(navigator.context);
    }
  }

  Future<void> _update(ShiftUpdate u, String success) => _run(
    () => AppScope.of(context).repository.updateShift(widget.shift.id, u),
    success,
    checkedIn: u.action == ShiftAction.checkIn,
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    final working =
        s.type != ShiftType.off &&
        !s.isLeave &&
        !s.isSwapped &&
        s.status != ShiftStatus.missed;
    final canCheckIn = working && s.checkInTime == null;
    final canSignOut =
        working &&
        s.checkInTime != null &&
        s.checkOutTime == null &&
        s.otStartTime == null;
    // On a long duty OT starts by itself after the main hours: no manual switch.
    final canStartOt =
        working &&
        !s.hasAutoOt &&
        s.checkInTime != null &&
        s.otStartTime == null;
    final canEndOt = s.otInProgress;
    final notStarted =
        s.checkInTime == null && s.status == ShiftStatus.scheduled;

    return _SheetFrame(
      title: '${s.code} · ${context.tr(s.type.label)}',
      subtitle:
          '${Fmt.weekday(s.date)}, ${Fmt.dayMonthYear(s.date)} · ${s.type.timeRange}',
      children: [
        if (s.isSwapped)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PastelCard(
              color: AppColors.peach,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.peachDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('Given to {name} in a duty swap', {
                        'name': s.swappedWith ?? '—',
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (working && notStarted) ...[
          _Label(context.tr('Skipped this duty? Mark leave in one tap')),
          Row(
            children: [
              for (final (i, leave) in const [
                LeaveType.casual,
                LeaveType.sick,
                LeaveType.noPay,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _update(
                            ShiftUpdate(leaveType: leave, otHours: 0),
                            context.tr('{leave} recorded', {
                              'leave': context.tr(leave.label),
                            }),
                          ),
                    child: FittedBox(
                      child: Text(
                        context.tr(leave.label.replaceFirst(' leave', '')),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _swap,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(context.tr('Swap with a colleague')),
          ),
          const SizedBox(height: 16),
        ],
        if (s.type.isLongDuty &&
            notStarted &&
            _mainOptions(s.type).length > 1) ...[
          _Label(context.tr('Main shift hours')),
          MainHoursPicker(
            type: s.type,
            value: s.standardHours,
            onChanged: _busy
                ? null
                : (h) => _update(
                    ShiftUpdate(standardHours: h),
                    h >= s.type.spanHours
                        ? context.tr('Whole duty counted as main shift')
                        : context.tr('OT starts after {hours} hrs', {
                            'hours': Fmt.hours(h),
                          }),
                  ),
          ),
          const SizedBox(height: 16),
        ],
        if (working || canEndOt) ...[
          _Label(context.tr('Attendance')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                ShiftAction.checkIn,
                Icons.login_rounded,
                enabled: canCheckIn && !_busy,
                onTap: _act,
              ),
              _ActionChip(
                ShiftAction.checkOut,
                Icons.logout_rounded,
                enabled: canSignOut && !_busy,
                onTap: _act,
              ),
              _ActionChip(
                ShiftAction.switchToOt,
                Icons.more_time_rounded,
                enabled: canStartOt && !_busy,
                onTap: _act,
              ),
              _ActionChip(
                ShiftAction.endOt,
                Icons.timer_off_outlined,
                enabled: canEndOt && !_busy,
                onTap: _act,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (working)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.publicHoliday,
              onChanged: _busy
                  ? null
                  : (v) => _update(
                      ShiftUpdate(publicHoliday: v),
                      v
                          ? context.tr('Marked as public holiday duty')
                          : context.tr('Public holiday removed'),
                    ),
              title: Text(context.tr('Public holiday duty')),
              subtitle: Text(
                s.isSunday
                    ? context.tr('Sunday duty is counted automatically')
                    : context.tr('Earns the holiday rate set in Pay rules'),
              ),
            ),
          ),
        if (!s.isLeave && !s.isSwapped) ...[
          _Label(context.tr('OT hours')),
          PastelCard(
            color: AppColors.lavender,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.tr('Less OT'),
                  onPressed: _ot <= 0 || _busy
                      ? null
                      : () => setState(() => _ot = (_ot - 0.5).clamp(0, 16)),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '${Fmt.hours(_ot)} hrs',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('More OT'),
                  onPressed: _ot >= 16 || _busy
                      ? null
                      : () => setState(() => _ot = (_ot + 0.5).clamp(0, 16)),
                  icon: const Icon(Icons.add_rounded),
                ),
                FilledButton(
                  onPressed: _ot == s.otHours || _busy
                      ? null
                      : () => _update(
                          ShiftUpdate(otHours: _ot),
                          context.tr('OT updated'),
                        ),
                  child: Text(context.tr('Save')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _Label(context.tr('Mark as')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: context.tr('Completed'),
              selected: s.status == ShiftStatus.completed,
              onTap: _busy
                  ? null
                  : () => _update(
                      const ShiftUpdate(status: ShiftStatus.completed),
                      context.tr('Marked completed'),
                    ),
            ),
            _StatusChip(
              label: context.tr('Missed'),
              selected: s.status == ShiftStatus.missed,
              onTap: _busy
                  ? null
                  : () => _update(
                      const ShiftUpdate(status: ShiftStatus.missed, otHours: 0),
                      context.tr('Marked missed'),
                    ),
            ),
            for (final leave in [
              LeaveType.casual,
              LeaveType.sick,
              LeaveType.noPay,
              LeaveType.halfDay,
              LeaveType.vacation,
              LeaveType.publicHoliday,
            ])
              _StatusChip(
                label: context.tr(leave.label),
                selected: s.leaveType == leave,
                // A leave day can't carry OT, so clear it in the same request.
                onTap: _busy
                    ? null
                    : () => _update(
                        ShiftUpdate(leaveType: leave, otHours: 0),
                        context.tr('{leave} recorded', {
                          'leave': context.tr(leave.label),
                        }),
                      ),
              ),
            if (s.status != ShiftStatus.scheduled)
              _StatusChip(
                label: context.tr('Back to scheduled'),
                selected: false,
                onTap: _busy
                    ? null
                    : () => _update(
                        const ShiftUpdate(
                          status: ShiftStatus.scheduled,
                          leaveType: LeaveType.none,
                        ),
                        context.tr('Shift reset to scheduled'),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _busy ? null : _confirmDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(context.tr('Delete shift')),
        ),
      ],
    );
  }

  /// Attendance runs from the page below the sheet, so the check-out summary and
  /// prompts appear there once the sheet has closed.
  Future<void> _act(ShiftAction action) async {
    final navigator = Navigator.of(context);
    navigator.pop(true);
    await runDutyAction(navigator.context, widget.shift, action);
  }

  Future<void> _swap() async {
    final result = await showDialog<_SwapRequest>(
      context: context,
      builder: (_) => _SwapDialog(date: widget.shift.date),
    );
    if (result == null || !mounted) return;
    await _run(
      () => AppScope.of(context).repository.swapShift(
        widget.shift.id,
        colleague: result.colleague,
        takeDate: result.takeDate,
        takeType: result.takeType,
      ),
      context.tr('Duty swapped with {name}', {'name': result.colleague}),
    );
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete this shift?')),
        content: Text(
          context.tr(
            'It will be removed from your roster and salary calculations.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(
        () => AppScope.of(context).repository.deleteShift(widget.shift.id),
        context.tr('Shift deleted'),
      );
    }
  }
}

/// Main-shift hours a long duty can be logged with; the rest is OT.
List<double> _mainOptions(ShiftType type) => switch (type) {
  ShiftType.day => const [6, 12],
  ShiftType.twentyFour => const [6, 12, 24],
  _ => [type.standardHours],
};

/// "6 h + 6 h OT" / "12 h, no OT" choices for a long duty.
class MainHoursPicker extends StatelessWidget {
  const MainHoursPicker({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final ShiftType type;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final h in _mainOptions(type))
          _StatusChip(
            label: h >= type.spanHours
                ? '${Fmt.hours(h)} h, no OT'
                : '${Fmt.hours(h)} h + ${Fmt.hours(type.spanHours - h)} h OT',
            selected: value == h,
            onTap: onChanged == null ? null : () => onChanged!(h),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
    this.action,
    this.icon, {
    required this.enabled,
    required this.onTap,
  });

  final ShiftAction action;
  final IconData icon;
  final bool enabled;
  final void Function(ShiftAction) onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? () => onTap(action) : null,
      icon: Icon(icon, size: 18),
      label: Text(context.tr(action.label)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null || selected ? null : (_) => onTap!(),
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.ink,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Create a shift on a given date.
class AddShiftSheet extends StatefulWidget {
  const AddShiftSheet({super.key, required this.date});

  final DateTime date;

  @override
  State<AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<AddShiftSheet> {
  ShiftType _type = ShiftType.morning;
  late bool _completed = widget.date.isBefore(dayOf(DateTime.now()));
  double _ot = 0;
  double? _main;
  bool _busy = false;

  double get _mainHours => _main ?? _type.standardHours;

  /// Long duties carry their OT built in; standard shifts take extra OT by hand.
  bool get _autoOt => _type.spanHours > _mainHours;

  /// A night or 24-hour duty the day before ends at 07:00 on this date.
  bool _afterNight = false;
  bool _checkedNight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedNight) return;
    _checkedNight = true;
    final before = widget.date.subtract(const Duration(days: 1));
    AppScope.of(context).repository
        .shifts(from: before, to: before)
        .then((list) {
          final night = list.any(
            (s) =>
                (s.type == ShiftType.night || s.type == ShiftType.twentyFour) &&
                !s.isLeave &&
                !s.isSwapped,
          );
          if (mounted && night) setState(() => _afterNight = true);
        })
        .catchError((_) {});
  }

  /// Duties that start at 07:00, right when the night before ends.
  bool get _noRest => _afterNight && _type.startHour == 7;

  Future<void> _save() async {
    setState(() => _busy = true);
    final scope = AppScope.of(context);
    final ok = await context.runWithFeedback(
      () => scope.repository.createShift(
        ShiftDraft(
          date: widget.date,
          type: _type,
          status: _completed ? ShiftStatus.completed : ShiftStatus.scheduled,
          otHours: _autoOt ? 0 : _ot,
          standardHours: _type.isLongDuty ? _mainHours : null,
        ),
      ),
      success: context.tr('{shift} added', {'shift': context.tr(_type.label)}),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      scope.sync.changed();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final past = !widget.date.isAfter(dayOf(DateTime.now()));
    return _SheetFrame(
      title: context.tr('Add shift'),
      subtitle: '${Fmt.weekday(widget.date)}, ${Fmt.dayMonthYear(widget.date)}',
      children: [
        _Label(context.tr('Duty')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ShiftType.values)
              _StatusChip(
                label:
                    '${t.code}  ${context.tr(t.label.replaceFirst(' Shift', ''))}',
                selected: _type == t,
                onTap: () => setState(() {
                  _type = t;
                  _main = null;
                  _ot = 0;
                }),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(_type.timeRange, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        if (_mainOptions(_type).length > 1) ...[
          _Label(context.tr('Main shift hours')),
          MainHoursPicker(
            type: _type,
            value: _mainHours,
            onChanged: (h) => setState(() => _main = h),
          ),
          const SizedBox(height: 12),
        ],
        if (past)
          SwitchListTile(
            value: _completed,
            onChanged: (v) => setState(() => _completed = v),
            title: Text(context.tr('Already worked')),
            subtitle: Text(context.tr('Counts towards earned pay')),
            contentPadding: EdgeInsets.zero,
          ),
        if (_autoOt)
          PastelCard(
            color: AppColors.peach,
            padding: const EdgeInsets.all(12),
            child: Text(
              '${Fmt.hours(_type.spanHours - _mainHours)} hrs OT built in. It starts automatically '
              'after ${Fmt.hours(_mainHours)} hrs of main shift, with a single check-in.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else ...[
          _Label(context.tr('OT hours')),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: context.tr('Less OT'),
                onPressed: _ot <= 0 ? null : () => setState(() => _ot -= 0.5),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '${Fmt.hours(_ot)} hrs',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: context.tr('More OT'),
                onPressed: _ot >= 16 ? null : () => setState(() => _ot += 0.5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
        if (_noRest)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: PastelCard(
              color: AppColors.peach,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.bedtime_rounded, color: AppColors.peachDeep),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Your night duty ends at 07:00 this morning. This duty starts straight after it, with no sleep.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.tr('Add shift')),
        ),
      ],
    );
  }
}

typedef _SwapRequest = ({
  String colleague,
  DateTime? takeDate,
  ShiftType? takeType,
});

/// Who takes this duty, and which of their duties (if any) the nurse works instead.
class _SwapDialog extends StatefulWidget {
  const _SwapDialog({required this.date});

  final DateTime date;

  @override
  State<_SwapDialog> createState() => _SwapDialogState();
}

class _SwapDialogState extends State<_SwapDialog> {
  final _name = TextEditingController();
  bool _takeReturn = true;
  late DateTime _takeDate = widget.date.add(const Duration(days: 1));
  ShiftType _takeType = ShiftType.morning;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _takeDate,
      firstDate: widget.date.subtract(const Duration(days: 60)),
      lastDate: widget.date.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _takeDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valid = _name.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(context.tr('Swap with a colleague')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.tr('Colleague\'s name'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _takeReturn,
              onChanged: (v) => setState(() => _takeReturn = v),
              title: Text(context.tr('I take one of their duties')),
            ),
            if (_takeReturn) ...[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  '${Fmt.weekday(_takeDate)}, ${Fmt.dayMonthYear(_takeDate)}',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in ShiftType.values.where(
                    (t) => t != ShiftType.off,
                  ))
                    ChoiceChip(
                      label: Text(t.code),
                      tooltip: context.tr(t.label),
                      selected: _takeType == t,
                      onSelected: (_) => setState(() => _takeType = t),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(context.tr(_takeType.label), style: text.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop<_SwapRequest>(context, (
                  colleague: _name.text.trim(),
                  takeDate: _takeReturn ? _takeDate : null,
                  takeType: _takeReturn ? _takeType : null,
                ))
              : null,
          child: Text(context.tr('Swap')),
        ),
      ],
    );
  }
}
