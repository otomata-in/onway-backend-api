import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/clan_models.dart';
import '../../../core/models/community_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class ClanDetailScreen extends ConsumerWidget {
  final String clanId;
  const ClanDetailScreen({super.key, required this.clanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clan = ref.watch(clanByIdProvider(clanId));
    final communities = ref.watch(communitiesByClanProvider(clanId));

    if (clan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Clan not found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: TeritoryColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: TeritoryColors.clanPurple,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
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
                  Image.network(
                    clan.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      value: '${clan.communitiesCount}',
                      label: 'Communities'),
                  Container(
                    width: 1,
                    height: 30,
                    color: TeritoryColors.border,
                  ),
                  _StatColumn(value: clan.region, label: 'Region'),
                ],
              ),
            ),
          ),

          // Description
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

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Chieftain bar
          SliverToBoxAdapter(
            child: _ChieftainBar(clan: clan),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Communities header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.groups_rounded,
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
                    '${communities.length} total',
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

          // Communities list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final community = communities[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _CommunityCard(
                    community: community,
                    onTap: () => context.go(
                        '/clans/$clanId/communities/${community.id}'),
                  ),
                );
              },
              childCount: communities.length,
            ),
          ),

          // Create Community button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => context.go('/clans/$clanId/create'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeritoryColors.communityIndigo,
                  side:
                      const BorderSide(color: TeritoryColors.communityIndigo),
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
                  clan.chieftainName,
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
                child: Image.network(
                  community.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
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
