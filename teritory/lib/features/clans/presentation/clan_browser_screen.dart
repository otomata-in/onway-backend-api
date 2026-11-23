import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/clan_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../profile/application/profile_providers.dart';
import '../application/clans_provider.dart';
import 'create_clan_sheet.dart';

class ClanBrowserScreen extends ConsumerStatefulWidget {
  const ClanBrowserScreen({super.key});

  @override
  ConsumerState<ClanBrowserScreen> createState() => _ClanBrowserScreenState();
}

class _ClanBrowserScreenState extends ConsumerState<ClanBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _pendingClans = {};
  bool _openingClan = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Nearby',
    'Popular',
    'Nature & Trekking',
    'Heritage & Culture',
    'Road Trips',
    'International',
  ];

  static const Map<String, List<String>> _categoryTags = {
    'Nature & Trekking': ['trekking', 'backpacking', 'camping', 'wildlife'],
    'Heritage & Culture': ['heritage', 'culture', 'temples'],
    'Road Trips': ['road_trip', 'motorcycle', 'driving'],
    'International': ['international'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Clan> _filterClans(List<Clan> clans, {String? userRegion, String? userCountry}) {
    var filtered = clans;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                c.name.toLowerCase().contains(query) ||
                c.region.toLowerCase().contains(query) ||
                c.description.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_selectedCategory == 'Popular') {
      filtered = List.from(filtered)
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } else if (_selectedCategory == 'Nearby') {
      final regionMatch = userRegion?.trim().toLowerCase() ?? '';
      final countryMatch = userCountry?.trim().toLowerCase() ?? '';

      filtered = List.from(filtered)..sort((a, b) {
        final aRegion = a.region.toLowerCase();
        final bRegion = b.region.toLowerCase();

        bool isNear(String r) {
          if (regionMatch.isNotEmpty && r.contains(regionMatch)) return true;
          if (countryMatch.isNotEmpty && r.contains(countryMatch)) return true;
          return r.contains('india') || r.contains('kerala') || r.contains('south') || r.contains('asia');
        }

        final aNear = isNear(aRegion);
        final bNear = isNear(bRegion);
        if (aNear && !bNear) return -1;
        if (!aNear && bNear) return 1;
        return b.memberCount.compareTo(a.memberCount);
      });
    } else if (_categoryTags.containsKey(_selectedCategory)) {
      final tags = _categoryTags[_selectedCategory]!;
      filtered = filtered
          .where(
            (c) => tags.any((tag) => c.interestTag.toLowerCase().contains(tag)),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _toggleMembership(String clanId) async {
    if (_pendingClans.contains(clanId)) return;
    setState(() => _pendingClans.add(clanId));
    try {
      await ref.read(clansProvider.notifier).toggleMembership(clanId);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not reach Teritory. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _pendingClans.remove(clanId));
    }
  }

  Future<void> _openCreateClan() async {
    final clan = await CreateClanSheet.show(context);
    if (!mounted || clan == null) return;
    await _openClan(clan.id);
  }

  /// Guards against a double tap pushing the same detail twice.
  Future<void> _openClan(String clanId) async {
    if (_openingClan) return;
    _openingClan = true;
    try {
      await context.push('/clans/$clanId');
    } finally {
      _openingClan = false;
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clansAsync = ref.watch(clansProvider);
    final data = clansAsync.valueOrNull;
    final myProfile = ref.watch(myProfileProvider).valueOrNull;
    final filteredClans = _filterClans(
      data?.clans ?? const <Clan>[],
      userRegion: myProfile?.state.isNotEmpty == true ? myProfile?.state : myProfile?.district,
      userCountry: myProfile?.country,
    );

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.shield_rounded,
              color: TeritoryColors.clanPurple,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Clans',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (data != null)
              Text(
                '${data.myClans.length} joined',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textMuted,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
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
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: TeritoryColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search clans by name, region...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: TeritoryColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: TeritoryColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: TeritoryColors.textMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Category chips
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TeritoryColors.clanPurple
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? TeritoryColors.clanPurple
                            : TeritoryColors.border,
                      ),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : TeritoryColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Stale-data refresh failure: keep the list, offer a retry.
          if (data != null && clansAsync.hasError)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TeritoryColors.expiredRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: TeritoryColors.expiredRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not refresh clans.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(clansProvider.notifier).refresh(),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.expiredRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Clan list
          Expanded(child: _buildBody(clansAsync, data, filteredClans)),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 96,
        ),
        child: FloatingActionButton.extended(
          onPressed: _openCreateClan,
          backgroundColor: TeritoryColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Create Clan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<ClansData> clansAsync,
    ClansData? data,
    List<Clan> filteredClans,
  ) {
    if (data == null) {
      if (clansAsync.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: TeritoryColors.clanPurple),
        );
      }
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load clans',
        detail: clansAsync.error is ApiException
            ? (clansAsync.error as ApiException).message
            : 'Teritory is unreachable. Check the API and retry.',
        onRetry: () => ref.read(clansProvider.notifier).refresh(),
      );
    }

    if (filteredClans.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        title: _searchQuery.isNotEmpty || _selectedCategory != 'All'
            ? 'No clans match this filter'
            : 'No clans yet',
        detail: 'Founding one takes a name and a region.',
      );
    }

    return RefreshIndicator(
      color: TeritoryColors.clanPurple,
      onRefresh: () => ref.read(clansProvider.notifier).refresh(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).padding.bottom + 140,
        ),
        itemCount: filteredClans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final clan = filteredClans[index];
          return _ClanCard(
            clan: clan,
            isJoined: data.isMember(clan.id),
            isPending: _pendingClans.contains(clan.id),
            onTap: () => _openClan(clan.id),
            onJoinToggle: () => _toggleMembership(clan.id),
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeritoryColors.clanPurple,
                  side: const BorderSide(color: TeritoryColors.clanPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClanCard extends StatelessWidget {
  final Clan clan;
  final bool isJoined;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onJoinToggle;

  const _ClanCard({
    required this.clan,
    required this.isJoined,
    required this.isPending,
    required this.onTap,
    required this.onJoinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TeritoryColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient cover with overlay
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
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
                  child: clan.coverImageUrl.isEmpty
                      ? null
                      : CachedNetworkImage(
                          imageUrl: clan.coverImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox.shrink(),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Text(
                    clan.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: TeritoryColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clan.region.isEmpty ? 'Region not set' : clan.region,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_rounded,
                        label: '${clan.memberCount} members',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.groups_rounded,
                        label: '${clan.communitiesCount} communities',
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: isPending ? null : onJoinToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isJoined
                                ? TeritoryColors.surfaceContainer
                                : TeritoryColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isPending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isJoined ? 'Joined ✓' : 'Join',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isJoined
                                        ? TeritoryColors.textPrimary
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: TeritoryColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
