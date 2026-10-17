import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../roster/roster_widgets.dart';

/// How this nurse's hospital pays: employer type, salary grade, how OT is counted,
/// Sunday / holiday duty pay and leave entitlements. Defaults follow common government
/// practice; every rule can be changed because hospitals differ.
class PayRulesScreen extends StatefulWidget {
  const PayRulesScreen({super.key, required this.config, required this.user});

  final SalaryConfig config;
  final UserProfile user;

  static Future<void> open(
    BuildContext context, {
    required SalaryConfig config,
    required UserProfile user,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PayRulesScreen(config: config, user: user),
    ),
  );

  @override
  State<PayRulesScreen> createState() => _PayRulesScreenState();
}

class _PayRulesScreenState extends State<PayRulesScreen> {
  late SalaryConfig _c = widget.config;
  List<SalaryScale>? _scales;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scales != null) return;
    _scales = const [];
    AppScope.of(context).repository
        .salaryScales()
        .then((s) {
          if (mounted) setState(() => _scales = s);
        })
        .catchError((_) {});
  }

  SalaryScale? get _grade =>
      _scales?.where((s) => s.code == _c.gradeCode).firstOrNull;

  void _set(SalaryConfig c) => setState(() => _c = c);

  Future<void> _save() async {
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final grade = _grade;
    final ok = await context.runWithFeedback(() async {
      await scope.repository.updateSalaryConfig(_c);
      // A chosen grade sets the basic salary used by every calculation.
      if (grade != null) {
        await scope.repository.updateProfile({
          'baseSalary': grade.basicAt(_c.salaryStep ?? 0),
        });
      }
    }, success: context.tr('Pay rules saved'));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      scope.sync.changed();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final private = _c.employerType == EmployerType.private;
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
                      PageHeader(title: context.tr('Pay rules')),
                      const SizedBox(height: 10),
                      Text(
                        context.tr(
                          'Defaults follow common government practice. Hospitals differ, so check these with your hospital and change any that don\'t match.',
                        ),
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _Card(
                        title: context.tr('Employer'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<EmployerType>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: EmployerType.government,
                                  label: Text(context.tr('Government')),
                                ),
                                ButtonSegment(
                                  value: EmployerType.private,
                                  label: Text(context.tr('Private')),
                                ),
                              ],
                              selected: {_c.employerType},
                              onSelectionChanged: (v) =>
                                  _set(_c.copyWith(employerType: v.first)),
                            ),
                            if (private) ...[
                              const SizedBox(height: 10),
                              Text(
                                context.tr(
                                  'Private hospitals usually pay a fixed OT hourly rate: set it under Pay settings. Remove COLA and W&OP there if they don\'t apply to you.',
                                ),
                                style: text.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!private && (_scales ?? const []).isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.gap),
                        _Card(
                          title: context.tr('Salary grade'),
                          child: _GradePicker(
                            scales: _scales!,
                            config: _c,
                            currentBasic: widget.user.baseSalary,
                            onChanged: _set,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.gap),
                      _Card(
                        title: context.tr('How OT is counted'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Choice(
                              selected: _c.otMode == OtMode.perShift,
                              title: context.tr('Per duty'),
                              subtitle: context.tr(
                                'OT recorded on each duty (after the main shift, or the extra hours of a D / 24 duty).',
                              ),
                              onTap: () =>
                                  _set(_c.copyWith(otMode: OtMode.perShift)),
                            ),
                            _Choice(
                              selected: _c.otMode == OtMode.monthlyHours,
                              title: context.tr('From monthly hours'),
                              subtitle: context.tr(
                                'Every hour worked in the month beyond the required duty hours is OT.',
                              ),
                              onTap: () => _set(
                                _c.copyWith(otMode: OtMode.monthlyHours),
                              ),
                            ),
                            if (_c.otMode == OtMode.monthlyHours)
                              _Stepper(
                                label: context.tr('Required hours a month'),
                                value: _c.requiredMonthlyHours,
                                step: 6,
                                min: 60,
                                max: 300,
                                suffix: 'h',
                                onChanged: (v) =>
                                    _set(_c.copyWith(requiredMonthlyHours: v)),
                              ),
                            _Stepper(
                              label: context.tr('Hourly rate divisor'),
                              hint: context.tr(
                                'Basic salary ÷ this = basic hourly rate',
                              ),
                              value: _c.otDivisor,
                              step: 10,
                              min: 100,
                              max: 400,
                              onChanged: (v) => _set(_c.copyWith(otDivisor: v)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      _Card(
                        title: context.tr('Sunday & public holiday duty'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.tr(
                                'Extra pay for each main-shift hour, as a multiple of the basic hourly rate.',
                              ),
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final m in const [0.0, 0.5, 1.0, 1.5, 2.0])
                                  ChoiceChip(
                                    label: Text(
                                      m == 0
                                          ? context.tr('Off')
                                          : '+${Fmt.hours(m)}×',
                                    ),
                                    selected: _c.holidayRateMultiplier == m,
                                    onSelected: (_) => _set(
                                      _c.copyWith(holidayRateMultiplier: m),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _c.sundayIsHoliday,
                              onChanged: (v) =>
                                  _set(_c.copyWith(sundayIsHoliday: v)),
                              title: Text(
                                context.tr('Sundays count as holidays'),
                              ),
                              subtitle: Text(
                                context.tr(
                                  'Mark public holidays on the duty itself (Public holiday duty).',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      _Card(
                        title: context.tr('Leave entitlements (days a year)'),
                        child: Column(
                          children: [
                            _Stepper(
                              label: context.tr('Casual leave'),
                              value: _c.leave.casual.toDouble(),
                              step: 1,
                              min: 0,
                              max: 60,
                              onChanged: (v) => _set(
                                _c.copyWith(
                                  leave: _c.leave.copyWith(casual: v.round()),
                                ),
                              ),
                            ),
                            _Stepper(
                              label: context.tr('Vacation leave'),
                              value: _c.leave.vacation.toDouble(),
                              step: 1,
                              min: 0,
                              max: 60,
                              onChanged: (v) => _set(
                                _c.copyWith(
                                  leave: _c.leave.copyWith(vacation: v.round()),
                                ),
                              ),
                            ),
                            _Stepper(
                              label: context.tr('Sick leave'),
                              hint: context.tr('0 = no fixed quota'),
                              value: _c.leave.sick.toDouble(),
                              step: 1,
                              min: 0,
                              max: 120,
                              onChanged: (v) => _set(
                                _c.copyWith(
                                  leave: _c.leave.copyWith(sick: v.round()),
                                ),
                              ),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    boxShadow: AppColors.softShadow(0.08),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(context.tr('Save pay rules')),
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

class _GradePicker extends StatelessWidget {
  const _GradePicker({
    required this.scales,
    required this.config,
    required this.currentBasic,
    required this.onChanged,
  });

  final List<SalaryScale> scales;
  final SalaryConfig config;
  final double currentBasic;
  final ValueChanged<SalaryConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grade = scales.where((s) => s.code == config.gradeCode).firstOrNull;
    final step = config.salaryStep ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: grade?.code,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr('Grade')),
          items: [
            for (final s in scales)
              DropdownMenuItem(value: s.code, child: Text(s.name)),
          ],
          onChanged: (code) => onChanged(
            config.copyWith(
              gradeCode: code,
              salaryStep: config.salaryStep ?? 0,
            ),
          ),
        ),
        if (grade != null) ...[
          _Stepper(
            label: context.tr('Salary step (increments)'),
            value: step.toDouble(),
            step: 1,
            min: 0,
            max: grade.steps.toDouble(),
            onChanged: (v) => onChanged(config.copyWith(salaryStep: v.round())),
          ),
          Text(
            context.tr('Basic salary at this step: {amount}', {
              'amount': Fmt.lkr(grade.basicAt(step)),
            }),
            style: text.titleSmall,
          ),
          if (grade.basicAt(step) != currentBasic)
            Text(
              context.tr('Saving replaces your current basic of {amount}.', {
                'amount': Fmt.lkr(currentBasic),
              }),
              style: text.bodySmall,
            ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => PastelCard(
    elevated: true,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AppColors.lavenderDeep
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
    this.hint,
    this.suffix = '',
  });

  final String label;
  final String? hint;
  final double value;
  final double step;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hint != null) Text(hint!, style: text.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Decrease'),
            onPressed: value - step < min
                ? null
                : () => onChanged(value - step),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${Fmt.hours(value)}$suffix',
              textAlign: TextAlign.center,
              style: text.titleSmall,
            ),
          ),
          IconButton(
            tooltip: context.tr('Increase'),
            onPressed: value + step > max
                ? null
                : () => onChanged(value + step),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
