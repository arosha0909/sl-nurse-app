import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/reminders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import 'sl_hospitals.dart';

/// Progressive profiling: optional details are asked for only when the nurse first uses
/// the feature that needs them, and every prompt can be skipped. None of these block the
/// action that triggered them; callers just `await` and carry on.
abstract final class ProgressivePrompts {
  /// Before "Scan roster" / "Add shift": ask for the primary hospital & ward, once.
  static Future<void> ensureWorkplace(BuildContext context) async {
    final scope = AppScope.of(context);
    final user = scope.auth.user;
    if (user == null || user.workplaceSetup != OnboardingState.pending) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const WorkplaceSheet(),
    );
  }

  /// On "Predict salary" / the Salary tab: ask for basic salary & OT rate, once.
  /// [force] reopens it from an "Estimate" chip even after the nurse skipped.
  static Future<void> ensureSalary(
    BuildContext context, {
    bool force = false,
  }) async {
    final scope = AppScope.of(context);
    final user = scope.auth.user;
    if (user == null) return;
    final ask = force
        ? user.salaryIsEstimate || user.salarySetup != OnboardingState.completed
        : user.salarySetup == OnboardingState.pending;
    if (!ask) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const SalarySetupDialog(),
    );
  }

  /// After the first successful check-in on this device: offer shift reminders, once.
  static Future<void> offerReminders(BuildContext context) async {
    final scope = AppScope.of(context);
    final reminders = scope.reminders;
    if (!reminders.supported ||
        await reminders.wasOffered() ||
        await reminders.isEnabled()) {
      return;
    }
    await reminders.markOffered();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => const RemindersSheet(),
    );
  }
}

/// Shared helper: PATCH /auth/me and propagate the new profile everywhere.
Future<void> _saveProfile(BuildContext context, Json changes) async {
  final scope = AppScope.of(context);
  final user = await scope.repository.updateProfile(changes);
  scope.auth.updateUser(user);
  scope.sync.changed();
}

/* ------------------------------------------------------------------ *
 * 1. Primary hospital / ward (2 quick steps)
 * ------------------------------------------------------------------ */
class WorkplaceSheet extends StatefulWidget {
  const WorkplaceSheet({super.key});

  @override
  State<WorkplaceSheet> createState() => _WorkplaceSheetState();
}

