import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_clan.dart';
import '../../../core/models/clan_models.dart';
import '../../../core/models/community_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/clans_provider.dart';

class ClanDetailScreen extends ConsumerStatefulWidget {
  final String clanId;
  const ClanDetailScreen({super.key, required this.clanId});

  @override
  ConsumerState<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends ConsumerState<ClanDetailScreen> {
  bool _membershipPending = false;

  Future<void> _refresh() async {
    ref.invalidate(clanDetailProvider(widget.clanId));
    await ref.read(clansProvider.notifier).refresh();
  }

  Future<void> _toggleMembership({required bool isMember}) async {
    if (_membershipPending) return;

    if (isMember) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave this clan?'),
          content: const Text(
              'Your communities and messages stay; your membership does not.'),
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
      await ref.read(clansProvider.notifier).toggleMembership(widget.clanId);
      if (!mounted) return;
      // The list was patched optimistically; re-read the server for the header
      // count and the roster so both screens settle on the same numbers.
      ref.invalidate(clanDetailProvider(widget.clanId));
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not reach Teritory. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _membershipPending = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(clanDetailProvider(widget.clanId));
    final clansAsync = ref.watch(clansProvider);
    final currentUserId = ref.watch(currentUserProvider).id;
    final detail = detailAsync.valueOrNull;

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: detailAsync.hasError
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 44, color: TeritoryColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        detailAsync.error is ApiException
                            ? (detailAsync.error as ApiException).message
                            : 'Could not load this clan.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(clanDetailProvider(widget.clanId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(
                  color: TeritoryColors.clanPurple),
        ),
      );
    }

    final clan = detail.clan;
    final clansData = clansAsync.valueOrNull;
    final isMember = clansData?.isMember(clan.id) ?? false;
    final isChieftain =
        currentUserId.isNotEmpty && clan.chieftainId == currentUserId;

    // Distinguish "still checking" from "could not check": both disable the
    // button, but only one is a failure.
    final membershipLabel = clansData != null
        ? (isMember ? 'Leave Clan' : 'Join Clan')
        : (clansAsync.isLoading
            ? 'Checking membership…'
            : 'Membership unavailable');

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      body: RefreshIndicator(
        color: TeritoryColors.clanPurple,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Hero header
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: TeritoryColors.clanPurple,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  // Opened from the list it was pushed, so pop returns there; a
                  // deep link has no stack and falls back to the clan list.
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/clans');
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                title: Text(
                  clan.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (clan.coverImageUrl.isEmpty)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TeritoryColors.clanPurple,
                              TeritoryColors.communityIndigo,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      )
                    else
                      Image.network(
                        clan.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TeritoryColors.clanPurple,
                                TeritoryColors.communityIndigo,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                        value: '${clan.memberCount}', label: 'Members'),
                    Container(
                      width: 1,
                      height: 30,
                      color: TeritoryColors.border,
                    ),
                    _StatColumn(
                        value: '${detail.communities.length}',
                        label: 'Communities'),
                    Container(
                      width: 1,
                      height: 30,
                      color: TeritoryColors.border,
                    ),
                    _StatColumn(
                        value: clan.region.isEmpty ? '—' : clan.region,
                        label: 'Region'),
                  ],
                ),
              ),
            ),

            // Description
            if (clan.description.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    clan.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: TeritoryColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Membership action
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isChieftain
                    ? _ChieftainNotice()
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _membershipPending || clansData == null
                              ? null
                              : () => _toggleMembership(isMember: isMember),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMember
                                ? TeritoryColors.surfaceContainer
                                : TeritoryColors.clanPurple,
                            foregroundColor: isMember
                                ? TeritoryColors.textPrimary
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isMember
                                    ? TeritoryColors.border
                                    : TeritoryColors.clanPurple,
                              ),
                            ),
                          ),
                          icon: _membershipPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(
                                  isMember
                                      ? Icons.logout_rounded
                                      : Icons.add_rounded,
                                  size: 20,
                                ),
                          label: Text(
                            membershipLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Chieftain bar
            SliverToBoxAdapter(child: _ChieftainBar(clan: clan)),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Members
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        size: 18, color: TeritoryColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Members',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${clan.memberCount} total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: detail.members.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        'No members to show yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 96,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.members.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) =>
                            _MemberTile(member: detail.members[index]),
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Communities header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 18, color: TeritoryColors.communityIndigo),
                    const SizedBox(width: 8),
                    Text(
                      'Communities',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${detail.communities.length} total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (detail.communities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No communities in this clan yet — create the first one.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final community = detail.communities[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: _CommunityCard(
                        community: community,
                        onTap: () => context.push(
                            '/clans/${widget.clanId}/communities/${community.id}'),
                      ),
                    );
                  },
                  childCount: detail.communities.length,
                ),
              ),

            // Create Community button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/clans/${widget.clanId}/create'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeritoryColors.communityIndigo,
                    side: const BorderSide(
                        color: TeritoryColors.communityIndigo),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Create Community',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _ChieftainNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TeritoryColors.clanPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeritoryColors.clanPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded,
              size: 18, color: TeritoryColors.clanPurple),
          const SizedBox(width: 8),
          Text(
            'You are the Chieftain of this clan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.clanPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ApiClanMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final firstName = member.name.split(' ').first;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: TeritoryColors.clanPurple.withValues(alpha: 0.12),
            backgroundImage: member.avatarUrl.isNotEmpty
                ? NetworkImage(member.avatarUrl)
                : null,
            child: member.avatarUrl.isNotEmpty
                ? null
                : Text(
                    firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.clanPurple,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TeritoryColors.textPrimary,
            ),
          ),
          Text(
            member.role == ClanRole.chieftain ? 'Chieftain' : 'Member',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: TeritoryColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: TeritoryColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: TeritoryColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChieftainBar extends StatelessWidget {
  final Clan clan;
  const _ChieftainBar({required this.clan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            radius: 22,
            backgroundColor: TeritoryColors.clanPurple.withValues(alpha: 0.15),
            child: const Icon(Icons.shield_rounded,
                color: TeritoryColors.clanPurple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chieftain',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: TeritoryColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  clan.chieftainName.isEmpty ? 'Unknown' : clan.chieftainName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: TeritoryColors.clanPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: TeritoryColors.clanPurple),
                const SizedBox(width: 4),
                Text(
                  'Leader',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.clanPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onTap;
  const _CommunityCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    TeritoryColors.communityIndigo,
                    TeritoryColors.clanPurple,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: community.coverImageUrl.isEmpty
                    ? const Icon(Icons.groups_rounded,
                        color: Colors.white, size: 28)
                    : Image.network(
                        community.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${community.memberCount} members • ${community.activeTripPlansCount} trips',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  if (community.interestTags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: community.interestTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TeritoryColors.communityIndigo
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag.replaceAll('_', ' '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.communityIndigo,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: TeritoryColors.textMuted),
          ],
        ),
      ),
    );
  }
}
