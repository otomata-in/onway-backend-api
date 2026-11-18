import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/community_models.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../shared/presentation/invite_friends_sheet.dart';
import '../../trips/presentation/trip_planner_screen.dart';
import '../application/community_detail_provider.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  final Set<String> _pendingVotes = {};

  bool _membershipPending = false;
  bool _sendingMessage = false;

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

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  String _errorMessage(Object error) => error is ApiException
      ? error.message
      : 'Teritory is unreachable. Check the API and retry.';

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

  // ─── Actions ────────────────────────────────────────────────────────

  Future<void> _toggleMembership({required bool isMember}) async {
    if (_membershipPending) return;

    if (isMember) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave this community?'),
          content: const Text('You will stop seeing its feed and chat.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Leave',
                style: TextStyle(color: TeritoryColors.expiredRed),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _membershipPending = true);
    try {
      final repository = TeritoryRepository.instance;
      if (isMember) {
        await repository.leaveCommunity(widget.communityId);
      } else {
        await repository.joinCommunity(widget.communityId);
      }
      if (!mounted) return;
      ref.invalidate(communityDetailProvider(widget.communityId));
      ref.invalidate(communityMembersLiveProvider(widget.communityId));
      _toast(isMember ? 'Left the community' : 'Joined the community');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not reach Teritory. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _membershipPending = false);
    }
  }

  Future<void> _toggleVote(String planId) async {
    if (_pendingVotes.contains(planId)) return;
    setState(() => _pendingVotes.add(planId));
    try {
      final voted = await TeritoryRepository.instance.toggleTripPlanVote(
        planId,
      );
      if (!mounted) return;
      ref.invalidate(communityPlansProvider(widget.communityId));
      _toast(voted ? 'Vote added' : 'Vote removed');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not save your vote. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _pendingVotes.remove(planId));
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _sendingMessage) return;

    setState(() => _sendingMessage = true);
    try {
      await ref
          .read(communityMessagesProvider(widget.communityId).notifier)
          .sendMessage(text);
      if (!mounted) return;
      _chatController.clear();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast(
        'Could not send your message. Check your connection.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _openInviteSheet(String communityName) async {
    final members =
        ref
            .read(communityMembersLiveProvider(widget.communityId))
            .valueOrNull ??
        const <CommunityMember>[];
    final invited = await InviteFriendsSheet.show(
      context,
      targetType: InviteTargetType.community,
      targetId: widget.communityId,
      targetName: communityName,
      excludeUserIds: members.map((member) => member.userId).toSet(),
    );
    if (!mounted || invited == null) return;
    _toast(invited == 1 ? 'Invitation sent' : '$invited invitations sent');
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final communityAsync = ref.watch(
      communityDetailProvider(widget.communityId),
    );
    final community = communityAsync.valueOrNull;

    if (community == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: communityAsync.hasError
              ? _TabError(
                  message: _errorMessage(communityAsync.error!),
                  onRetry: () => ref.invalidate(
                    communityDetailProvider(widget.communityId),
                  ),
                )
              : const CircularProgressIndicator(
                  color: TeritoryColors.communityIndigo,
                ),
        ),
      );
    }

    final membersAsync = ref.watch(
      communityMembersLiveProvider(widget.communityId),
    );
    final members = membersAsync.valueOrNull;
    final currentUserId = ref.watch(currentUserProvider).id;
    final isMember =
        members?.any((member) => member.userId == currentUserId) ?? false;
    final membershipLabel = members != null
        ? (isMember ? 'Leave' : 'Join')
        : (membersAsync.isLoading ? 'Checking…' : 'Unavailable');

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
            _buildHeader(
              community,
              isMember: isMember,
              membershipLabel: membershipLabel,
              canToggle: members != null,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFeedTab(),
                  _buildTripPlansTab(),
                  _buildMembersTab(community),
                  _buildChatTab(currentUserId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(
    Community community, {
    required bool isMember,
    required String membershipLabel,
    required bool canToggle,
  }) {
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
              if (community.parentClanName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
          if (community.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              community.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.people_rounded,
                size: 16,
                color: TeritoryColors.communityIndigo,
              ),
              const SizedBox(width: 4),
              Text(
                '${community.memberCount} members',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: !canToggle || _membershipPending
                      ? null
                      : () => _toggleMembership(isMember: isMember),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isMember
                        ? TeritoryColors.textPrimary
                        : TeritoryColors.communityIndigo,
                    side: BorderSide(
                      color: isMember
                          ? TeritoryColors.border
                          : TeritoryColors.communityIndigo,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _membershipPending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          membershipLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    final feedAsync = ref.watch(communityFeedProvider(widget.communityId));

    return feedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TeritoryColors.communityIndigo),
      ),
      error: (error, _) => _TabError(
        message: _errorMessage(error),
        onRetry: () =>
            ref.invalidate(communityFeedProvider(widget.communityId)),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return const _TabMessage(text: 'No activity yet');
        }
        return RefreshIndicator(
          color: TeritoryColors.communityIndigo,
          onRefresh: () async =>
              ref.invalidate(communityFeedProvider(widget.communityId)),
          child: ListView.separated(
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
                        color: TeritoryColors.communityIndigo.withValues(
                          alpha: 0.1,
                        ),
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
                          if (activity.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              activity.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: TeritoryColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Avatar(
                                name: activity.userName,
                                avatarUrl: activity.userAvatar,
                                radius: 10,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  activity.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: TeritoryColors.textPrimary,
                                  ),
                                ),
                              ),
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
          ),
        );
      },
    );
  }

  // ─── Trip Plans Tab ─────────────────────────────────────────────────

  Widget _buildTripPlansTab() {
    final plansAsync = ref.watch(communityPlansProvider(widget.communityId));

    return plansAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TeritoryColors.communityIndigo),
      ),
      error: (error, _) => _TabError(
        message: _errorMessage(error),
        onRetry: () =>
            ref.invalidate(communityPlansProvider(widget.communityId)),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_off_rounded,
                      size: 48, color: TeritoryColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No expedition plans yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Be the first to propose an expedition for this community!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final communityName = ref
                          .read(communityDetailProvider(widget.communityId))
                          .valueOrNull
                          ?.name;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TripPlannerScreen(
                            communityId: widget.communityId,
                            communityName: communityName,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      ref.invalidate(communityPlansProvider(widget.communityId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeritoryColors.communityIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Propose First Plan'),
                  ),
                ],
              ),
            ),
          );
        }

        final highestScore = plans
            .map((plan) => plan.voteScore)
            .reduce((a, b) => a > b ? a : b);

        return Stack(
          children: [
            RefreshIndicator(
              color: TeritoryColors.communityIndigo,
              onRefresh: () async =>
                  ref.invalidate(communityPlansProvider(widget.communityId)),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildPlanCard(
                  plans[index],
                  plans[index].voteScore == highestScore,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final communityName = ref
                      .read(communityDetailProvider(widget.communityId))
                      .valueOrNull
                      ?.name;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TripPlannerScreen(
                        communityId: widget.communityId,
                        communityName: communityName,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  ref.invalidate(communityPlansProvider(widget.communityId));
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
      },
    );
  }

  Widget _buildPlanCard(TripPlan plan, bool isWinning) {
    final pending = _pendingVotes.contains(plan.id);

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
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: TeritoryColors.majorGold,
                ),
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
              const Icon(
                Icons.place_rounded,
                size: 14,
                color: TeritoryColors.communityIndigo,
              ),
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
                onPressed: pending ? null : () => _toggleVote(plan.id),
                icon: pending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.thumb_up_outlined, size: 18),
                color: TeritoryColors.communityIndigo,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Vote for this plan',
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
            ],
          ),
        ],
      ),
    );
  }

  // ─── Members Tab ────────────────────────────────────────────────────

  Widget _buildMembersTab(Community community) {
    final membersAsync = ref.watch(
      communityMembersLiveProvider(widget.communityId),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openInviteSheet(community.name),
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
            error: (error, _) => _TabError(
              message: _errorMessage(error),
              onRetry: () => ref.invalidate(
                communityMembersLiveProvider(widget.communityId),
              ),
            ),
            data: (members) {
              if (members.isEmpty) {
                return const _TabMessage(text: 'No members yet');
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: members.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final badgeColor = _roleBadgeColor(member.role);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _Avatar(
                      name: member.userName,
                      avatarUrl: member.userAvatar,
                      radius: 20,
                    ),
                    title: Text(
                      member.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Container(
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
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Chat Tab ───────────────────────────────────────────────────────

  Widget _buildChatTab(String currentUserId) {
    final messagesAsync = ref.watch(
      communityMessagesProvider(widget.communityId),
    );

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: TeritoryColors.communityIndigo,
              ),
            ),
            error: (error, _) => _TabError(
              message: _errorMessage(error),
              onRetry: () =>
                  ref.invalidate(communityMessagesProvider(widget.communityId)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const _TabMessage(text: 'No messages yet — say hello');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildChatBubble(
                    message,
                    message.userId == currentUserId,
                  );
                },
              );
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
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
                          color: TeritoryColors.communityIndigo,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendingMessage ? null : _sendMessage,
                  icon: _sendingMessage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
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
      mainAxisAlignment: isSelf
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSelf) ...[
          _Avatar(name: msg.userName, avatarUrl: msg.userAvatar, radius: 14),
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

/// Avatar that degrades to initials when the API has no image or it fails.
class _Avatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double radius;

  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: TeritoryColors.communityIndigo.withValues(alpha: 0.15),
      backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      onBackgroundImageError: avatarUrl.isEmpty ? null : (_, _) {},
      child: avatarUrl.isEmpty
          ? Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.communityIndigo,
              ),
            )
          : null,
    );
  }
}

class _TabMessage extends StatelessWidget {
  final String text;
  const _TabMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(color: TeritoryColors.textMuted),
      ),
    );
  }
}

class _TabError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TabError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
