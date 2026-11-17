import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';

/// Live inbox backed by `GET /notifications`, with `PATCH /:id/read`,
/// `PATCH /read-all` and tap-through to the route the server sends in
/// `actionUrl`.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsNotifierProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllRead(context, ref),
              child: Text(
                'Mark all read',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeritoryColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.primary),
        ),
        error: (error, _) => _InboxError(
          message: error is ApiException
              ? error.message
              : 'Could not load notifications. Check the API and retry.',
          onRetry: () => ref.invalidate(notificationsNotifierProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyInbox();
          return RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: () =>
                ref.read(notificationsNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationTile(
                  item: item,
                  onTap: () => _open(context, ref, item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationsNotifierProvider.notifier).markAllRead();
      messenger.showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!item.isRead) {
      try {
        await ref.read(notificationsNotifierProvider.notifier).markRead(item.id);
      } on ApiException {
        // Opening the target still makes sense; the badge just stays unread.
      }
    }
    if (!context.mounted) return;

    final route = item.actionUrl ?? item.targetId;
    if (route == null || route.isEmpty || route == '/notifications') return;

    const knownPrefixes = ['/clans/', '/trips/', '/profile/'];
    if (knownPrefixes.any(route.startsWith)) {
      context.go(route);
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('This notification points to a screen the app has not '
            'built yet.'),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(item.type);
    return Material(
      color: item.isRead ? Colors.white : TeritoryColors.primaryLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(item.type), size: 19, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: TeritoryColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.35,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(item.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.tripInvite:
      case NotificationType.tripStarted:
      case NotificationType.tripCompleted:
        return Icons.route_rounded;
      case NotificationType.rallyAlert:
      case NotificationType.rallyStarted:
        return Icons.local_fire_department_rounded;
      case NotificationType.waypointValidated:
        return Icons.pin_drop_rounded;
      case NotificationType.clanInvite:
        return Icons.groups_rounded;
      case NotificationType.communityInvite:
        return Icons.forum_rounded;
      case NotificationType.leaderboardChange:
        return Icons.leaderboard_rounded;
      case NotificationType.tripVoteResult:
        return Icons.how_to_vote_rounded;
      case NotificationType.flagNearby:
        return Icons.flag_rounded;
      case NotificationType.achievement:
        return Icons.military_tech_rounded;
      case NotificationType.kudos:
        return Icons.favorite_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  static Color _accentFor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
      case NotificationType.clanInvite:
        return TeritoryColors.sapphireBlue;
      case NotificationType.rallyAlert:
      case NotificationType.rallyStarted:
      case NotificationType.achievement:
        return TeritoryColors.majorGold;
      case NotificationType.tripInvite:
      case NotificationType.tripStarted:
      case NotificationType.tripCompleted:
      case NotificationType.waypointValidated:
        return TeritoryColors.emeraldGreen;
      case NotificationType.kudos:
        return TeritoryColors.primary;
      default:
        return TeritoryColors.textMuted;
    }
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 44, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              "You're all caught up",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Clan joins, invitations, trip starts and rally sign-ups land here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color: TeritoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: TeritoryColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
