import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

/// App-bar bell that opens [NotificationsScreen] and shows the live unread
/// count once the server list has loaded (no count while loading or signed
/// out, rather than an invented number).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final icon = Icon(
      Icons.notifications_none_rounded,
      size: 20,
      color: color,
    );

    return IconButton(
      tooltip: 'Notifications',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () => context.push('/notifications'),
      icon: unread > 0
          ? Badge.count(
              count: unread,
              backgroundColor: TeritoryColors.primary,
              textColor: Colors.white,
              child: icon,
            )
          : icon,
    );
  }
}
