import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/profile_providers.dart';

/// Live friend requests: `GET /users/friends/requests` for both directions,
/// `POST …/:id/respond` to accept/decline and `DELETE …/:id` to cancel a sent
/// request.
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  final Set<String> _pendingActionIds = {};

  Future<void> _respond(ApiFriendRequest request, bool accept) async {
    setState(() => _pendingActionIds.add(request.relationshipId));
    try {
      await TeritoryRepository.instance.respondToFriendRequest(
        request.relationshipId,
        accept: accept,
      );
      ref.invalidate(friendRequestsLiveProvider);
      ref.invalidate(friendsLiveProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'You are now friends with ${request.user.displayName}'
                : 'Declined ${request.user.displayName}',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingActionIds.remove(request.relationshipId));
      }
    }
  }

  Future<void> _cancel(ApiFriendRequest request) async {
    setState(() => _pendingActionIds.add(request.relationshipId));
    try {
      await TeritoryRepository.instance
          .cancelFriendRequest(request.relationshipId);
      ref.invalidate(friendRequestsLiveProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancelled request to ${request.user.displayName}'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingActionIds.remove(request.relationshipId));
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(friendRequestsLiveProvider);
    try {
      await ref.read(friendRequestsLiveProvider.future);
    } on ApiException {
      // The error state renders the message.
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsLiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: TeritoryColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  error is ApiException
                      ? error.message
                      : 'Could not load friend requests.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => ref.invalidate(friendRequestsLiveProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (snapshot) {
          if (snapshot.total == 0) {
            return RefreshIndicator(
              color: TeritoryColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 64, color: TeritoryColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No pending requests',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requests you send or receive appear here.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: TeritoryColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (snapshot.incoming.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Incoming Requests', icon: Icons.call_received_rounded),
                  const SizedBox(height: 10),
                  for (final request in snapshot.incoming) ...[
                    _RequestCard(
                      request: request,
                      isBusy:
                          _pendingActionIds.contains(request.relationshipId),
                      isIncoming: true,
                      onAccept: () => _respond(request, true),
                      onDecline: () => _respond(request, false),
                      onCancel: null,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                ],
                if (snapshot.outgoing.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Sent Requests', icon: Icons.call_made_rounded),
                  const SizedBox(height: 10),
                  for (final request in snapshot.outgoing) ...[
                    _RequestCard(
                      request: request,
                      isBusy:
                          _pendingActionIds.contains(request.relationshipId),
                      isIncoming: false,
                      onAccept: null,
                      onDecline: null,
                      onCancel: () => _cancel(request),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: TeritoryColors.textPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: TeritoryColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isBusy,
    required this.isIncoming,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final ApiFriendRequest request;
  final bool isBusy;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final user = request.user;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile/friends/${user.id}'),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: TeritoryColors.surfaceContainer,
              backgroundImage:
                  user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person_rounded,
                      color: TeritoryColors.textMuted)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                Text(
                  '@${user.handle}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${user.totalFlags} flags • ${user.state.isNotEmpty ? user.state : user.country}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: TeritoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isIncoming) ...[
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeritoryColors.validatedGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Accept',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: TeritoryColors.expiredRed,
                side: const BorderSide(color: TeritoryColors.expiredRed),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                side: const BorderSide(color: TeritoryColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
