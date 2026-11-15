import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/clan_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class ClanBrowserScreen extends ConsumerStatefulWidget {
  const ClanBrowserScreen({super.key});

  @override
  ConsumerState<ClanBrowserScreen> createState() => _ClanBrowserScreenState();
}

class _ClanBrowserScreenState extends ConsumerState<ClanBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _joinedClans = {'clan1'};

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

  List<Clan> _filterClans(List<Clan> clans) {
    var filtered = clans;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.region.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedCategory == 'Popular') {
      filtered = List.from(filtered)
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } else if (_categoryTags.containsKey(_selectedCategory)) {
      final tags = _categoryTags[_selectedCategory]!;
      filtered = filtered
          .where(
              (c) => tags.any((tag) => c.interestTag.toLowerCase().contains(tag)))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final clans = ref.watch(clansProvider);
    final filteredClans = _filterClans(clans);

    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded,
                color: TeritoryColors.clanPurple, size: 22),
            const SizedBox(width: 8),
            Text(
              'Clans',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: TeritoryColors.textPrimary,
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
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: TeritoryColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 18, color: TeritoryColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Clan list
          Expanded(
            child: filteredClans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: TeritoryColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No clans found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredClans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final clan = filteredClans[index];
                      final isJoined = _joinedClans.contains(clan.id);
                      return _ClanCard(
                        clan: clan,
                        isJoined: isJoined,
                        onTap: () => context.go('/clans/${clan.id}'),
                        onJoinToggle: () {
                          setState(() {
                            if (isJoined) {
                              _joinedClans.remove(clan.id);
                            } else {
                              _joinedClans.add(clan.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Coming soon',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: TeritoryColors.chatBubbleSelf,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
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
    );
  }
}

class _ClanCard extends StatelessWidget {
  final Clan clan;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback onJoinToggle;

  const _ClanCard({
    required this.clan,
    required this.isJoined,
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
                  child: Image.network(
                    clan.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                // Dark gradient overlay
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
                // Clan name on cover
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
                      Icon(Icons.location_on_rounded,
                          size: 14, color: TeritoryColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clan.region,
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
                        onTap: onJoinToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isJoined
                                ? TeritoryColors.surfaceContainer
                                : TeritoryColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
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
