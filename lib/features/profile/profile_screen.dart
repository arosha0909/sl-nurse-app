import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import '../../data/models.dart';

class _ProfileData {
  const _ProfileData(this.user, this.config);

  final UserProfile user;
  final SalaryConfig config;
}

/// Personal details, pay settings, allowances/deductions and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ResponsiveContent(
        child: AsyncView<_ProfileData>(
          skeleton: const SkeletonList(heights: [150, 200, 180, 180]),
          load: () async {
            final r = await Future.wait<Object>([
              scope.repository.me(),
              scope.repository.salaryConfig(),
            ]);
            return _ProfileData(r[0] as UserProfile, r[1] as SalaryConfig);
          },
          builder: (context, data, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                16,
                AppSpacing.screenPadding,
                AppSpacing.dockClearance,
              ),
              children: [
                Text('Profile & Settings', style: text.headlineSmall),
                const SizedBox(height: 18),
                _Identity(user: data.user),
                const SizedBox(height: AppSpacing.gap),
                _PaySettings(user: data.user, config: data.config),
                const SizedBox(height: AppSpacing.gap),
                _AmountList(
                  title: 'Monthly allowances',
                  hint: 'COLA, interim, uniform…',
                  color: AppColors.mint,
                  accent: AppColors.mintDeep,
                  items: data.config.allowances,
                  onSave: (items) => _saveConfig(
                    context,
                    data.config.copyWith(allowances: items),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap),
                _AmountList(
                  title: 'Monthly deductions',
                  hint: 'W&OP, union fee, loan…',
                  color: AppColors.peach,
                  accent: AppColors.peachDeep,
                  items: data.config.deductions,
                  onSave: (items) => _saveConfig(
                    context,
                    data.config.copyWith(deductions: items),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap),
                const _RemindersCard(),
                const SizedBox(height: AppSpacing.sectionGap),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConfig.demoMode
                      ? 'Demo mode · sample data'
                      : 'Connected to ${AppConfig.apiBaseUrl}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _saveConfig(
    BuildContext context,
    SalaryConfig config,
  ) async {
    final scope = AppScope.of(context);
    final ok = await context.runWithFeedback(
      () => scope.repository.updateSalaryConfig(config),
      success: 'Salary settings saved',
    );
    if (ok) scope.sync.changed();
  }

  static Future<void> _confirmSignOut(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You\'ll need your email and password to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await AppScope.of(context).auth.logout();
    }
  }
}

/* ------------------------------------------------------------------ *
 * Editing helpers
 * ------------------------------------------------------------------ */

/// Updates profile fields via PATCH /auth/me and refreshes everything that depends on them.
Future<void> _updateProfile(
  BuildContext context,
  Json changes,
  String success,
) async {
  final scope = AppScope.of(context);
  await context.runWithFeedback(() async {
    final user = await scope.repository.updateProfile(changes);
    scope.auth.updateUser(user);
    scope.sync.changed();
  }, success: success);
}

Future<String?> _editText(
  BuildContext context, {
  required String title,
  required String initial,
  TextInputType keyboard = TextInputType.text,
  String? Function(String)? validate,
  String? helper,
}) => TextPromptDialog.show(
  context,
  TextPromptDialog(
    title: title,
    initial: initial,
    keyboard: keyboard,
    numeric: keyboard == TextInputType.number,
    validate: validate,
    helper: helper,
  ),
);

String? _validMoney(String v) {
  final n = double.tryParse(v);
  if (n == null) return 'Enter an amount';
  if (n < 0 || n > 100000000) return 'Enter a realistic amount';
  return null;
}

/* ------------------------------------------------------------------ *
 * Sections
 * ------------------------------------------------------------------ */
class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: AppColors.lavender,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(name: user.fullName, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.contact,
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: user.fullName,
            onTap: () async {
              final v = await _editText(
                context,
                title: 'Full name',
                initial: user.fullName,
                validate: (v) => v.length < 2 ? 'Enter your name' : null,
              );
              if (v != null && context.mounted) {
                await _updateProfile(context, {'fullName': v}, 'Name updated');
              }
            },
          ),
          _SettingRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone,
            onTap: () async {
              final v = await _editText(
                context,
                title: 'Phone',
                initial: user.phone,
                keyboard: TextInputType.phone,
                validate: (v) =>
                    RegExp(
                      r'^(?:\+94|94|0)\d{9}$',
                    ).hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''))
                    ? null
                    : 'Enter a Sri Lankan number, e.g. 077 123 4567',
              );
              if (v != null && context.mounted) {
                await _updateProfile(context, {'phone': v}, 'Phone updated');
              }
            },
          ),
          _SettingRow(
            icon: Icons.local_hospital_outlined,
            label: 'Hospital / ward',
            value: user.hospitalOrWard.isEmpty ? 'Add' : user.hospitalOrWard,
            onTap: () async {
              final v = await _editText(
                context,
                title: 'Hospital / ward',
                initial: user.hospitalOrWard,
              );
              if (v != null && context.mounted) {
                await _updateProfile(context, {
                  'hospitalOrWard': v,
                }, 'Ward updated');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PaySettings extends StatelessWidget {
  const _PaySettings({required this.user, required this.config});

  final UserProfile user;
  final SalaryConfig config;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final derivedRate = user.baseSalary / 240 * config.otRateMultiplier;

    Future<void> editMoney(
      String field,
      String title,
      double current, {
      String? helper,
    }) async {
      final v = await _editText(
        context,
        title: title,
        initial: current == 0 ? '' : Fmt.hours(current),
        keyboard: TextInputType.number,
        validate: _validMoney,
        helper: helper,
      );
      if (v != null && context.mounted) {
        await _updateProfile(context, {
          field: double.parse(v),
        }, '$title updated');
      }
    }

    return PastelCard(
      elevated: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay settings', style: text.titleMedium),
          if (user.salaryIsEstimate)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Using a typical salary estimate until you add your basic salary.',
                style: text.bodySmall?.copyWith(color: AppColors.peachDeep),
              ),
            ),
          const SizedBox(height: 6),
          _SettingRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Basic salary',
            value: Fmt.lkr(user.baseSalary),
            onTap: () =>
                editMoney('baseSalary', 'Basic salary', user.baseSalary),
          ),
          _SettingRow(
            icon: Icons.nightlight_outlined,
            label: 'Night allowance / shift',
            value: Fmt.lkr(user.defaultNightAllowance),
            onTap: () => editMoney(
              'defaultNightAllowance',
              'Night allowance',
              user.defaultNightAllowance,
            ),
          ),
          _SettingRow(
            icon: Icons.more_time_rounded,
            label: 'OT hourly rate',
            value: user.defaultOtHourlyRate > 0
                ? Fmt.lkr(user.defaultOtHourlyRate)
                : 'Auto · ${Fmt.lkr(derivedRate)}',
            onTap: () => editMoney(
              'defaultOtHourlyRate',
              'OT hourly rate',
              user.defaultOtHourlyRate,
              helper: 'Leave 0 to use basic ÷ 240 × multiplier',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 4),
              const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OT multiplier',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Lower multiplier',
                onPressed: config.otRateMultiplier <= 1
                    ? null
                    : () => ProfileScreen._saveConfig(
                        context,
                        config.copyWith(
                          otRateMultiplier: config.otRateMultiplier - 0.25,
                        ),
                      ),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text('${config.otRateMultiplier}×', style: text.titleSmall),
              IconButton(
                tooltip: 'Raise multiplier',
                onPressed: config.otRateMultiplier >= 3
                    ? null
                    : () => ProfileScreen._saveConfig(
                        context,
                        config.copyWith(
                          otRateMultiplier: config.otRateMultiplier + 0.25,
                        ),
                      ),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Editable list of named monthly amounts (allowances or deductions).
class _AmountList extends StatelessWidget {
  const _AmountList({
    required this.title,
    required this.hint,
    required this.color,
    required this.accent,
    required this.items,
    required this.onSave,
  });

  final String title;
  final String hint;
  final Color color;
  final Color accent;
  final List<NamedAmount> items;
  final Future<void> Function(List<NamedAmount>) onSave;

  Future<void> _edit(BuildContext context, {int? index}) async {
    final existing = index == null ? null : items[index];
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => _AmountDialog(existing: existing, hint: hint),
    );

    if (result == null) return;
    final next = [...items];
    if (result == 'delete') {
      next.removeAt(index!);
    } else if (index == null) {
      next.add(result as NamedAmount);
    } else {
      next[index] = result as NamedAmount;
    }
    await onSave(next);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = items.fold(0.0, (sum, i) => sum + i.amount);
    return PastelCard(
      color: color,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: text.titleMedium)),
              Text(Fmt.lkr(total), style: text.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty) Text('None yet', style: text.bodySmall),
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => _edit(context, index: i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].name,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      Fmt.thousands(items[i].amount),
                      style: text.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Add / edit / delete one named amount. Returns a [NamedAmount], 'delete', or null.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.existing, required this.hint});

  final NamedAmount? existing;
  final String hint;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : Fmt.hours(widget.existing!.amount),
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: Text(existing == null ? 'Add item' : 'Edit item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: existing == null,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: widget.hint,
                fillColor: AppColors.surface,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly amount (LKR)',
                fillColor: AppColors.surface,
              ),
              validator: (v) => _validMoney((v ?? '').trim()),
            ),
          ],
        ),
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                NamedAmount(
                  _name.text.trim(),
                  double.parse(_amount.text.trim()),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Shift reminders on/off (local notifications on this device).
class _RemindersCard extends StatefulWidget {
  const _RemindersCard();

  @override
  State<_RemindersCard> createState() => _RemindersCardState();
}

class _RemindersCardState extends State<_RemindersCard> {
  bool? _enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).reminders.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(bool on) async {
    final scope = AppScope.of(context);
    if (on) {
      final granted = await scope.reminders.enable();
      if (granted) {
        final now = scope.today();
        await scope.reminders.schedule(
          await scope.repository.shifts(
            from: now,
            to: now.add(const Duration(days: 14)),
          ),
          now: now,
        );
      } else if (mounted) {
        context.showMessage(
          'Notifications are blocked for this app. Allow them in your phone settings.',
        );
      }
      if (mounted) setState(() => _enabled = granted);
    } else {
      await scope.reminders.disable();
      if (mounted) setState(() => _enabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = AppScope.of(context).reminders;
    if (!reminders.supported) return const SizedBox.shrink();
    return PastelCard(
      color: AppColors.sky,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SwitchListTile(
        value: _enabled ?? false,
        onChanged: _enabled == null ? null : _toggle,
        secondary: const Icon(
          Icons.notifications_active_outlined,
          color: AppColors.skyDeep,
        ),
        title: const Text('Shift reminders'),
        subtitle: const Text(
          'A notification 1 hour before each rostered shift',
        ),
      ),
    );
  }
}