class _WorkplaceSheetState extends State<WorkplaceSheet> {
  final _search = TextEditingController();
  final _wardNo = TextEditingController();
  String? _hospital;
  String? _ward;
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    _wardNo.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final q = _search.text.trim().toLowerCase();
    final list = q.isEmpty
        ? slHospitals.take(6)
        : slHospitals.where((h) => h.toLowerCase().contains(q));
    return list.take(6).toList();
  }

  /// "Ward 07 · Medical · National Hospital of Sri Lanka, Colombo"
  String get _label => [
    if (_wardNo.text.trim().isNotEmpty) 'Ward ${_wardNo.text.trim()}',
    ?_ward,
    ?_hospital,
  ].join(' · ');

  Future<void> _finish({required bool skip}) async {
    setState(() => _saving = true);
    final ok = await context.runWithFeedback(
      () => _saveProfile(
        context,
        skip
            ? {
                'onboarding': {'workplace': 'skipped'},
              }
            : {'hospitalOrWard': _label},
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final step2 = _hospital != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _StepDot(active: !step2, done: step2, label: '1'),
                  const SizedBox(width: 6),
                  _StepDot(active: step2, done: false, label: '2'),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => _finish(skip: true),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step2 ? 'Which ward?' : 'Select your primary hospital',
                style: text.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                step2
                    ? 'Optional. Helps match your roster rows.'
                    : 'We use it to label your roster. You can change it any time.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (!step2) ...[
                TextField(
                  controller: _search,
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search hospitals',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (v.trim().length > 2) {
                      setState(
                        () => _hospital = _matches.firstOrNull ?? v.trim(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                for (final h in _matches)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppColors.lavenderDeep,
                    ),
                    title: Text(
                      h,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () => setState(() => _hospital = h),
                  ),
                if (_search.text.trim().length > 2 &&
                    !slHospitals.any(
                      (h) =>
                          h.toLowerCase() == _search.text.trim().toLowerCase(),
                    ))
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(
                      Icons.add_rounded,
                      color: AppColors.lavenderDeep,
                    ),
                    title: Text(
                      'Use "${_search.text.trim()}"',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () =>
                        setState(() => _hospital = _search.text.trim()),
                  ),
              ] else ...[
                PastelCard(
                  color: AppColors.lavender,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  onTap: () => setState(() => _hospital = null),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.lavenderDeep,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_hospital!, style: text.titleSmall)),
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final w in commonWards)
                      ChoiceChip(
                        label: Text(w),
                        selected: _ward == w,
                        onSelected: (on) =>
                            setState(() => _ward = on ? w : null),
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.ink,
                        labelStyle: TextStyle(
                          color: _ward == w
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _wardNo,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Ward number (optional)',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : () => _finish(skip: false),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save & continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.active,
    required this.done,
    required this.label,
  });

  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 34 : 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.ink
            : (done ? AppColors.mintDeep : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(12),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * 2. Basic salary & OT rate (with "Skip for now")
 * ------------------------------------------------------------------ */
class SalarySetupDialog extends StatefulWidget {
  const SalarySetupDialog({super.key});

  @override
  State<SalarySetupDialog> createState() => _SalarySetupDialogState();
}

class _SalarySetupDialogState extends State<SalarySetupDialog> {
  final _form = GlobalKey<FormState>();
  final _base = TextEditingController();
  final _ot = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _base.dispose();
    _ot.dispose();
    super.dispose();
  }

  Future<void> _save({required bool skip}) async {
    if (!skip && !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.runWithFeedback(
      () => _saveProfile(
        context,
        skip
            ? {
                'onboarding': {'salary': 'skipped'},
              }
            : {
                'baseSalary': double.parse(_base.text.trim()),
                if (_ot.text.trim().isNotEmpty)
                  'defaultOtHourlyRate': double.parse(_ot.text.trim()),
              },
      ),
      success: skip
          ? 'Using a typical salary estimate for now'
          : 'Salary saved. Predictions are now exact',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  static String? _amount(String? v, {bool optional = false}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return optional ? null : 'Enter your basic salary';
    final n = double.tryParse(s);
    if (n == null || n <= 0) return 'Enter an amount in LKR';
    if (n > 10000000) return 'That looks too high';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final numeric = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return Dialog(
      backgroundColor: AppColors.peach,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: IconBadge(
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.peachDeep,
                  size: 48,
                ),
              ),
              const SizedBox(height: 14),
              Text('Make your salary exact', style: text.titleLarge),
              const SizedBox(height: 6),
              Text(
                'To calculate your exact salary & OT predictions, please enter your Base Salary & Hourly OT Rate.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _base,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numeric,
                decoration: const InputDecoration(
                  labelText: 'Base salary (LKR / month)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: _amount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ot,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numeric,
                decoration: const InputDecoration(
                  labelText: 'OT rate (LKR / hour)',
                  prefixIcon: Icon(Icons.more_time_rounded),
                  helperText: 'Optional. Leave empty to use basic ÷ 240 × 1.5',
                ),
                validator: (v) => _amount(v, optional: true),
                onFieldSubmitted: (_) => _save(skip: false),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : () => _save(skip: false),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save & predict'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _saving ? null : () => _save(skip: true),
                child: const Text('Skip for now (Use Default Estimate)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * 3. Shift reminders (one tap)
 * ------------------------------------------------------------------ */
class RemindersSheet extends StatefulWidget {
  const RemindersSheet({super.key});

  @override
  State<RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<RemindersSheet> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    final scope = AppScope.of(context);
    final granted = await scope.reminders.enable();
    if (granted) await scope.rescheduleReminders();
    if (!mounted) return;
    Navigator.pop(context);
    context.showMessage(
      granted
          ? 'Reminders on: we\'ll nudge you ${reminderLeadText()} before each shift'
          : 'Notifications are blocked. You can turn them on later in Profile.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: IconBadge(
                icon: Icons.notifications_active_rounded,
                color: AppColors.sky,
                iconColor: AppColors.skyDeep,
                size: 60,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Never miss a shift',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Nice, you\'re checked in! Want a reminder ${reminderLeadText()} before each upcoming shift?',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _enable,
              icon: const Icon(Icons.notifications_rounded, size: 18),
              label: const Text('Turn on reminders'),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

String reminderLeadText() =>
    reminderLead.inMinutes % 60 == 0 && reminderLead.inHours == 1
    ? '1 hour'
    : '${reminderLead.inMinutes} minutes';

/// Small "Estimate" pill shown on salary figures until the nurse enters her own salary.
class EstimateChip extends StatelessWidget {
  const EstimateChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.peach,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 14,
                color: AppColors.peachDeep,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Estimate · add your salary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
