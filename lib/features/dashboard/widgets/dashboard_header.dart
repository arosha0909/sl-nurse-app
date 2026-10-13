import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    required this.onMenu,
    required this.onAvatar,
    this.isNewUser = false,
  });

  final UserProfile user;
  final VoidCallback onMenu;
  final VoidCallback onAvatar;

  /// Just signed up: a warmer first-run greeting.
  final bool isNewUser;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onMenu,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppColors.textPrimary,
                    semanticLabel: 'Menu',
                  ),
                ),
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Profile',
              child: GestureDetector(
                onTap: onAvatar,
                child: UserAvatar(name: user.fullName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          isNewUser
              ? 'Welcome, Nurse ${user.firstName}!'
              : 'Hello Nurse ${user.firstName},',
          style: text.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          isNewUser
              ? "Let's simplify your duty life."
              : 'Have a nice shift today! 🩺',
          style: text.bodyLarge?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
