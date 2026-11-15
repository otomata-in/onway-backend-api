import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/community_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  final String _currentUserId = 'u1';

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  IconData _activityIcon(CommunityActivityType type) {
    switch (type) {
      case CommunityActivityType.flagDrop:
        return Icons.flag_rounded;
      case CommunityActivityType.tripComplete:
        return Icons.route_rounded;
      case CommunityActivityType.announcement:
        return Icons.campaign_rounded;
      case CommunityActivityType.memberJoin:
        return Icons.person_add_rounded;
    }
  }

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

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final community = ref.watch(communityByIdProvider(widget.communityId));
    if (community == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Community not found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            community.name,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            labelColor: TeritoryColors.communityIndigo,
            unselectedLabelColor: TeritoryColors.textSecondary,
            indicatorColor: TeritoryColors.communityIndigo,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Trip Plans'),
              Tab(text: 'Members'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildHeader(community),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFeedTab(),
                  _buildTripPlansTab(),
                  _buildMembersTab(),
                  _buildChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(Community community) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: TeritoryColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  community.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TeritoryColors.communityIndigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  community.parentClanName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            community.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: TeritoryColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_rounded,
                  size: 16, color: TeritoryColors.communityIndigo),
              const SizedBox(width: 4),
              Text(
                '${community.memberCount} members',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Feed Tab ───────────────────────────────────────────────────────

  Widget _buildFeedTab() {
    final activities =
        ref.watch(communityActivitiesProvider(widget.communityId));
    if (activities.isEmpty) {
      return Center(
        child: Text(
          'No activity yet',
          style: GoogleFonts.plusJakartaSans(color: TeritoryColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TeritoryColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TeritoryColors.communityIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _activityIcon(activity.type),
                  size: 20,
                  color: TeritoryColors.communityIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage:
                              NetworkImage(activity.userAvatar),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity.userName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(activity.createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Trip Plans Tab ─────────────────────────────────────────────────

  Widget _buildTripPlansTab() {
    final plans = ref.watch(tripPlansByCommunityProvider(widget.communityId));
    if (plans.isEmpty) {
      return Center(
        child: Text(
          'No trip plans yet',
          style: GoogleFonts.plusJakartaSans(color: TeritoryColors.textMuted),
        ),
      );
    }

    final highestScore =
        plans.map((p) => p.voteScore).reduce((a, b) => a > b ? a : b);

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isWinning = plan.voteScore == highestScore;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWinning
                      ? TeritoryColors.majorGold.withValues(alpha: 0.6)
                      : TeritoryColors.border,
                  width: isWinning ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isWinning) ...[
                        const Icon(Icons.emoji_events_rounded,
                            size: 20, color: TeritoryColors.majorGold),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          plan.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 14, color: TeritoryColors.communityIndigo),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${plan.originName} → ${plan.destinationName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.waypoints.length} waypoints • by ${plan.createdByName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.thumb_up_outlined, size: 18),
                        color: TeritoryColors.communityIndigo,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${plan.voteScore}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.thumb_down_outlined, size: 18),
                        color: TeritoryColors.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
            backgroundColor: TeritoryColors.communityIndigo,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Create Trip Plan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Members Tab ────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    final members =
        ref.watch(communityMembersProvider(widget.communityId));

    return Column(
      children: [
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
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(member.userAvatar),
                ),
                title: Text(
                  member.userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleBadgeColor(member.role).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _roleLabel(member.role),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _roleBadgeColor(member.role),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Chat Tab ───────────────────────────────────────────────────────

  Widget _buildChatTab() {
    final messages =
        ref.watch(communityMessagesProvider(widget.communityId));

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isSelf = msg.userId == _currentUserId;
              return _buildChatBubble(msg, isSelf);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: TeritoryColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: TeritoryColors.textMuted,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: TeritoryColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: TeritoryColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: TeritoryColors.communityIndigo, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_chatController.text.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent!')),
                      );
                      _chatController.clear();
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  color: TeritoryColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(CommunityMessage msg, bool isSelf) {
    return Row(
      mainAxisAlignment:
          isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSelf) ...[
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(msg.userAvatar),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelf
                  ? TeritoryColors.chatBubbleSelf
                  : TeritoryColors.chatBubbleOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSelf ? 16 : 4),
                bottomRight: Radius.circular(isSelf ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSelf)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      msg.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.communityIndigo,
                      ),
                    ),
                  ),
                Text(
                  msg.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isSelf ? Colors.white : TeritoryColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(msg.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isSelf
                        ? Colors.white.withValues(alpha: 0.6)
                        : TeritoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
