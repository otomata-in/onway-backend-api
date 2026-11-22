import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../clans/application/clans_provider.dart';
import '../application/rankings_provider.dart';

// ─── Expedition Theme Tokens ──────────────────────────────────────────────────

class _ExpeditionColors {
  static const Color background = Color(0xFF060B14);
  static const Color surfaceDark = Color(0xFF0B1322);
  static const Color cardBg = Color(0xFF0F1B2F);
  static const Color cardBgElevated = Color(0xFF14243D);
  static const Color cardBorder = Color(0xFF1E3250);

  static const Color cyanGlow = Color(0xFF38BDF8);
  static const Color coralFlame = Color(0xFFFF5330);
  static const Color wonderGold = Color(0xFFF59E0B);
  static const Color silverMist = Color(0xFFCBD5E1);
  static const Color bronzeRidge = Color(0xFFCD7F32);
  static const Color emeraldTrail = Color(0xFF10B981);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

// ─── Custom Topographic & Cartographic Background ─────────────────────────────

class _ExpeditionCartographyPainter extends CustomPainter {
  const _ExpeditionCartographyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final accentPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Topographic wavy contour lines
    for (double y = 60; y < size.height; y += 120) {
      final path = Path();
      path.moveTo(0, y);
      path.cubicTo(
        size.width * 0.25,
        y - 30,
        size.width * 0.45,
        y + 35,
        size.width * 0.7,
        y - 15,
      );
      path.cubicTo(
        size.width * 0.85,
        y - 45,
        size.width * 0.95,
        y + 20,
        size.width,
        y,
      );
      canvas.drawPath(path, linePaint);
    }

    // Concentric celestial & compass range rings in the upper portion
    final compassCenter = Offset(size.width * 0.82, 140);
    for (double r = 40; r <= 180; r += 45) {
      canvas.drawCircle(compassCenter, r, accentPaint);
    }

