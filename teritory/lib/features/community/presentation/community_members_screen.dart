import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/community_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class CommunityMembersScreen extends ConsumerWidget {
  final String communityId;

  const CommunityMembersScreen({super.key, required this.communityId});

  Color _roleBadgeColor(CommunityRole role) {
    switch (role) {
      case CommunityRole.creator:
        return TeritoryColors.majorGold;
      case CommunityRole.moderator:
        return TeritoryColors.clanPurple;
      case CommunityRole.member:
        return TeritoryColors.textSecondary;
    }
  }

  String _roleLabel(CommunityRole role) {
    switch (role) {
      case CommunityRole.creator:
        return 'Creator';
      case CommunityRole.moderator:
        return 'Moderator';
      case CommunityRole.member:
        return 'Member';
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(communityMembersProvider(communityId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Members',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Invite Button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied!')),
                  );
                },
                icon:
                    const Icon(Icons.person_add_rounded, color: Colors.white),
                label: Text(
                  'Invite Friends',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeritoryColors.communityIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // ── Members List ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                final badgeColor = _roleBadgeColor(member.role);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            NetworkImage(member.userAvatar),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.userName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TeritoryColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Joined ${_formatDate(member.joinedAt)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: TeritoryColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _roleLabel(member.role),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
