import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models.dart';
import '../../../core/i18n/i18n.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    required this.onMenu,
    this.onNotifications,
    required this.onAvatar,
    this.isNewUser = false,
  });

  final UserProfile user;
  final VoidCallback onMenu;

  /// Opens the notifications list (bell with an unread count).
  final VoidCallback? onNotifications;
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
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppColors.textPrimary,
                    semanticLabel: context.tr('Menu'),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (onNotifications != null) ...[
              NotificationBell(onTap: onNotifications!),
              const SizedBox(width: 10),
            ],
            Semantics(
              button: true,
              label: context.tr('Profile'),
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
              ? context.tr('Welcome, Nurse {name}!', {'name': user.firstName})
              : context.tr('Hello Nurse {name},', {'name': user.firstName}),
          style: text.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          isNewUser
              ? context.tr("Let's simplify your duty life.")
              : context.tr('Have a nice shift today! 🩺'),
          style: text.bodyLarge?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// Bell with the number of unread notifications.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.inbox,
      builder: (context, _) {
        final unread = scope.inbox.unread(scope.today());
        return Tooltip(
          message: context.tr('Notifications'),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.square(
                dimension: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.peachDeep,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
