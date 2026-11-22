import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/community_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../profile/presentation/friend_profile_screen.dart';
import '../../shared/presentation/invite_friends_sheet.dart';
import '../application/community_detail_provider.dart';

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(communityMembersLiveProvider(communityId));

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final communityName =
                      ref
                          .read(communityDetailProvider(communityId))
                          .valueOrNull
                          ?.name ??
                      'this community';
                  final invited = await InviteFriendsSheet.show(
                    context,
                    targetType: InviteTargetType.community,
                    targetId: communityId,
                    targetName: communityName,
                    excludeUserIds:
                        membersAsync.valueOrNull
                            ?.map((member) => member.userId)
                            .toSet() ??
                        const {},
                  );
                  if (invited == null || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        invited == 1
                            ? 'Invitation sent'
                            : '$invited invitations sent',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
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
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: TeritoryColors.communityIndigo,
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 40,
                        color: TeritoryColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        error is ApiException
                            ? error.message
                            : 'Could not load members.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(
                          communityMembersLiveProvider(communityId),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      'No members yet',
                      style: GoogleFonts.plusJakartaSans(
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final badgeColor = _roleBadgeColor(member.role);

                    return InkWell(
                      onTap: () => FriendProfileScreen.open(
                        context,
                        userId: member.userId,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            _MemberAvatar(member: member),
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
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final CommunityMember member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: TeritoryColors.communityIndigo.withValues(alpha: 0.15),
      backgroundImage: member.userAvatar.isEmpty
          ? null
          : NetworkImage(member.userAvatar),
      onBackgroundImageError: member.userAvatar.isEmpty ? null : (_, _) {},
      child: member.userAvatar.isEmpty
          ? Text(
              member.userName.isEmpty ? '?' : member.userName[0].toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.communityIndigo,
              ),
            )
          : null,
    );
  }
}