    // Cartographic latitude / longitude tick crosses
    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 40; x < size.width; x += 90) {
      for (double y = 100; y < size.height; y += 140) {
        // Draw miniature crosshair `+`
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), tickPaint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    if (_missingGeoValue != null) return;
    ref.read(leaderboardFeedProvider(_query).notifier).loadMore();
  }

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
    ref.invalidate(leaderboardFeedProvider(query));
    try {
      await ref.read(leaderboardFeedProvider(query).future);
    } on ApiException {
      // Error state renders notice
    }
  }

  void _scrollToLedger() {
    setState(() => _breakdownExpanded = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent - 80,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rankingsFacetsProvider, (previous, next) {
      next.whenData(_applyFacetDefaults);
    });

    final facetsAsync = ref.watch(rankingsFacetsProvider);
    final query = _query;
    final missingGeo = _missingGeoValue;
    final feedAsync = missingGeo == null
        ? ref.watch(leaderboardFeedProvider(query))
        : null;
    final myRankAsync = ref.watch(myRankProvider);
    final currentUser = ref.watch(currentUserProvider);

    final feed = feedAsync?.valueOrNull;
    final entries = feed?.entries ?? const <LeaderboardEntry>[];
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
      backgroundColor: _ExpeditionColors.background,
      body: Stack(
        children: [
          // Background Topography Canvas
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ExpeditionCartographyPainter(),
              ),
            ),
          ),

          // Main Scroll Area
          RefreshIndicator(
            color: _ExpeditionColors.cyanGlow,
            backgroundColor: _ExpeditionColors.cardBgElevated,
            onRefresh: () => _refresh(query),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Expedition Navigation Header
                SliverToBoxAdapter(
                  child: _ExpeditionHeader(
                    onOpenLedger: _scrollToLedger,
                  ),
                ),

                // Live Explorer Telemetry Ribbon
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _ExpeditionTelemetryStrip(),
                  ),
                ),

                // Expedition Theater Selector (Scope)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _ExpeditionScopePills(
                      selected: _scope,
                      onChanged: _changeScope,
                    ),
                  ),
                ),

                // Horizon / Epoch Selector (Time Period)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _ExpeditionHorizonFilter(
                      selected: _period,
                      onChanged: (period) => setState(() => _period = period),
                    ),
                  ),
                ),

                // Geographic / Clan / Community Filter Selector
                SliverToBoxAdapter(
                  child: _ExpeditionGeoFilterBar(
                    scope: _scope,
                    facetsAsync: facetsAsync,
                    country: _country,
                    state: _state,
                    district: _district,
                    clanId: _clanId,
                    communityId: _communityId,
                    onCountryChanged: (value) =>
                        setState(() => _country = value),
                    onStateChanged: (value) => setState(() => _state = value),
                    onDistrictChanged: (value) =>
                        setState(() => _district = value),
                    onClanChanged: (value) => setState(() => _clanId = value),
                    onCommunityChanged: (value) =>
                        setState(() => _communityId = value),
                    onRetryFacets: () =>
                        ref.invalidate(rankingsFacetsProvider),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                // Content Slivers
                if (feedAsync == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ExpeditionMissingFilterState(missing: missingGeo!),
                  )
                else
                  ...feedAsync.when(
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: _ExpeditionLoadingRadar(),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ExpeditionErrorState(
                          message: error is ApiException
                              ? error.message
                              : 'Could not synchronize expedition telemetry. Check satellite connection and retry.',
                          onRetry: () =>
                              ref.invalidate(leaderboardFeedProvider(query)),
                        ),
                      ),
                    ],
                    data: (feed) {
                      final entries = feed.entries;
                      if (entries.isEmpty) {
                        return [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ExpeditionEmptyState(
                              scope: _scope,
                              period: _period,
                            ),
                          ),
                        ];
                      }
                      return [
                        // The Grand Expedition Vanguard (Ranks 1, 2, 3)
                        if (top3.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: _GrandExpeditionVanguard(top3: top3),
                            ),
                          ),

                        // Field Explorer Dossiers Section Header
                        if (rest.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _ExpeditionColors.cyanGlow,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'EXPLORER FIELD LOGBOOK',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: _ExpeditionColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _ExpeditionColors.cardBgElevated,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _ExpeditionColors.cardBorder,
                                      ),
                                    ),
                                    child: Text(
                                      '${entries.length} TRAILBLAZERS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: _ExpeditionColors.cyanGlow,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Ranks 4+ List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _ExplorerFieldLogTile(
                                entry: rest[index],
                              ),
                              childCount: rest.length,
                            ),
                          ),
                        ),

                        // Expedition Merit & Cartographic Valuation Ledger
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: _ExpeditionLedgerSection(
                              myRankAsync: myRankAsync,
                              isExpanded: _breakdownExpanded,
                              onToggle: () => setState(() =>
                                  _breakdownExpanded = !_breakdownExpanded),
                              onRetry: () => ref.invalidate(myRankProvider),
                            ),
                          ),
                        ),

                        // Paging Footer
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 130),
                            child: _ExpeditionPagingFooter(
                              feed: feed,
                              onLoadMore: () => ref
                                  .read(leaderboardFeedProvider(query).notifier)
                                  .loadMore(),
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
          ),

          // Floating Active Explorer Field HUD (User's Rank & Standing)
          if (myEntry != null || myRank != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: _ActiveExplorerFieldHUD(
                entry: myEntry,
                myRank: myRank,
                fallbackName: currentUser.displayName,
                fallbackAvatar: currentUser.avatarUrl,
                nearestCompetitor: nearestCompetitor,
                onTapLedger: _scrollToLedger,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Header & Telemetry ──────────────────────────────────────────────────────

class _ExpeditionHeader extends StatelessWidget {
  const _ExpeditionHeader({required this.onOpenLedger});

  final VoidCallback onOpenLedger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _ExpeditionColors.cardBgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: _ExpeditionColors.cardBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: _ExpeditionColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // App Logo Emblem with ambient glow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _ExpeditionColors.cyanGlow.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/teritory_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.explore_rounded,
                  color: _ExpeditionColors.coralFlame,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EXPEDITION ANNALS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: _ExpeditionColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _ExpeditionColors.coralFlame,
                              Color(0xFFE11D48),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ROSTER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'World Wonders & Deep Overland Treks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _ExpeditionColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Ledger Shortcut Button
          GestureDetector(
            onTap: onOpenLedger,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _ExpeditionColors.cardBgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ExpeditionColors.wonderGold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 15,
                    color: _ExpeditionColors.wonderGold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Ledger',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _ExpeditionColors.wonderGold,
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
}

class _ExpeditionTelemetryStrip extends StatelessWidget {
  const _ExpeditionTelemetryStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _ExpeditionColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ExpeditionColors.cardBorder),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ExpeditionColors.emeraldTrail,
                  boxShadow: [
                    BoxShadow(
                      color: _ExpeditionColors.emeraldTrail,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'GPS TELEMETRY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _ExpeditionColors.emeraldTrail,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '7 CONTINENTS • WONDERS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _ExpeditionColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scope Navigator ("Expedition Theater") ──────────────────────────────────

class _ExpeditionScopePills extends StatelessWidget {
  const _ExpeditionScopePills({
    required this.selected,
    required this.onChanged,
  });

  final LeaderboardScope selected;
  final ValueChanged<LeaderboardScope> onChanged;

  static const _labels = {
    LeaderboardScope.global: 'Global Atlas',
    LeaderboardScope.country: 'National Frontier',
    LeaderboardScope.state: 'Regional Sector',
    LeaderboardScope.district: 'Territory Outpost',
    LeaderboardScope.friends: 'Explorer Guild',
    LeaderboardScope.clan: 'Clan Fleet',
    LeaderboardScope.community: 'Vanguard Caravan',
  };

  static const _icons = {
    LeaderboardScope.global: Icons.public_rounded,
    LeaderboardScope.country: Icons.flag_rounded,
    LeaderboardScope.state: Icons.terrain_rounded,
    LeaderboardScope.district: Icons.place_rounded,
    LeaderboardScope.friends: Icons.people_alt_rounded,
    LeaderboardScope.clan: Icons.shield_rounded,
    LeaderboardScope.community: Icons.explore_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
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
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          _ExpeditionColors.coralFlame,
                          Color(0xFFE11D48),
                        ],
                      )
                    : null,
                color: isSelected ? null : _ExpeditionColors.cardBgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _ExpeditionColors.coralFlame
                      : _ExpeditionColors.cardBorder,
                  width: isSelected ? 1.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _ExpeditionColors.coralFlame
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[scope],
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : _ExpeditionColors.cyanGlow,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _labels[scope]!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : _ExpeditionColors.textSecondary,
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

// ─── Time Horizon ("Trek Epoch") ─────────────────────────────────────────────

class _ExpeditionHorizonFilter extends StatelessWidget {
  const _ExpeditionHorizonFilter({
    required this.selected,
    required this.onChanged,
  });

  final LeaderboardPeriod selected;
  final ValueChanged<LeaderboardPeriod> onChanged;

  static const _labels = {
    LeaderboardPeriod.alltime: 'All-Time',
    LeaderboardPeriod.month: 'This Month',
    LeaderboardPeriod.week: 'This Week',
  };

  static const _icons = {
    LeaderboardPeriod.alltime: Icons.hourglass_full_rounded,
    LeaderboardPeriod.month: Icons.nightlight_round,
    LeaderboardPeriod.week: Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _ExpeditionColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ExpeditionColors.cardBorder),
      ),
      child: Row(
        children: LeaderboardPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF0369A1),
                            Color(0xFF0284C7),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _ExpeditionColors.cyanGlow
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[period],
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : _ExpeditionColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _labels[period]!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : _ExpeditionColors.textSecondary,
                        ),
                      ),
                    ],
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

// ─── Geo Filter Bar ──────────────────────────────────────────────────────────

class _ExpeditionGeoFilterBar extends ConsumerWidget {
  const _ExpeditionGeoFilterBar({
    required this.scope,
    required this.facetsAsync,
    required this.country,
    required this.state,
    required this.district,
    required this.clanId,
    required this.communityId,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onDistrictChanged,
    required this.onClanChanged,
    required this.onCommunityChanged,
    required this.onRetryFacets,
  });

  final LeaderboardScope scope;
  final AsyncValue<RankingsFacets> facetsAsync;
  final String? country;
  final String? state;
  final String? district;
  final String? clanId;
  final String? communityId;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onClanChanged;
  final ValueChanged<String?> onCommunityChanged;
  final VoidCallback onRetryFacets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scope == LeaderboardScope.community) {
      final communitiesAsync = ref.watch(myCommunitiesProvider);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: communitiesAsync.when(
          loading: () => const LinearProgressIndicator(
            minHeight: 2,
            color: _ExpeditionColors.cyanGlow,
            backgroundColor: _ExpeditionColors.cardBg,
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (communities) {
            if (communities.isEmpty) return const SizedBox.shrink();
            return _buildDropdownContainer(
              icon: Icons.explore_rounded,
              iconColor: _ExpeditionColors.cyanGlow,
              label: 'Caravan',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  dropdownColor: _ExpeditionColors.cardBgElevated,
                  value: communities.any((c) => c.id == communityId)
                      ? communityId
                      : null,
                  isExpanded: true,
                  hint: Text(
                    'All Caravan Communities',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: _ExpeditionColors.textSecondary,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Caravan Communities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _ExpeditionColors.textPrimary,
                        ),
                      ),
                    ),
                    ...communities.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: _ExpeditionColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: onCommunityChanged,
                ),
              ),
            );
          },
        ),
      );
    }

    if (scope == LeaderboardScope.clan) {
      final clansAsync = ref.watch(clansProvider);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: clansAsync.when(
          loading: () => const LinearProgressIndicator(
            minHeight: 2,
            color: TeritoryColors.clanPurple,
            backgroundColor: _ExpeditionColors.cardBg,
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) {
            final myClans = data.myClans;
            if (myClans.isEmpty) return const SizedBox.shrink();
            return _buildDropdownContainer(
              icon: Icons.shield_rounded,
              iconColor: TeritoryColors.clanPurple,
              label: 'Fleet',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  dropdownColor: _ExpeditionColors.cardBgElevated,
                  value: myClans.any((c) => c.id == clanId) ? clanId : null,
                  isExpanded: true,
                  hint: Text(
                    'All Clan Fleets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: _ExpeditionColors.textSecondary,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Clan Fleets',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _ExpeditionColors.textPrimary,
                        ),
                      ),
                    ),
                    ...myClans.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: _ExpeditionColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: onClanChanged,
                ),
              ),
            );
          },
        ),
      );
    }

    final isGeoScope = scope == LeaderboardScope.country ||
        scope == LeaderboardScope.state ||
        scope == LeaderboardScope.district;
    if (!isGeoScope) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: facetsAsync.when(
        loading: () => const LinearProgressIndicator(
          minHeight: 2,
          color: _ExpeditionColors.cyanGlow,
          backgroundColor: _ExpeditionColors.cardBg,
        ),
        error: (_, _) => Row(
          children: [
            Expanded(
              child: Text(
                'Could not locate terrestrial sectors.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _ExpeditionColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetryFacets,
              child: const Text('Re-scan'),
            ),
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
              ? 'Nation'
              : scope == LeaderboardScope.state
                  ? 'Sector'
                  : 'Outpost';
          final onChanged = scope == LeaderboardScope.country
              ? onCountryChanged
              : scope == LeaderboardScope.state
                  ? onStateChanged
                  : onDistrictChanged;

          if (options.isEmpty) {
            return Text(
              'No $label data stamped in the expedition annals yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _ExpeditionColors.textSecondary,
              ),
            );
          }

          return _buildDropdownContainer(
            icon: Icons.navigation_rounded,
            iconColor: _ExpeditionColors.coralFlame,
            label: label,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: _ExpeditionColors.cardBgElevated,
                key: ValueKey('$label-${options.length}'),
                value: options.contains(selected) ? selected : null,
                isExpanded: true,
                hint: Text(
                  'Select $label',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: _ExpeditionColors.textSecondary,
                  ),
                ),
                items: options
                    .map((opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(
                            opt,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: _ExpeditionColors.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownContainer({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: _ExpeditionColors.cardBgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ExpeditionColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _ExpeditionColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── The Grand Expedition Vanguard (Ranks 1, 2, 3) ───────────────────────────

class _GrandExpeditionVanguard extends StatelessWidget {
  const _GrandExpeditionVanguard({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? rank1, rank2, rank3;
    for (final entry in top3) {
      if (entry.rank == 1) rank1 = entry;
      if (entry.rank == 2) rank2 = entry;
      if (entry.rank == 3) rank3 = entry;
    }

    if (rank1 == null && rank2 == null && rank3 == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(
              Icons.military_tech_rounded,
              color: _ExpeditionColors.wonderGold,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'GRAND EXPEDITION VANGUARD',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: _ExpeditionColors.wonderGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Rank 1: Apex Voyager Hero Card
        if (rank1 != null) _ApexVoyagerCard(entry: rank1),

        // Ranks 2 & 3: Senior Navigators Flanking Grid
        if (rank2 != null || rank3 != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (rank2 != null)
                Expanded(
                  child: _VanguardOfficerCard(
                    entry: rank2,
                    rankNumber: 2,
                    title: 'MASTER NAVIGATOR',
                    accentColor: _ExpeditionColors.silverMist,
                    borderGradient: const [
                      _ExpeditionColors.silverMist,
                      Color(0xFF64748B),
                    ],
                  ),
                ),
              if (rank2 != null && rank3 != null) const SizedBox(width: 10),
              if (rank3 != null)
                Expanded(
                  child: _VanguardOfficerCard(
                    entry: rank3,
                    rankNumber: 3,
                    title: 'VANGUARD PIONEER',
                    accentColor: _ExpeditionColors.bronzeRidge,
                    borderGradient: const [
                      Color(0xFFE8A862),
                      _ExpeditionColors.bronzeRidge,
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Rank 1 Apex Voyager Card ────────────────────────────────────────────────

class _ApexVoyagerCard extends StatelessWidget {
  const _ApexVoyagerCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2838),
            Color(0xFF0F1B2F),
            Color(0xFF0B1424),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ExpeditionColors.wonderGold.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _ExpeditionColors.wonderGold.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background celestial watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.public_rounded,
                size: 160,
                color: _ExpeditionColors.wonderGold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tagline Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            _ExpeditionColors.wonderGold,
                            Color(0xFFD97706),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 14,
                            color: Color(0xFF0B1322),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'APEX TRAILBLAZER #1',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: const Color(0xFF0B1322),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 14,
                          color: _ExpeditionColors.cyanGlow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GLOBAL SOVEREIGN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: _ExpeditionColors.cyanGlow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Explorer Avatar & Profile Row
                Row(
                  children: [
                    // Avatar with double concentric compass rings
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ExpeditionColors.wonderGold
                                  .withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        _ExpeditionAvatar(
                          url: entry.userAvatar,
                          name: entry.userName,
                          radius: 28,
                          borderColor: _ExpeditionColors.wonderGold,
                          borderWidth: 2.5,
                          shadowColor: _ExpeditionColors.wonderGold,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: _ExpeditionColors.wonderGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFF0B1322),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Explorer Identity & Merit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: _ExpeditionColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                entry.userHandle.startsWith('@')
                                    ? entry.userHandle
                                    : '@${entry.userHandle}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _ExpeditionColors.cyanGlow,
                                ),
                              ),
                              if (entry.country.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _ExpeditionColors.textMuted,
                                  ),
                                ),
                                Text(
                                  entry.country,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: _ExpeditionColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _ExpeditionColors.wonderGold
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _ExpeditionColors.wonderGold
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  size: 14,
                                  color: _ExpeditionColors.wonderGold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_formatScore(entry.compositeScore)} MERIT',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: _ExpeditionColors.wonderGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4-Cell Telemetry Grid
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _ExpeditionColors.cardBgElevated
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ExpeditionColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildMiniTelemetry(
                        icon: Icons.star_rounded,
                        iconColor: _ExpeditionColors.wonderGold,
                        value: '${entry.majorFlags}',
                        label: 'Wonders',
                      ),
                      _buildDivider(),
                      _buildMiniTelemetry(
                        icon: Icons.flag_rounded,
                        iconColor: _ExpeditionColors.coralFlame,
                        value: '${entry.totalFlags}',
                        label: 'Flags',
                      ),
                      _buildDivider(),
                      _buildMiniTelemetry(
                        icon: Icons.public_rounded,
                        iconColor: _ExpeditionColors.cyanGlow,
                        value: '${entry.countriesVisited}',
                        label: 'Nations',
                      ),
                      _buildDivider(),
                      _buildMiniTelemetry(
                        icon: Icons.route_rounded,
                        iconColor: _ExpeditionColors.emeraldTrail,
                        value: '${entry.completedTrips}',
                        label: 'Treks',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTelemetry({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ExpeditionColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: _ExpeditionColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      color: _ExpeditionColors.cardBorder,
    );
  }
}

// ─── Vanguard Officer Card (Ranks 2 and 3) ───────────────────────────────────

class _VanguardOfficerCard extends StatelessWidget {
  const _VanguardOfficerCard({
    required this.entry,
    required this.rankNumber,
    required this.title,
    required this.accentColor,
    required this.borderGradient,
  });

  final LeaderboardEntry entry;
  final int rankNumber;
  final String title;
  final Color accentColor;
  final List<Color> borderGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ExpeditionColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#0$rankNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _ExpeditionColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Avatar and Name
          Row(
            children: [
              _ExpeditionAvatar(
                url: entry.userAvatar,
                name: entry.userName,
                radius: 19,
                borderColor: accentColor,
                borderWidth: 1.8,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ExpeditionColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.userHandle.startsWith('@')
                          ? entry.userHandle
                          : '@${entry.userHandle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: _ExpeditionColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Core Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: _ExpeditionColors.wonderGold,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.majorFlags}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _ExpeditionColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.flag_rounded,
                    size: 12,
                    color: _ExpeditionColors.coralFlame,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.totalFlags}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _ExpeditionColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_formatScore(entry.compositeScore)} pts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Explorer Field Log Tile (Ranks 4+) ───────────────────────────────────────

class _ExplorerFieldLogTile extends StatelessWidget {
  const _ExplorerFieldLogTile({required this.entry});

  final LeaderboardEntry entry;

  String _deriveExplorerTitle(LeaderboardEntry e) {
    if (e.majorFlags >= 5) return '🏛️ Wonder Surveyor';
    if (e.continentsExplored >= 3) return '🌍 Continental Nomad';
    if (e.totalFlags >= 25) return '🚩 Master Cartographer';
    if (e.completedTrips >= 5) return '🧭 Highland Pioneer';
    if (e.streakDays >= 7) return '🔥 Trail Survivor';
    if (e.rank <= 10) return '⭐ Frontier Scout';
    return '🏕️ Pathfinder';
  }

  @override
  Widget build(BuildContext context) {
    final title = _deriveExplorerTitle(entry);
    final isTop10 = entry.rank <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _ExpeditionColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop10
              ? _ExpeditionColors.cyanGlow.withValues(alpha: 0.3)
              : _ExpeditionColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Waypoint Rank Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isTop10
                  ? _ExpeditionColors.cyanGlow.withValues(alpha: 0.12)
                  : _ExpeditionColors.cardBgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTop10
                    ? _ExpeditionColors.cyanGlow.withValues(alpha: 0.35)
                    : _ExpeditionColors.cardBorder,
              ),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isTop10
                      ? _ExpeditionColors.cyanGlow
                      : _ExpeditionColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Explorer Avatar
          _ExpeditionAvatar(
            url: entry.userAvatar,
            name: entry.userName,
            radius: 20,
            borderColor: isTop10
                ? _ExpeditionColors.cyanGlow.withValues(alpha: 0.5)
                : _ExpeditionColors.cardBorder,
          ),
          const SizedBox(width: 12),

          // Explorer Details & Telemetry
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _ExpeditionColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _ExpeditionColors.cardBgElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _ExpeditionColors.wonderGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.userHandle.startsWith('@')
                      ? entry.userHandle
                      : '@${entry.userHandle}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _ExpeditionColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),

                // Explorer Telemetry Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ExpeditionBadge(
                      icon: Icons.flag_rounded,
                      label: '${entry.totalFlags}',
                      color: _ExpeditionColors.coralFlame,
                    ),
                    if (entry.majorFlags > 0)
                      _ExpeditionBadge(
                        icon: Icons.star_rounded,
                        label: '${entry.majorFlags}',
                        color: _ExpeditionColors.wonderGold,
                      ),
                    if (entry.countriesVisited > 0)
                      _ExpeditionBadge(
                        icon: Icons.public_rounded,
                        label: '${entry.countriesVisited}C',
                        color: _ExpeditionColors.cyanGlow,
                      ),
                    if (entry.completedTrips > 0)
                      _ExpeditionBadge(
                        icon: Icons.route_rounded,
                        label: '${entry.completedTrips}T',
                        color: _ExpeditionColors.emeraldTrail,
                      ),
                    if (entry.streakDays > 0)
                      _ExpeditionBadge(
                        icon: Icons.bolt_rounded,
                        label: '${entry.streakDays}d',
                        color: _ExpeditionColors.wonderGold,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Merit Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatScore(entry.compositeScore),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isTop10
                      ? _ExpeditionColors.cyanGlow
                      : _ExpeditionColors.textPrimary,
                ),
              ),
              Text(
                'MERIT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _ExpeditionColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpeditionBadge extends StatelessWidget {
  const _ExpeditionBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Explorer Field HUD (Sticky Floating Bar) ─────────────────────────

class _ActiveExplorerFieldHUD extends StatelessWidget {
  const _ActiveExplorerFieldHUD({
    required this.entry,
    required this.myRank,
    required this.fallbackName,
    required this.fallbackAvatar,
    required this.onTapLedger,
    this.nearestCompetitor,
  });

  final LeaderboardEntry? entry;
  final MyRank? myRank;
  final String fallbackName;
  final String fallbackAvatar;
  final VoidCallback onTapLedger;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _ExpeditionColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ExpeditionColors.cyanGlow.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _ExpeditionColors.cyanGlow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          // Personal Waypoint Rank Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _ExpeditionColors.coralFlame,
                  Color(0xFFE11D48),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _ExpeditionColors.coralFlame.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
          const SizedBox(width: 10),

          // Avatar
          _ExpeditionAvatar(
            url: avatar,
            name: name,
            radius: 18,
            borderColor: _ExpeditionColors.cyanGlow,
            borderWidth: 1.5,
          ),
          const SizedBox(width: 10),

          // Standing and Proximity Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'FIELD STANDING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _ExpeditionColors.cyanGlow,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _ExpeditionColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (nearestCompetitor != null && gap > 0)
                  Text(
                    '📍 ${_formatScore(gap)} merit to catch ${nearestCompetitor!.userName.split(' ').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _ExpeditionColors.wonderGold,
                    ),
                  )
                else if (rank == 1)
                  Text(
                    '⭐ Apex Trailblazer — Leading World Expedition',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _ExpeditionColors.wonderGold,
                    ),
                  )
                else
                  Text(
                    'Verified on the Global Overland Trail',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: _ExpeditionColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Total Merit Score + Tap to view Ledger
          GestureDetector(
            onTap: onTapLedger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatScore(score),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ExpeditionColors.wonderGold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MERIT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: _ExpeditionColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 8,
                      color: _ExpeditionColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expedition Ledger & Scoring Formula ──────────────────────────────────────

class _ExpeditionLedgerSection extends StatelessWidget {
  const _ExpeditionLedgerSection({
    required this.myRankAsync,
    required this.isExpanded,
    required this.onToggle,
    required this.onRetry,
  });

  final AsyncValue<MyRank> myRankAsync;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRetry;

  static const _labels = <String, (String, String, IconData, Color)>{
    'majorFlagsPoints': (
      'World Wonder Conquests',
      'High-altitude summits, UNESCO heritage sites & iconic wonders',
      Icons.military_tech_rounded,
      _ExpeditionColors.wonderGold,
    ),
    'flagsPoints': (
      'Territorial Flags Staked',
      'Backcountry viewpoints, campsites, secret coastal spots',
      Icons.flag_rounded,
      _ExpeditionColors.coralFlame,
    ),
    'countriesPoints': (
      'Sovereign Frontiers Crossings',
      'Nations and sovereign territories explored',
      Icons.public_rounded,
      _ExpeditionColors.cyanGlow,
    ),
    'continentsPoints': (
      'Intercontinental Treks',
      'Deep exploration across the 7 world continents',
      Icons.explore_rounded,
      TeritoryColors.communityIndigo,
    ),
    'tripsPoints': (
      'Overland Expeditions Completed',
      'Multi-waypoint journeys navigated from start to summit',
      Icons.route_rounded,
      _ExpeditionColors.emeraldTrail,
    ),
    'ralliesPoints': (
      'Legendary Survival Rallies',
      'Extreme terrain rallies and clan expedition events',
      Icons.bolt_rounded,
      _ExpeditionColors.wonderGold,
    ),
    'stampsPoints': (
      'Verified Passport Seals',
      'Geofenced biometric & GPS passport stamp validations',
      Icons.verified_rounded,
      _ExpeditionColors.emeraldTrail,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final myRank = myRankAsync.valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: _ExpeditionColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ExpeditionColors.wonderGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          // Header Row (Click to Expand / Collapse)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _ExpeditionColors.wonderGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _ExpeditionColors.wonderGold
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: _ExpeditionColors.wonderGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPEDITION MERIT LEDGER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _ExpeditionColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'How the exploration engine measures your global journey',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _ExpeditionColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _ExpeditionColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Detail Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    height: 1,
                    color: _ExpeditionColors.cardBorder,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _ExpeditionColors.cardBgElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.terrain_rounded,
                          size: 16,
                          color: _ExpeditionColors.cyanGlow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Boots on the ground. Staked flags, UNESCO ruins, high summits and wild frontiers calculate your standing.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              height: 1.4,
                              color: _ExpeditionColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (myRankAsync.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: _ExpeditionColors.wonderGold,
                        ),
                      ),
                    )
                  else if (myRankAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Could not synchronize ledger breakdown.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: _ExpeditionColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text('Re-evaluate'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (myRank != null) ...[
                    for (final entry in _labels.entries)
                      if (myRank.breakdown.containsKey(entry.key))
                        _LedgerRow(
                          icon: entry.value.$3,
                          title: entry.value.$1,
                          subtitle: entry.value.$2,
                          value: myRank.breakdown[entry.key]!,
                          color: entry.value.$4,
                        ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F223D),
                            Color(0xFF142E52),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ExpeditionColors.cyanGlow
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 18,
                                color: _ExpeditionColors.wonderGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TOTAL COMPOSITE MERIT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_formatScore(myRank.score)} PTS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: _ExpeditionColors.wonderGold,
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
            duration: const Duration(milliseconds: 260),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _ExpeditionColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: _ExpeditionColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatars & Status Indicators ─────────────────────────────────────────────

class _ExpeditionAvatar extends StatelessWidget {
  const _ExpeditionAvatar({
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
                  color: shadowColor!.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _ExpeditionColors.cardBgElevated,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        onBackgroundImageError: url.isNotEmpty ? (_, _) {} : null,
        child: url.isEmpty
            ? Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.w900,
                  color: _ExpeditionColors.textSecondary,
                ),
              )
            : null,
      ),
    );
  }
}

class _ExpeditionLoadingRadar extends StatelessWidget {
  const _ExpeditionLoadingRadar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _ExpeditionColors.cyanGlow,
                backgroundColor: _ExpeditionColors.cardBorder,
              ),
            ),
            const Icon(
              Icons.explore_rounded,
              size: 24,
              color: _ExpeditionColors.coralFlame,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'CONNECTING TO EXPEDITION SATELLITE...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: _ExpeditionColors.cyanGlow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Calculating world footprints & wonder points',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: _ExpeditionColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ExpeditionEmptyState extends StatelessWidget {
  const _ExpeditionEmptyState({
    required this.scope,
    required this.period,
  });

  final LeaderboardScope scope;
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _ExpeditionColors.cardBgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: _ExpeditionColors.cardBorder),
              ),
              child: const Icon(
                Icons.explore_off_rounded,
                size: 48,
                color: _ExpeditionColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Uncharted Expedition Sector',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ExpeditionColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No explorer logs stamped in this theater yet.\nStake the first territorial flag, conquer a world wonder, or complete a backcountry trek to claim this region.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _ExpeditionColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpeditionMissingFilterState extends StatelessWidget {
  const _ExpeditionMissingFilterState({required this.missing});

  final String missing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 40,
              color: _ExpeditionColors.cyanGlow,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a $missing sector to inspect its expedition annals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: _ExpeditionColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpeditionErrorState extends StatelessWidget {
  const _ExpeditionErrorState({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(
              Icons.satellite_alt_rounded,
              size: 44,
              color: _ExpeditionColors.coralFlame,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _ExpeditionColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Re-link Telemetry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ExpeditionColors.cyanGlow,
                side: const BorderSide(color: _ExpeditionColors.cyanGlow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpeditionPagingFooter extends StatelessWidget {
  const _ExpeditionPagingFooter({
    required this.feed,
    required this.onLoadMore,
  });

  final LeaderboardFeedState feed;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (feed.loadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ExpeditionColors.cyanGlow,
            ),
          ),
        ),
      );
    }

    if (feed.loadMoreError != null) {
      return Column(
        children: [
          Text(
            feed.loadMoreError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _ExpeditionColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: onLoadMore,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (!feed.hasMore) return const SizedBox.shrink();

    return Center(
      child: OutlinedButton.icon(
        onPressed: onLoadMore,
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        label: Text(
          'Scan further into territory (${feed.entries.length} of ${feed.total})',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ExpeditionColors.cyanGlow,
          side: const BorderSide(color: _ExpeditionColors.cardBorder),
        ),
      ),
    );
  }
}

// ─── Number Formatter ────────────────────────────────────────────────────────

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
