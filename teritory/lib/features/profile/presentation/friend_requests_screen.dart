import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRelationships = MockDataService.instance.friendRelationships;

    // Incoming: where friendId == 'u1' and status pending
    final incoming = allRelationships
        .where((f) => f.friendId == 'u1' && f.status == FriendStatus.pending)
        .toList();

    // Sent: where userId == 'u1' and status pending
    final sent = allRelationships
        .where((f) => f.userId == 'u1' && f.status == FriendStatus.pending)
        .toList();

    // Also watch the provider to stay reactive
    ref.watch(friendRequestsProvider);

    final hasContent = incoming.isNotEmpty || sent.isNotEmpty;

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
      body: !hasContent
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
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
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Incoming Requests ──
                  if (incoming.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Incoming Requests', Icons.call_received_rounded),
                    const SizedBox(height: 10),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: incoming.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = incoming[index];
                        final sender =
                            MockDataService.instance.userById(request.userId);
                        return _IncomingRequestCard(
                          name: sender?.displayName ?? 'Unknown',
                          handle: sender?.handle ?? '',
                          avatarUrl: sender?.avatarUrl ?? '',
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Sent Requests ──
                  if (sent.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Sent Requests', Icons.call_made_rounded),
                    const SizedBox(height: 10),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: sent.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = sent[index];
                        final receiver = MockDataService.instance
                            .userById(request.friendId);
                        return _SentRequestCard(
                          name: receiver?.displayName ?? 'Unknown',
                          handle: receiver?.handle ?? '',
                          avatarUrl: receiver?.avatarUrl ?? '',
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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

class _IncomingRequestCard extends StatelessWidget {
  final String name;
  final String handle;
  final String avatarUrl;

  const _IncomingRequestCard({
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
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
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: TeritoryColors.surfaceContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                Text(
                  handle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '2 mutual friends',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: TeritoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request accepted!')),
              );
            },
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request declined')),
              );
            },
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
        ],
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  final String name;
  final String handle;
  final String avatarUrl;

  const _SentRequestCard({
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
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
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: TeritoryColors.surfaceContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                Text(
                  handle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TeritoryColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pending',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TeritoryColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request cancelled')),
              );
            },
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
