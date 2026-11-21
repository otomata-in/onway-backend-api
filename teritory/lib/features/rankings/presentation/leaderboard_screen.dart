import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../clans/application/clans_provider.dart';
import '../application/rankings_provider.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.global;
  LeaderboardPeriod _period = LeaderboardPeriod.alltime;
  String? _country;
  String? _state;
  String? _district;
  String? _clanId;
  String? _communityId;
  bool _breakdownExpanded = false;

  LeaderboardQuery get _query => LeaderboardQuery(
        scope: _scope,
        period: _period,
        country: _scope == LeaderboardScope.country ? _country : null,
        state: _scope == LeaderboardScope.state ? _state : null,
        district: _scope == LeaderboardScope.district ? _district : null,
        clanId: _scope == LeaderboardScope.clan ? _clanId : null,
        communityId: _scope == LeaderboardScope.community ? _communityId : null,
      );

  String? get _missingGeoValue {
    switch (_scope) {
      case LeaderboardScope.country:
        return (_country ?? '').isEmpty ? 'country' : null;
      case LeaderboardScope.state:
        return (_state ?? '').isEmpty ? 'state' : null;
      case LeaderboardScope.district:
        return (_district ?? '').isEmpty ? 'district' : null;
      default:
        return null;
    }
  }

  /// Picks the first live option when a geo scope has no selection yet, so the
  /// list never sits empty waiting for a tap.
  void _applyFacetDefaults(RankingsFacets facets) {
    if (!mounted) return;
    setState(() {
      switch (_scope) {
        case LeaderboardScope.country:
          _country ??= facets.countries.firstOrNull;
        case LeaderboardScope.state:
          _state ??= facets.states.firstOrNull;
        case LeaderboardScope.district:
          _district ??= facets.districts.firstOrNull;
        default:
          break;
      }
    });
  }

  void _changeScope(LeaderboardScope scope) {
    setState(() => _scope = scope);
    final facets = ref.read(rankingsFacetsProvider).valueOrNull;
    if (facets != null) _applyFacetDefaults(facets);
  }

  Future<void> _refresh(LeaderboardQuery query) async {
    ref.invalidate(rankingsFacetsProvider);
    ref.invalidate(myRankProvider);
    ref.invalidate(rankingsProvider(query));
    try {
      await ref.read(rankingsProvider(query).future);
    } on ApiException {
      // The error state renders the message; refresh just ends here.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep geo defaults in sync when the live facets finish loading.
    ref.listen(rankingsFacetsProvider, (previous, next) {
      next.whenData(_applyFacetDefaults);
    });

    final facetsAsync = ref.watch(rankingsFacetsProvider);
    final query = _query;
    final missingGeo = _missingGeoValue;
    final entriesAsync = missingGeo == null ? ref.watch(rankingsProvider(query)) : null;
    final myRankAsync = ref.watch(myRankProvider);
    final currentUser = ref.watch(currentUserProvider);

    final entries = entriesAsync?.valueOrNull ?? const <LeaderboardEntry>[];
    LeaderboardEntry? myEntry;
    for (final entry in entries) {
      if (entry.userId == currentUser.id) {
        myEntry = entry;
        break;
      }
    }

    final top3 = entries.where((e) => e.rank <= 3).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final rest = entries.where((e) => e.rank > 3).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    LeaderboardEntry? nearestCompetitor;
    if (myEntry != null && myEntry.rank > 1) {
      for (final entry in entries) {
        if (entry.rank == myEntry.rank - 1) {
          nearestCompetitor = entry;
          break;
        }
      }
    }

    final myRank = myRankAsync.valueOrNull;

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
          RefreshIndicator(
            color: TeritoryColors.primary,
            onRefresh: () => _refresh(query),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ScopePills(
                      selected: _scope,
                      onChanged: _changeScope,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _TimeFilter(
                      selected: _period,
                      onChanged: (period) =>
                          setState(() => _period = period),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GeoFilterBar(
                    scope: _scope,
                    facetsAsync: facetsAsync,
                    country: _country,
                    state: _state,
                    district: _district,
                    clanId: _clanId,
                    onCountryChanged: (value) =>
                        setState(() => _country = value),
                    onStateChanged: (value) => setState(() => _state = value),
                    onDistrictChanged: (value) =>
                        setState(() => _district = value),
                    onClanChanged: (value) => setState(() => _clanId = value),
                    onRetryFacets: () =>
                        ref.invalidate(rankingsFacetsProvider),
                  ),
                ),

                if (entriesAsync == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MissingFilterState(missing: missingGeo!),
                  )
                else
                  ...entriesAsync.when(
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: TeritoryColors.primary),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          message: error is ApiException
                              ? error.message
                              : 'Could not load the rankings. Check the API and retry.',
                          onRetry: () =>
                              ref.invalidate(rankingsProvider(query)),
                        ),
                      ),
                    ],
                    data: (entries) {
                      if (entries.isEmpty) {
                        return [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(scope: _scope, period: _period),
                          ),
                        ];
                      }
                      return [
                        if (top3.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: _PodiumSection(top3: top3),
                            ),
                          ),
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
                        if (myEntry != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: _ScoreBreakdownSection(
                                myRankAsync: myRankAsync,
                                isExpanded: _breakdownExpanded,
                                onToggle: () => setState(
                                    () => _breakdownExpanded = !_breakdownExpanded),
                                onRetry: () => ref.invalidate(myRankProvider),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ];
                    },
                  ),
              ],
            ),
          ),

          if (myEntry != null || myRank != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _MyRankCard(
                entry: myEntry,
                myRank: myRank,
                fallbackName: currentUser.displayName,
                fallbackAvatar: currentUser.avatarUrl,
                nearestCompetitor: nearestCompetitor,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Geo filters ────────────────────────────────────────────────────────────

class _GeoFilterBar extends ConsumerWidget {
  const _GeoFilterBar({
    required this.scope,
    required this.facetsAsync,
    required this.country,
    required this.state,
    required this.district,
    required this.clanId,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onDistrictChanged,
    required this.onClanChanged,
    required this.onRetryFacets,
  });

  final LeaderboardScope scope;
  final AsyncValue<RankingsFacets> facetsAsync;
  final String? country;
  final String? state;
  final String? district;
  final String? clanId;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onClanChanged;
  final VoidCallback onRetryFacets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scope == LeaderboardScope.clan) {
      final clansAsync = ref.watch(clansProvider);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: clansAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) {
            final myClans = data.myClans;
            if (myClans.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TeritoryColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 16, color: TeritoryColors.clanPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Clan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: myClans.any((c) => c.id == clanId) ? clanId : null,
                        isExpanded: true,
                        hint: Text('All My Clans',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All My Clans',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          ...myClans.map((c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13)),
                              )),
                        ],
                        onChanged: onClanChanged,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final isGeoScope = scope == LeaderboardScope.country ||
        scope == LeaderboardScope.state ||
        scope == LeaderboardScope.district;
    if (!isGeoScope) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: facetsAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (_, _) => Row(
          children: [
            Expanded(
              child: Text(
                'Could not load filter options.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ),
            TextButton(onPressed: onRetryFacets, child: const Text('Retry')),
          ],
        ),
        data: (facets) {
          final options = scope == LeaderboardScope.country
              ? facets.countries
              : scope == LeaderboardScope.state
                  ? facets.states
                  : facets.districts;
          final selected = scope == LeaderboardScope.country
              ? country
              : scope == LeaderboardScope.state
                  ? state
                  : district;
          final label = scope == LeaderboardScope.country
              ? 'Country'
              : scope == LeaderboardScope.state
                  ? 'State'
                  : 'District';
          final onChanged = scope == LeaderboardScope.country
              ? onCountryChanged
              : scope == LeaderboardScope.state
                  ? onStateChanged
                  : onDistrictChanged;

          if (options.isEmpty) {
            return Text(
              'No ${label.toLowerCase()} data in the rankings yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textSecondary,
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TeritoryColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 16,
                  color: TeritoryColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: ValueKey('$label-${options.length}'),
                      value: options.contains(selected) ? selected : null,
                      isExpanded: true,
                      hint: Text(
                        'Select ${label.toLowerCase()}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                      items: options
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  style:
                                      GoogleFonts.plusJakartaSans(fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── State widgets ──────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
                size: 48, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MissingFilterState extends StatelessWidget {
  const _MissingFilterState({required this.missing});

  final String missing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Choose a $missing to see its rankings.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: TeritoryColors.textSecondary,
          ),
        ),
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
    final periodLabel = switch (period) {
      LeaderboardPeriod.alltime => 'all time',
      LeaderboardPeriod.month => 'this month',
      LeaderboardPeriod.week => 'this week',
    };

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
              'Nobody has scored in this filter for $periodLabel.\nDrop flags, complete trips, and join rallies to appear here.',
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

// ─── Avatars ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.name,
    required this.radius,
    this.borderColor,
    this.borderWidth = 2,
    this.shadowColor,
  });

  final String url;
  final String name;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: shadowColor == null
            ? null
            : [
                BoxShadow(
                  color: shadowColor!.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: TeritoryColors.surfaceContainer,
        backgroundImage: url.isEmpty ? null : NetworkImage(url),
        onBackgroundImageError: url.isEmpty ? null : (_, _) {},
        child: url.isEmpty
            ? Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textSecondary,
                ),
              )
            : null,
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
    LeaderboardEntry? rank1, rank2, rank3;
    for (final entry in top3) {
      if (entry.rank == 1) rank1 = entry;
      if (entry.rank == 2) rank2 = entry;
      if (entry.rank == 3) rank3 = entry;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
        _Avatar(
          url: entry.userAvatar,
          name: entry.userName,
          radius: avatarSize / 2,
          borderColor: medalColor,
          borderWidth: 3,
          shadowColor: medalColor,
        ),
        const SizedBox(height: 8),
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
          _Avatar(url: entry.userAvatar, name: entry.userName, radius: 22),
          const SizedBox(width: 12),
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
                      icon: Icons.star_rounded,
                      label: '${entry.majorFlags}',
                      color: TeritoryColors.majorGold,
                    ),
                    _StatBadge(
                      icon: Icons.route_rounded,
                      label: '${entry.completedTrips}',
                      color: TeritoryColors.tripRoute,
                    ),
                  ],
                ),
              ],
            ),
          ),
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

// ─── Score Breakdown ────────────────────────────────────────────────────────

class _ScoreBreakdownSection extends StatelessWidget {
  const _ScoreBreakdownSection({
    required this.myRankAsync,
    required this.isExpanded,
    required this.onToggle,
    required this.onRetry,
  });

  final AsyncValue<MyRank> myRankAsync;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRetry;

  static const _labels = <String, (String, IconData, Color)>{
    'flagsPoints': ('Flags', Icons.flag_rounded, TeritoryColors.primary),
    'majorFlagsPoints': ('Major flags', Icons.star_rounded, TeritoryColors.majorGold),
    'countriesPoints': ('Countries', Icons.public_rounded, TeritoryColors.sapphireBlue),
    'continentsPoints': ('Continents', Icons.explore_rounded, TeritoryColors.communityIndigo),
    'tripsPoints': ('Completed trips', Icons.route_rounded, TeritoryColors.tripRoute),
    'ralliesPoints': ('Legendary rallies', Icons.flash_on_rounded, TeritoryColors.rallyGold),
    'stampsPoints': ('Passport stamps', Icons.verified_rounded, TeritoryColors.validatedGreen),
  };

  @override
  Widget build(BuildContext context) {
    final myRank = myRankAsync.valueOrNull;

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
                          'How the API calculates your score',
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
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: TeritoryColors.border),
                  const SizedBox(height: 12),
                  if (myRankAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                          color: TeritoryColors.rallyGold),
                    )
                  else if (myRankAsync.hasError)
                    Column(
                      children: [
                        Text(
                          myRankAsync.error is ApiException
                              ? (myRankAsync.error as ApiException).message
                              : 'Could not load your score breakdown.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                        TextButton(
                            onPressed: onRetry, child: const Text('Retry')),
                      ],
                    )
                  else if (myRank != null) ...[
                    for (final entry in _labels.entries)
                      if (myRank.breakdown.containsKey(entry.key))
                        _BreakdownRow(
                          icon: entry.value.$2,
                          label: entry.value.$1,
                          value: myRank.breakdown[entry.key]!,
                          color: entry.value.$3,
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
                            _formatScore(myRank.score),
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
            '$value pts',
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
  const _MyRankCard({
    required this.entry,
    required this.myRank,
    required this.fallbackName,
    required this.fallbackAvatar,
    this.nearestCompetitor,
  });

  final LeaderboardEntry? entry;
  final MyRank? myRank;
  final String fallbackName;
  final String fallbackAvatar;
  final LeaderboardEntry? nearestCompetitor;

  @override
  Widget build(BuildContext context) {
    final rank = entry?.rank ?? myRank?.globalRank;
    final score = entry?.compositeScore ?? myRank?.score;
    final name = entry?.userName ?? fallbackName;
    final avatar = entry?.userAvatar ?? fallbackAvatar;
    if (rank == null || score == null) return const SizedBox.shrink();

    final gap = nearestCompetitor != null && entry != null
        ? nearestCompetitor!.compositeScore - entry!.compositeScore
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
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(url: avatar, name: name, radius: 18),
          const SizedBox(width: 10),
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
                  name,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatScore(score),
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
    final s = score.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return score.toString();
}
