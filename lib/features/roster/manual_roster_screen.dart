import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../onboarding/progressive_prompts.dart';
import 'manual_roster_help.dart';
import 'roster_widgets.dart';

/// Type a month's roster by hand: one code per day, with a rota quick-fill.
class ManualRosterScreen extends StatefulWidget {
  const ManualRosterScreen({super.key});

  /// Opens the screen, asking once for the primary hospital/ward first (skippable).
  static Future<void> open(BuildContext context) async {
    await ProgressivePrompts.ensureWorkplace(context);
    if (context.mounted) await Navigator.of(context).push(route());
  }

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ManualRosterScreen());

  @override
  State<ManualRosterScreen> createState() => _ManualRosterScreenState();
}

class _ManualRosterScreenState extends State<ManualRosterScreen> {
  late DateTime _month;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final today = AppScope.of(context).today();
    _month = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final today = scope.today();
    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.screenPadding,
                    AppSpacing.screenPadding,
                    12,
                  ),
                  child: Column(
                    children: [
                      PageHeader(
                        title: 'Manual Roster',
                        trailing: CircleIconButton(
                          icon: Icons.help_outline_rounded,
                          tooltip: 'How to add your roster',
                          onPressed: () => showManualRosterHelp(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MonthSwitcher(
                        month: _month,
                        min: DateTime(today.year, today.month - 3),
                        max: DateTime(today.year, today.month + 3),
                        onChanged: (m) => setState(() => _month = m),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AsyncView<List<Shift>>(
                    reloadKey: _month,
                    load: () => scope.repository.shifts(
                      from: _month,
                      to: DateTime(_month.year, _month.month + 1, 0),
                    ),
                    // Keyed by month so edits don't leak between months.
                    builder: (context, shifts, _) => _MonthEditor(
                      key: ValueKey(_month),
                      month: _month,
                      existing: shifts,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthEditor extends StatefulWidget {
  const _MonthEditor({super.key, required this.month, required this.existing});

  final DateTime month;
  final List<Shift> existing;

  @override
  State<_MonthEditor> createState() => _MonthEditorState();
}

class _MonthEditorState extends State<_MonthEditor> {
  late final int _days = DateTime(
    widget.month.year,
    widget.month.month + 1,
    0,
  ).day;
  late final Map<int, RosterCode?> _original = {
    for (var d = 1; d <= _days; d++) d: _codeFromExisting(d),
  };
  late final Map<int, RosterCode?> _codes = {..._original};
  bool _saving = false;

  /// Days with more than one entry (e.g. a double) are shown but not editable here.
  late final Set<int> _multi = {
    for (var d = 1; d <= _days; d++)
      if (widget.existing.where((s) => s.date.day == d).length > 1) d,
  };

  RosterCode? _codeFromExisting(int day) {
    final onDay = widget.existing.where((s) => s.date.day == day).toList();
    if (onDay.isEmpty) return null;
    return RosterCode.ofShift(onDay.first);
  }

  List<int> get _changed => [
    for (var d = 1; d <= _days; d++)
      if (_codes[d] != _original[d]) d,
  ];

  Future<void> _fillRota() async {
    const pattern = [
      RosterCode.morning,
      RosterCode.morning,
      RosterCode.evening,
      RosterCode.evening,
      RosterCode.night,
      RosterCode.night,
      RosterCode.off,
    ];
    var start = 1;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Fill with rota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '7  7  1  1  N  N  DO, repeating.\nOnly empty days are filled.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Start on day'),
                  const Spacer(),
                  IconButton(
                    onPressed: start > 1 ? () => setLocal(() => start--) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text(
                    '$start',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: start < _days
                        ? () => setLocal(() => start++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, start),
              child: const Text('Fill'),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      for (var d = picked; d <= _days; d++) {
        if (_codes[d] == null && !_multi.contains(d)) {
          _codes[d] = pattern[(d - picked) % pattern.length];
        }
      }
    });
  }

  Future<void> _save() async {
    final changed = _changed;
    if (changed.isEmpty) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final repo = scope.repository;
    try {
      // A changed day replaces its old entry: the API keys shifts by (date, type),
      // so a new type would otherwise create a second shift on the same day.
      for (final d in changed) {
        for (final s in widget.existing.where((s) => s.date.day == d)) {
          await repo.deleteShift(s.id);
        }
      }
      final drafts = [
        for (final d in changed)
          if (_codes[d] != null)
            _codes[d]!.draft(
              DateTime(widget.month.year, widget.month.month, d),
              // Extra OT on a standard shift is kept; a long duty's OT is planned by the API.
              otHours: _codes[d]!.type.isLongDuty
                  ? 0
                  : widget.existing
                        .where((s) => s.date.day == d && !s.type.isLongDuty)
                        .fold(0.0, (m, s) => s.otHours > m ? s.otHours : m),
            ),
      ];
      if (drafts.isNotEmpty) await repo.bulkShifts(drafts, overwrite: true);
      scope.sync.changed();
      if (!mounted) return;
      context.showMessage(
        '${changed.length} day(s) saved for ${Fmt.monthYear(widget.month)}',
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) context.showMessage('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final changed = _changed.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              12,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap a day to set its shift',
                      style: text.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fillRota,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Fill rota'),
                  ),
                ],
              ),
              PastelCard(
                elevated: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (var d = 1; d <= _days; d++)
                      _DayRow(
                        date: DateTime(
                          widget.month.year,
                          widget.month.month,
                          d,
                        ),
                        code: _codes[d],
                        edited: _codes[d] != _original[d],
                        locked: _multi.contains(d),
                        onChanged: (c) => setState(() => _codes[d] = c),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: AppColors.softShadow(0.08),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: changed == 0 || _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(changed == 0 ? 'No changes' : 'Save $changed day(s)'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.date,
    required this.code,
    required this.edited,
    required this.locked,
    required this.onChanged,
  });

  final DateTime date;
  final RosterCode? code;
  final bool edited;
  final bool locked;
  final ValueChanged<RosterCode?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weekend = date.weekday >= DateTime.saturday;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${date.day}', style: text.titleMedium),
          ),
          SizedBox(
            width: 44,
            child: Text(
              Fmt.weekday(date),
              style: text.bodySmall?.copyWith(
                color: weekend ? AppColors.peachDeep : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              locked
                  ? 'Double shift · edit from Duty details'
                  : (code?.label ?? 'Not set'),
              style: text.bodyMedium?.copyWith(
                color: code == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (edited)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.circle, size: 8, color: AppColors.lavenderDeep),
            ),
          if (locked)
            const SizedBox(
              width: 52,
              child: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            )
          else
            RosterCodeButton(
              code: code,
              allowClear: true,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
