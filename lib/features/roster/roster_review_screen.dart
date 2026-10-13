import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metric_pill.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import 'roster_widgets.dart';

/// Step 2 of the OCR import: check and correct what was read, then save.
class RosterReviewScreen extends StatefulWidget {
  const RosterReviewScreen({
    super.key,
    required this.result,
    required this.month,
  });

  final RosterScanResult result;
  final DateTime month;

  static Route<void> route({
    required RosterScanResult result,
    required DateTime month,
  }) => MaterialPageRoute(
    builder: (_) => RosterReviewScreen(result: result, month: month),
  );

  @override
  State<RosterReviewScreen> createState() => _RosterReviewScreenState();
}

class _RosterReviewScreenState extends State<RosterReviewScreen> {
  late final List<ParsedRosterShift> _rows = [...widget.result.shifts];
  bool _overwrite = false;
  bool _saving = false;

  int get _toCheck => _rows.where((r) => r.lowConfidence).length;

  void _setCode(int i, RosterCode code) {
    setState(() {
      _rows[i] = _rows[i].copyWith(
        type: code.type,
        leaveType: code.leave,
        status: code.isLeave ? ShiftStatus.leave : ShiftStatus.scheduled,
        otHours: code.isLeave ? 0 : _rows[i].otHours,
      );
    });
  }

  Future<void> _editOt(int i) async {
    var hours = _rows[i].otHours;
    final saved = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            'OT on ${Fmt.weekday(_rows[i].date)} ${_rows[i].date.day}',
          ),
          content: Row(
            children: [
              IconButton.filledTonal(
                onPressed: hours <= 0
                    ? null
                    : () => setLocal(() => hours -= 0.5),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '${Fmt.hours(hours)} hrs',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton.filledTonal(
                onPressed: hours >= 16
                    ? null
                    : () => setLocal(() => hours += 0.5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, hours),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      setState(() => _rows[i] = _rows[i].copyWith(otHours: saved));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    try {
      final r = await scope.repository.bulkShifts([
        for (final row in _rows) row.toDraft(),
      ], overwrite: _overwrite);
      scope.sync.changed();
      if (!mounted) return;
      context.showMessage(
        'Roster saved: ${r.inserted} added'
        '${r.updated > 0 ? ', ${r.updated} updated' : ''}'
        '${r.skipped > 0 ? ', ${r.skipped} already existed' : ''}',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showMessage('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = widget.result;

    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      const PageHeader(title: 'Review Roster'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: MetricPill(
                              icon: Icons.event_note_rounded,
                              label: Fmt.monthYear(widget.month),
                              value: '${_rows.length} shifts read',
                              accent: AppColors.lavenderDeep,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricPill(
                              icon: Icons.fact_check_outlined,
                              label: 'Needs a look',
                              value: _toCheck == 0
                                  ? 'All clear'
                                  : '$_toCheck to check',
                              accent: _toCheck == 0
                                  ? AppColors.mintDeep
                                  : AppColors.peachDeep,
                            ),
                          ),
                        ],
                      ),
                      if (result.warnings.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.gap),
                        PastelCard(
                          color: AppColors.peach,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final w in result.warnings)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: AppColors.peachDeep,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: text.bodyMedium?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.gap),
                      Text(
                        'Tap a code to change it. Swipe a row away to drop it.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      if (_rows.isEmpty)
                        PastelCard(
                          elevated: true,
                          child: Text(
                            'Nothing could be read from this photo. Go back and try a clearer, well-lit shot.',
                            style: text.bodyMedium,
                          ),
                        ),
                      for (var i = 0; i < _rows.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(
                              '${_rows[i].date}-${_rows[i].type}-$i',
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                              ),
                            ),
                            onDismissed: (_) =>
                                setState(() => _rows.removeAt(i)),
                            child: _RowTile(
                              row: _rows[i],
                              onCode: (c) => _setCode(i, c),
                              onOt: () => _editOt(i),
                            ),
                          ),
                        ),
                      if (result.unparsed.isNotEmpty)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            '${result.unparsed.length} line(s) skipped',
                            style: text.titleSmall,
                          ),
                          children: [
                            for (final u in result.unparsed)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(u, style: text.bodySmall),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                _SaveBar(
                  count: _rows.length,
                  overwrite: _overwrite,
                  saving: _saving,
                  onOverwrite: (v) => setState(() => _overwrite = v),
                  onSave: _rows.isEmpty || _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onCode, required this.onOt});

  final ParsedRosterShift row;
  final ValueChanged<RosterCode> onCode;
  final VoidCallback onOt;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final code = RosterCode.of(row.type, row.leaveType);
    return PastelCard(
      elevated: true,
      color: row.lowConfidence ? AppColors.peach : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Fmt.weekday(row.date), style: text.bodySmall),
                Text('${row.date.day}', style: text.titleMedium),
              ],
            ),
          ),
          RosterCodeButton(
            code: code,
            onChanged: (c) => c == null ? null : onCode(c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code.label, style: text.titleSmall),
                Text(
                  row.lowConfidence
                      ? 'Read as "${row.source}" · please check'
                      : 'Read as "${row.source}"',
                  style: text.bodySmall?.copyWith(
                    color: row.lowConfidence ? AppColors.peachDeep : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!code.isLeave && code != RosterCode.off || row.otHours > 0)
            ActionChip(
              onPressed: onOt,
              label: Text(
                row.otHours > 0 ? '+${Fmt.hours(row.otHours)}h OT' : '+ OT',
              ),
              shape: const StadiumBorder(),
              side: BorderSide.none,
              backgroundColor: row.otHours > 0
                  ? AppColors.lavender
                  : AppColors.surfaceMuted,
            ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.count,
    required this.overwrite,
    required this.saving,
    required this.onOverwrite,
    required this.onSave,
  });

  final int count;
  final bool overwrite;
  final bool saving;
  final ValueChanged<bool> onOverwrite;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(26));
    // Material (not a coloured Container) so the switch tile's ink ripple shows.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(0.08),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: overwrite,
                onChanged: onOverwrite,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Replace days I already entered'),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSave,
                  child: saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Save $count shifts'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
