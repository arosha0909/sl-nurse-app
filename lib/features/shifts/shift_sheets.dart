import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../onboarding/progressive_prompts.dart';
import 'duty_actions.dart';

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
        s.type != ShiftType.off && !s.isLeave && s.status != ShiftStatus.missed;
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
      title: '${s.code} · ${s.type.label}',
      subtitle:
          '${Fmt.weekday(s.date)}, ${Fmt.dayMonthYear(s.date)} · ${s.type.timeRange}',
      children: [
        if (working && notStarted) ...[
          const _Label('Skipped this duty? Mark leave in one tap'),
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
                            '${leave.label} recorded',
                          ),
                    child: FittedBox(
                      child: Text(leave.label.replaceFirst(' leave', '')),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (s.type.isLongDuty &&
            notStarted &&
            _mainOptions(s.type).length > 1) ...[
          const _Label('Main shift hours'),
          MainHoursPicker(
            type: s.type,
            value: s.standardHours,
            onChanged: _busy
                ? null
                : (h) => _update(
                    ShiftUpdate(standardHours: h),
                    h >= s.type.spanHours
                        ? 'Whole duty counted as main shift'
                        : 'OT starts after ${Fmt.hours(h)} hrs',
                  ),
          ),
          const SizedBox(height: 16),
        ],
        if (working || canEndOt) ...[
          const _Label('Attendance'),
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
        if (!s.isLeave) ...[
          const _Label('OT hours'),
          PastelCard(
            color: AppColors.lavender,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Less OT',
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
                  tooltip: 'More OT',
                  onPressed: _ot >= 16 || _busy
                      ? null
                      : () => setState(() => _ot = (_ot + 0.5).clamp(0, 16)),
                  icon: const Icon(Icons.add_rounded),
                ),
                FilledButton(
                  onPressed: _ot == s.otHours || _busy
                      ? null
                      : () => _update(ShiftUpdate(otHours: _ot), 'OT updated'),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const _Label('Mark as'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: 'Completed',
              selected: s.status == ShiftStatus.completed,
              onTap: _busy
                  ? null
                  : () => _update(
                      const ShiftUpdate(status: ShiftStatus.completed),
                      'Marked completed',
                    ),
            ),
            _StatusChip(
              label: 'Missed',
              selected: s.status == ShiftStatus.missed,
              onTap: _busy
                  ? null
                  : () => _update(
                      const ShiftUpdate(status: ShiftStatus.missed, otHours: 0),
                      'Marked missed',
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
                label: leave.label,
                selected: s.leaveType == leave,
                // A leave day can't carry OT, so clear it in the same request.
                onTap: _busy
                    ? null
                    : () => _update(
                        ShiftUpdate(leaveType: leave, otHours: 0),
                        '${leave.label} recorded',
                      ),
              ),
            if (s.status != ShiftStatus.scheduled)
              _StatusChip(
                label: 'Back to scheduled',
                selected: false,
                onTap: _busy
                    ? null
                    : () => _update(
                        const ShiftUpdate(
                          status: ShiftStatus.scheduled,
                          leaveType: LeaveType.none,
                        ),
                        'Shift reset to scheduled',
                      ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _busy ? null : _confirmDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete shift'),
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

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this shift?'),
        content: const Text(
          'It will be removed from your roster and salary calculations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(
        () => AppScope.of(context).repository.deleteShift(widget.shift.id),
        'Shift deleted',
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
      label: Text(action.label),
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
      success: '${_type.label} added',
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
      title: 'Add shift',
      subtitle: '${Fmt.weekday(widget.date)}, ${Fmt.dayMonthYear(widget.date)}',
      children: [
        const _Label('Duty'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ShiftType.values)
              _StatusChip(
                label: '${t.code}  ${t.label.replaceFirst(' Shift', '')}',
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
          const _Label('Main shift hours'),
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
            title: const Text('Already worked'),
            subtitle: const Text('Counts towards earned pay'),
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
          const _Label('OT hours'),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Less OT',
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
                tooltip: 'More OT',
                onPressed: _ot >= 16 ? null : () => setState(() => _ot += 0.5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
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
              : const Text('Add shift'),
        ),
      ],
    );
  }
}
