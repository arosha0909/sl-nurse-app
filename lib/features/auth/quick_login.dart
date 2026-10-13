import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme/app_colors.dart';

/// A seeded test account (sl-nurse-api: `npm run seed:demo`).
class QuickLoginAccount {
  const QuickLoginAccount({
    required this.key,
    required this.name,
    required this.scenario,
    required this.icon,
    required this.color,
  });

  final String key;
  final String name;

  /// What this account is set up to test.
  final String scenario;
  final IconData icon;
  final Color color;

  String get email => '$key@demo.slnurse.lk';
}

/// One-tap test logins, shown only where [AppConfig.quickLogin] allows it.
abstract final class QuickLogin {
  /// Shared password of the seeded demo accounts.
  static const password = 'DemoNurse2026';

  /// Must match QUICK_LOGIN_ACCOUNTS in sl-nurse-api/src/scripts/seed.ts.
  static const accounts = [
    QuickLoginAccount(
      key: 'nimali',
      name: 'Nimali',
      scenario: '7 · 1 · N rota with OT',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.peach,
    ),
    QuickLoginAccount(
      key: 'kasun',
      name: 'Kasun',
      scenario: 'On a 24 h duty now',
      icon: Icons.schedule_rounded,
      color: AppColors.sky,
    ),
    QuickLoginAccount(
      key: 'dilini',
      name: 'Dilini',
      scenario: 'D duties (12 h)',
      icon: Icons.light_mode_rounded,
      color: AppColors.lavender,
    ),
    QuickLoginAccount(
      key: 'sachini',
      name: 'Sachini',
      scenario: 'Night tonight + leave',
      icon: Icons.nightlight_round,
      color: AppColors.mint,
    ),
    QuickLoginAccount(
      key: 'newnurse',
      name: 'New nurse',
      scenario: 'Empty account',
      icon: Icons.person_add_alt_1_rounded,
      color: AppColors.surfaceMuted,
    ),
  ];
}

/// Horizontal strip of test accounts; a tap signs in immediately.
class QuickLoginStrip extends StatelessWidget {
  const QuickLoginStrip({super.key, required this.onPick, required this.busy});

  final ValueChanged<QuickLoginAccount> onPick;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: AppColors.peachDeep,
            ),
            const SizedBox(width: 4),
            Text('Quick test login', style: text.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppConfig.demoMode ? 'DEMO' : 'LOCAL',
                style: text.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QuickLogin.accounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = QuickLogin.accounts[i];
              return _AccountCard(
                account: a,
                onTap: busy ? null : () => onPick(a),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onTap});

  final QuickLoginAccount account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Sign in as ${account.name}, ${account.scenario}',
      excludeSemantics: true,
      child: Material(
        color: account.color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 128,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(account.icon, size: 18, color: AppColors.ink),
                  ),
                  const Spacer(),
                  Text(
                    account.name,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    account.scenario,
                    style: text.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
