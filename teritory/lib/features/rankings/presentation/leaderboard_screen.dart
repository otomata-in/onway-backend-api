import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

// ─── Local state providers ──────────────────────────────────────────────────

final _selectedScopeProvider =
    StateProvider<LeaderboardScope>((ref) => LeaderboardScope.global);

final _selectedPeriodProvider =
    StateProvider<LeaderboardPeriod>((ref) => LeaderboardPeriod.alltime);

final _scoreBreakdownExpandedProvider = StateProvider<bool>((ref) => false);

// ─── Screen ─────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(_selectedScopeProvider);
    final period = ref.watch(_selectedPeriodProvider);
    final entries = ref.watch(
      leaderboardProvider((scope: scope, period: period)),
    );
    final currentUser = ref.watch(currentUserProvider);

    // Find the current user's entry
    LeaderboardEntry? myEntry;
    for (final e in entries) {
      if (e.userId == currentUser.id) {
        myEntry = e;
        break;
      }
    }

    // Top 3 and rest
    final top3 = entries.where((e) => e.rank <= 3).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final rest = entries.where((e) => e.rank > 3).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    // Nearest competitor (person ranked directly above the current user)
    LeaderboardEntry? nearestCompetitor;
    if (myEntry != null && myEntry.rank > 1) {
      for (final e in entries) {
        if (e.rank == myEntry.rank - 1) {
          nearestCompetitor = e;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: TeritoryColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_rounded,
                color: TeritoryColors.rallyGold, size: 24),
            const SizedBox(width: 8),
            Text(
              'Expedition Rankings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: TeritoryColors.border),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Scope pills ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ScopePills(
                    selected: scope,
                    onChanged: (s) =>
                        ref.read(_selectedScopeProvider.notifier).state = s,
                  ),
                ),
              ),

              // ── Time filter ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TimeFilter(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(_selectedPeriodProvider.notifier).state = p,
                  ),
                ),
              ),

              // ── Empty state ────────────────────────────────────────
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(scope: scope, period: period),
                )
              else ...[
                // ── Top 3 Podium ─────────────────────────────────────
                if (top3.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: _PodiumSection(top3: top3),
                    ),
                  ),

                // ── Ranked list ──────────────────────────────────────
                if (rest.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Rankings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _RankedTile(entry: rest[index]),
                      childCount: rest.length,
                    ),
                  ),
                ),

                // ── Score breakdown ──────────────────────────────────
                if (myEntry != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ScoreBreakdownSection(
                        entry: myEntry,
                        isExpanded: ref.watch(_scoreBreakdownExpandedProvider),
                        onToggle: () => ref
                            .read(_scoreBreakdownExpandedProvider.notifier)
                            .state = !ref.read(_scoreBreakdownExpandedProvider),
                      ),
                    ),
                  ),

                // Bottom padding for the floating card
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ],
          ),

          // ── My Rank floating card ──────────────────────────────────
          if (myEntry != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _MyRankCard(
                entry: myEntry,
                nearestCompetitor: nearestCompetitor,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Scope Pills ────────────────────────────────────────────────────────────

class _ScopePills extends StatelessWidget {
  const _ScopePills({required this.selected, required this.onChanged});

  final LeaderboardScope selected;
  final ValueChanged<LeaderboardScope> onChanged;

  static const _labels = {
    LeaderboardScope.global: 'Global',
    LeaderboardScope.country: 'Country',
    LeaderboardScope.state: 'State',
    LeaderboardScope.district: 'District',
    LeaderboardScope.friends: 'Friends',
    LeaderboardScope.clan: 'Clan',
    LeaderboardScope.community: 'Community',
  };

  static const _icons = {
    LeaderboardScope.global: Icons.public_rounded,
    LeaderboardScope.country: Icons.flag_rounded,
    LeaderboardScope.state: Icons.map_rounded,
    LeaderboardScope.district: Icons.location_city_rounded,
    LeaderboardScope.friends: Icons.people_rounded,
    LeaderboardScope.clan: Icons.shield_rounded,
    LeaderboardScope.community: Icons.groups_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LeaderboardScope.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scope = LeaderboardScope.values[index];
          final isSelected = scope == selected;
          return GestureDetector(
            onTap: () => onChanged(scope),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? TeritoryColors.primary
                    : TeritoryColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? TeritoryColors.primary
                      : TeritoryColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: TeritoryColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[scope],
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : TeritoryColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _labels[scope]!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : TeritoryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Time Filter ────────────────────────────────────────────────────────────

class _TimeFilter extends StatelessWidget {
  const _TimeFilter({required this.selected, required this.onChanged});

  final LeaderboardPeriod selected;
  final ValueChanged<LeaderboardPeriod> onChanged;

  static const _labels = {
    LeaderboardPeriod.alltime: 'All Time',
    LeaderboardPeriod.month: 'This Month',
    LeaderboardPeriod.week: 'This Week',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TeritoryColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: LeaderboardPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _labels[period]!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? TeritoryColors.textPrimary
                        : TeritoryColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scope, required this.period});

  final LeaderboardScope scope;
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: TeritoryColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to earn points in this category!\nDrop flags, complete trips, and join rallies.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: TeritoryColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top 3 Podium ───────────────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    // Layout: [Rank 2] [Rank 1 (taller)] [Rank 3]
    LeaderboardEntry? rank1, rank2, rank3;
    for (final e in top3) {
      if (e.rank == 1) rank1 = e;
      if (e.rank == 2) rank2 = e;
      if (e.rank == 3) rank3 = e;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: TeritoryColors.rallyGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Explorers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Podium columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 — left
              Expanded(
                child: rank2 != null
                    ? _PodiumColumn(
                        entry: rank2,
                        height: 100,
                        medalColor: const Color(0xFFC0C0C0),
                        medalGradient: const [
                          Color(0xFFE8E8E8),
                          Color(0xFFC0C0C0),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // Rank 1 — center (tallest)
              Expanded(
                child: rank1 != null
                    ? _PodiumColumn(
                        entry: rank1,
                        height: 130,
                        medalColor: const Color(0xFFFFD700),
                        medalGradient: const [
                          Color(0xFFFFF176),
                          Color(0xFFFFD700),
                        ],
                        showCrown: true,
                      )
                    : const SizedBox.shrink(),
              ),

              // Rank 3 — right
              Expanded(
                child: rank3 != null
                    ? _PodiumColumn(
                        entry: rank3,
                        height: 80,
                        medalColor: const Color(0xFFCD7F32),
                        medalGradient: const [
                          Color(0xFFE8A862),
                          Color(0xFFCD7F32),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.medalColor,
    required this.medalGradient,
    this.showCrown = false,
  });

  final LeaderboardEntry entry;
  final double height;
  final Color medalColor;
  final List<Color> medalGradient;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    final avatarSize = showCrown ? 56.0 : 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for rank 1
        if (showCrown)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFF176), Color(0xFFFFD700)],
            ).createShader(bounds),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        if (showCrown) const SizedBox(height: 4),

        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: TeritoryColors.surfaceContainer,
            backgroundImage: NetworkImage(entry.userAvatar),
          ),
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          entry.userName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),

        // Handle
        Text(
          entry.userHandle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: TeritoryColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),

        // Score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: medalGradient),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatScore(entry.compositeScore),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Podium bar
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.3),
                medalColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(color: medalColor.withValues(alpha: 0.5)),
              left: BorderSide(color: medalColor.withValues(alpha: 0.2)),
              right: BorderSide(color: medalColor.withValues(alpha: 0.2)),
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: medalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ranked Tile ────────────────────────────────────────────────────────────

class _RankedTile extends StatelessWidget {
  const _RankedTile({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TeritoryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: TeritoryColors.surfaceContainer,
            backgroundImage: NetworkImage(entry.userAvatar),
          ),
          const SizedBox(width: 12),

          // Name and handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.userHandle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // Stat badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _StatBadge(
                      icon: Icons.flag_rounded,
                      label: '${entry.totalFlags}',
                      color: TeritoryColors.primary,
                    ),
                    _StatBadge(
                      icon: Icons.public_rounded,
                      label: '${entry.countriesVisited}',
                      color: TeritoryColors.sapphireBlue,
                    ),
                    _StatBadge(
                      icon: Icons.route_rounded,
                      label: '${entry.completedTrips}',
                      color: TeritoryColors.tripRoute,
                    ),
                    if (entry.legendaryRallies > 0)
                      _StatBadge(
                        icon: Icons.flash_on_rounded,
                        label: '${entry.legendaryRallies}',
                        color: TeritoryColors.rallyGold,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatScore(entry.compositeScore),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'pts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Badge ─────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Breakdown Section ────────────────────────────────────────────────

class _ScoreBreakdownSection extends StatelessWidget {
  const _ScoreBreakdownSection({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
  });

  final LeaderboardEntry entry;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeritoryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (tap to toggle)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TeritoryColors.rallyGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: TeritoryColors.rallyGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score Breakdown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'See how your score is calculated',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: TeritoryColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: TeritoryColors.border),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    icon: Icons.flag_rounded,
                    label: 'Total Flags',
                    value: entry.totalFlags,
                    color: TeritoryColors.primary,
                  ),
                  _BreakdownRow(
                    icon: Icons.star_rounded,
                    label: 'Major Flags',
                    value: entry.majorFlags,
                    color: TeritoryColors.majorGold,
                  ),
                  _BreakdownRow(
                    icon: Icons.public_rounded,
                    label: 'Countries Visited',
                    value: entry.countriesVisited,
                    color: TeritoryColors.sapphireBlue,
                  ),
                  _BreakdownRow(
                    icon: Icons.explore_rounded,
                    label: 'Continents Explored',
                    value: entry.continentsExplored,
                    color: TeritoryColors.communityIndigo,
                  ),
                  _BreakdownRow(
                    icon: Icons.route_rounded,
                    label: 'Completed Trips',
                    value: entry.completedTrips,
                    color: TeritoryColors.tripRoute,
                  ),
                  _BreakdownRow(
                    icon: Icons.flash_on_rounded,
                    label: 'Legendary Rallies',
                    value: entry.legendaryRallies,
                    color: TeritoryColors.rallyGold,
                  ),
                  _BreakdownRow(
                    icon: Icons.groups_rounded,
                    label: 'Community Contributions',
                    value: entry.communityContributions,
                    color: TeritoryColors.validatedGreen,
                  ),
                  _BreakdownRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak Days',
                    value: entry.streakDays,
                    color: TeritoryColors.foodOrange,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: TeritoryColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Composite Score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.primary,
                          ),
                        ),
                        Text(
                          _formatScore(entry.compositeScore),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: TeritoryColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
              ),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Rank Floating Card ──────────────────────────────────────────────────

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry, this.nearestCompetitor});

  final LeaderboardEntry entry;
  final LeaderboardEntry? nearestCompetitor;

  @override
  Widget build(BuildContext context) {
    final gap = nearestCompetitor != null
        ? nearestCompetitor!.compositeScore - entry.compositeScore
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: TeritoryColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TeritoryColors.primary, TeritoryColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: TeritoryColors.surfaceContainer,
            backgroundImage: NetworkImage(entry.userAvatar),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (nearestCompetitor != null && gap > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_formatScore(gap)} pts behind ${nearestCompetitor!.userName.split(' ').first}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: TeritoryColors.rallyGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatScore(entry.compositeScore),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: TeritoryColors.primary,
                ),
              ),
              Text(
                'points',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatScore(int score) {
  if (score >= 10000) {
    final k = score / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
  }
  if (score >= 1000) {
    // Add comma: e.g. 9,850
    final s = score.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return score.toString();
}
