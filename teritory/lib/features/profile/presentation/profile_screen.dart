import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/teritory_data_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/flag_detail_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final MapController _profileMapController;
  String _activeTab = 'All Flags';

  @override
  void initState() {
    super.initState();
    _profileMapController = MapController();
  }

  @override
  void dispose() {
    _profileMapController.dispose();
    super.dispose();
  }

  void _zoomToRegion(LatLng center, double zoom) {
    _profileMapController.move(center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TeritoryDataService.instance,
      builder: (context, _) {
        final dataService = TeritoryDataService.instance;
        if (!dataService.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: TeritoryColors.primary),
            ),
          );
        }

        final user = dataService.currentUser;
        final allFlags = dataService.userFlags;
        final majorFlags = dataService.majorFlags;

        // Determine displayed flags based on filter
        final displayedFlags = _activeTab == 'Major Flags Only'
            ? majorFlags
            : _activeTab == 'Asia'
                ? allFlags.where((f) => f.continent == 'Asia').toList()
                : _activeTab == 'Europe'
                    ? allFlags.where((f) => f.continent == 'Europe').toList()
                    : allFlags;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.public_rounded,
                    color: TeritoryColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Traveler Footprint',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing your global travel passport!'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Traveler Header Card ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: TeritoryColors.majorGold,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(user.avatar),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: TeritoryColors.majorGoldDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.military_tech_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: TeritoryColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded,
                                    color: TeritoryColors.sapphireBlue, size: 16),
                              ],
                            ),
                            Text(
                              user.handle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: TeritoryColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: TeritoryColors.majorGoldLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rank: ${user.nomadRank} • Lvl ${user.nomadLevel}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: TeritoryColors.majorGoldDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    user.bio,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Prominent Stats Row (Major Flags Highlighted) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Major Flags Card (Golden Hero)
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: TeritoryColors.majorGold, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    TeritoryColors.majorGold.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.military_tech_rounded,
                                      color: TeritoryColors.majorGoldDark,
                                      size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MAJOR FLAGS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: TeritoryColors.majorGoldDark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user.stats.majorFlags}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: TeritoryColors.majorGoldDark,
                                ),
                              ),
                              Text(
                                'Iconic Tourist Wonders',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: TeritoryColors.majorGoldDark
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Total Flags
                      Expanded(
                        flex: 4,
                        child: _buildStatCard(
                          '${user.stats.totalFlags}',
                          'Total Flags',
                          'Claimed Footprints',
                          Icons.flag_rounded,
                          TeritoryColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Continents & Countries
                      Expanded(
                        flex: 4,
                        child: _buildStatCard(
                          '${user.stats.continentsVisited} / ${user.stats.countriesVisited}',
                          'Continents/Ctys',
                          'Global Reach',
                          Icons.travel_explore_rounded,
                          TeritoryColors.sapphireBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Global Footprint Map View (All flags of person in one view) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded,
                          size: 18, color: TeritoryColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Worldwide Flag Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${allFlags.length} spots across 3 continents',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Map Viewport Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: TeritoryColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _profileMapController,
                            options: const MapOptions(
                              initialCenter: LatLng(30.0, 50.0), // Broad Eurasian view
                              initialZoom: 2.2,
                              minZoom: 1.5,
                              maxZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.onway.teritory',
                              ),
                              MarkerLayer(
                                markers: allFlags.map((flag) {
                                  return Marker(
                                    point: flag.coordinates,
                                    width: 32,
                                    height: 32,
                                    child: GestureDetector(
                                      onTap: () => FlagDetailSheet.show(
                                        context,
                                        userFlag: flag,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: flag.isMajorFlag
                                              ? TeritoryColors.majorGold
                                              : TeritoryColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          flag.isMajorFlag
                                              ? Icons.military_tech_rounded
                                              : Icons.flag_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),

                          // Quick Zoom Buttons (Continent presets)
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMapPresetChip(
                                    '🌍 World',
                                    () => _zoomToRegion(
                                        const LatLng(25, 40), 1.8),
                                  ),
                                  _buildMapPresetChip(
                                    '🇮🇳 India / Asia',
                                    () => _zoomToRegion(
                                        const LatLng(20, 78), 4.2),
                                  ),
                                  _buildMapPresetChip(
                                    '🇪🇺 Europe',
                                    () => _zoomToRegion(
                                        const LatLng(48, 12), 4.0),
                                  ),
                                  _buildMapPresetChip(
                                    '🇦🇪 Middle East',
                                    () => _zoomToRegion(
                                        const LatLng(25, 55), 5.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Passport Stamps Shelf ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          size: 18, color: TeritoryColors.majorGoldDark),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Passport Stamps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${user.passportStamps.length} Stamps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TeritoryColors.majorGoldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Stamp Badges Horizontal Scroll
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: user.passportStamps.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, index) {
                      final stamp = user.passportStamps[index];
                      return Container(
                        width: 140,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TeritoryColors.majorGold.withValues(alpha: 0.5),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: TeritoryColors.majorGoldLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.stars_rounded,
                                      size: 14,
                                      color: TeritoryColors.majorGoldDark),
                                ),
                                const Spacer(),
                                Text(
                                  stamp.date,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: TeritoryColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              stamp.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: TeritoryColors.textPrimary,
                              ),
                            ),
                            Text(
                              stamp.category,
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
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // ── Filter Tabs for Flagged Locations ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab(
                            'All Flags (${allFlags.length})', 'All Flags'),
                        _buildFilterTab(
                            'Major Wonders (${majorFlags.length})',
                            'Major Flags Only'),
                        _buildFilterTab('Asia', 'Asia'),
                        _buildFilterTab('Europe', 'Europe'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Flag List Cards ──
                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayedFlags.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final flag = displayedFlags[index];
                    return GestureDetector(
                      onTap: () => FlagDetailSheet.show(context, userFlag: flag),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGold.withValues(alpha: 0.6)
                                : TeritoryColors.border,
                            width: flag.isMajorFlag ? 1.5 : 1.0,
                          ),
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
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                flag.photoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 72,
                                  height: 72,
                                  color: TeritoryColors.surfaceContainer,
                                  child: const Icon(Icons.image,
                                      color: TeritoryColors.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Flag Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (flag.isMajorFlag)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: TeritoryColors.majorGoldLight,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'MAJOR',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: TeritoryColors.majorGoldDark,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        flag.category,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: TeritoryColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    flag.placeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: TeritoryColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${flag.city}, ${flag.country} • ${flag.flaggedDate}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: TeritoryColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: TeritoryColors.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: TeritoryColors.textPrimary,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: TeritoryColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: TeritoryColors.surfaceDark,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : TeritoryColors.textPrimary,
        ),
        side: BorderSide(
          color: isSelected ? TeritoryColors.surfaceDark : TeritoryColors.border,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeTab = tabKey;
            });
          }
        },
      ),
    );
  }
}
