import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n/i18n.dart';
import '../../core/notices.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../guide/app_guide.dart';
import '../roster/roster_widgets.dart';

/// App version shown in About; keep in step with pubspec.yaml.
const appVersion = '1.0.0';

/// Device-level preferences: language, notifications, clock, and app info.
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AppSettingsScreen()));

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  PageHeader(title: context.tr('App Settings')),
                  const SizedBox(height: 20),
                  _Section(
                    icon: Icons.translate_rounded,
                    title: context.tr('Language'),
                    color: AppColors.lavender,
                    child: _LanguagePicker(settings: settings),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Section(
                    icon: Icons.notifications_active_outlined,
                    title: context.tr('Notifications'),
                    color: AppColors.sky,
                    child: _Notifications(settings: settings),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Section(
                    icon: Icons.schedule_rounded,
                    title: context.tr('Display'),
                    color: AppColors.mint,
                    child: _SwitchRow(
                      title: context.tr('24-hour clock'),
                      subtitle: context.tr('Times show as {example}', {
                        'example': Fmt.time(DateTime(2026, 1, 1, 19, 30)),
                      }),
                      value: settings.use24h,
                      onChanged: (v) {
                        settings.setUse24h(v);
                        // Screens that already loaded data redraw their times.
                        AppScope.of(context).sync.changed();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Section(
                    icon: Icons.info_outline_rounded,
                    title: context.tr('About'),
                    color: AppColors.surface,
                    child: const _About(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PastelCard(
      color: color,
      elevated: color == AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(title, style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final lang in AppLanguage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: settings.language == lang
                  ? AppColors.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => settings.setLanguage(lang),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang.nativeName, style: text.titleSmall),
                            if (lang != AppLanguage.english)
                              Text(lang.englishName, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (settings.language == lang)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.lavenderDeep,
                        )
                      else
                        Icon(
                          Icons.circle_outlined,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (settings.language != AppLanguage.english)
          Text(
            context.tr(
              'Notes and error messages from the server are shown in English.',
            ),
            style: text.bodySmall,
          ),
      ],
    );
  }
}

class _Notifications extends StatefulWidget {
  const _Notifications({required this.settings});

  final AppSettings settings;

  @override
  State<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<_Notifications> {
  bool? _reminders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).reminders.isEnabled().then((v) {
      if (mounted) setState(() => _reminders = v);
    });
  }

  Future<void> _toggleReminders(bool on) async {
    final scope = AppScope.of(context);
    if (!on) {
      await scope.reminders.disable();
      if (mounted) setState(() => _reminders = false);
      return;
    }
    final granted = await scope.reminders.enable();
    if (granted) {
      await scope.rescheduleReminders();
    } else if (mounted) {
      context.showMessage(
        context.tr(
          'Notifications are blocked for this app. Allow them in your phone settings.',
        ),
      );
    }
    if (mounted) setState(() => _reminders = granted);
  }

  /// Saves a setting, then re-plans the duty reminders with it.
  Future<void> _apply(Future<void> change) async {
    final scope = AppScope.of(context);
    await change;
    try {
      await scope.rescheduleReminders();
    } catch (_) {
      // Offline: applied at the next reschedule.
    }
  }

  Future<void> _setLead(int minutes) async {
    final scope = AppScope.of(context);
    await widget.settings.setReminderLead(minutes);
    try {
      await scope.rescheduleReminders();
    } catch (_) {
      // Offline: the new lead applies at the next reschedule.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = widget.settings;
    if (!scope.reminders.supported) {
      return Text(
        context.tr('Notifications are available in the Android and iOS app.'),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final on = _reminders ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SwitchRow(
          title: context.tr('Shift reminders'),
          subtitle: context.tr('A notification before each rostered shift'),
          value: on,
          onChanged: _reminders == null ? null : _toggleReminders,
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: on ? 1 : 0.45,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.tr('Remind me'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                for (final m in AppSettings.reminderLeadOptions)
                  ChoiceChip(
                    label: Text(
                      context.tr('{time} before', {
                        'time': leadText(Duration(minutes: m), context.tr),
                      }),
                    ),
                    selected: settings.reminderLeadMinutes == m,
                    onSelected: on ? (_) => _setLead(m) : null,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.ink,
                    labelStyle: TextStyle(
                      color: settings.reminderLeadMinutes == m
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        _SwitchRow(
          title: context.tr('OT switch alert'),
          subtitle: context.tr(
            'On D and 24 duties, tell me when the main shift ends and OT begins',
          ),
          value: settings.otAlerts,
          onChanged: (v) async {
            await settings.setOtAlerts(v);
            if (!v) await scope.reminders.cancelOtTransition();
          },
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          title: context.tr('Forgot to start'),
          subtitle: context.tr(
            'Remind me if a duty has started and I haven\'t tapped Start duty',
          ),
          value: settings.forgotStartAlert,
          onChanged: (v) => _apply(settings.setForgotStartAlert(v)),
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          title: context.tr('Before the main shift and OT end'),
          subtitle: context.tr('A reminder before each part of the duty ends'),
          value: settings.endReminders,
          onChanged: (v) => _apply(settings.setEndReminders(v)),
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          title: context.tr('Daily summary'),
          subtitle: context.tr(
            'After your last duty: hours, OT and what you earned that day',
          ),
          value: settings.daySummary,
          onChanged: (v) => settings.setDaySummary(v),
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          title: context.tr('Pay details reminder'),
          subtitle: context.tr(
            'If your salary or deductions are missing; at most once a week',
          ),
          value: settings.payDetailsReminder,
          onChanged: (v) => settings.setPayDetailsReminder(v),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => AppGuide.open(context),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: Text(context.tr('App guide')),
        ),
        const SizedBox(height: 8),
        row(context.tr('Version'), appVersion),
        row(
          context.tr('Server'),
          AppConfig.demoMode ? context.tr('Demo mode') : AppConfig.apiBaseUrl,
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'These settings are saved on this phone only. Your shifts and pay details are saved to your account.',
          ),
          style: text.bodySmall,
        ),
      ],
    );
  }
}
