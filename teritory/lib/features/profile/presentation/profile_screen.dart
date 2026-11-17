import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../../rankings/application/rankings_provider.dart';
import '../application/profile_providers.dart';
import 'edit_profile_sheet.dart';

/// Live "Traveler Footprint" page: profile, stats and stamps come from
/// `GET /users/me`, the map and flag list from `GET /flags?userId=`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final MapController _profileMapController;
  String _activeTab = 'All';
  bool _isOceanicTheme = true;

  static const String _majorTab = 'Major';

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

  Future<void> _refresh(ApiUser profile) async {
    ref.invalidate(myProfileProvider);
    ref.invalidate(userFlagsProvider(profile.id));
    try {
      await ref.read(myProfileProvider.future);
    } on ApiException {
      // The error state renders the message; refresh just ends here.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

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
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _openEditProfile(profileAsync.valueOrNull),
          ),
          IconButton(
            tooltip: 'Friends',
            icon: const Icon(Icons.people_outline_rounded, size: 20),
            onPressed: () => context.go('/profile/friends'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.go('/profile/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.primary),
        ),
        error: (error, _) => _ProfileErrorState(
          message: error is ApiException
              ? error.message
              : 'Could not load your profile. Check the API and retry.',
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: _buildProfile,
      ),
    );
  }

  Future<void> _openEditProfile(ApiUser? profile) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile is still loading')),
      );
      return;
    }

    final saved = await EditProfileSheet.show(context, profile);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Widget _buildProfile(ApiUser profile) {
    final flagsAsync = ref.watch(userFlagsProvider(profile.id));

    return flagsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TeritoryColors.primary),
      ),
      error: (error, _) => _ProfileErrorState(
        message: error is ApiException
            ? error.message
            : 'Could not load your flags. Check the API and retry.',
        onRetry: () => ref.invalidate(userFlagsProvider(profile.id)),
      ),
      data: (allFlags) => _buildBody(profile, allFlags),
    );
  }

  Widget _buildBody(ApiUser profile, List<ApiFlag> allFlags) {
    final majorFlags = allFlags.where((flag) => flag.isMajorFlag).toList();
    final continents = allFlags.map((flag) => flag.continent).toSet().toList()
      ..sort();

    // Drop a continent tab that no longer exists after a refresh.
    if (_activeTab != 'All' &&
        _activeTab != _majorTab &&
        !continents.contains(_activeTab)) {
      _activeTab = 'All';
    }

    final displayedFlags = switch (_activeTab) {
      'All' => allFlags,
      _majorTab => majorFlags,
      final continent =>
        allFlags.where((flag) => flag.continent == continent).toList(),
    };

    return RefreshIndicator(
      color: TeritoryColors.primary,
      onRefresh: () => _refresh(profile),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 14),
          _StatsRow(profile: profile),
          const SizedBox(height: 12),
          _ProfileBadges(profile: profile),
          const SizedBox(height: 18),
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
                  allFlags.isEmpty
                      ? 'No flags yet'
                      : '${allFlags.length} spots • ${continents.length} continents',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FootprintMap(
              mapController: _profileMapController,
              flags: allFlags,
              isOceanicTheme: _isOceanicTheme,
              onThemeChanged: (isOceanic) =>
                  setState(() => _isOceanicTheme = isOceanic),
              onPreset: _zoomToRegion,
            ),
          ),
          const SizedBox(height: 20),
          _StampsShelf(stamps: profile.passportStamps),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterTab('All Flags (${allFlags.length})', 'All'),
                  _filterTab(
                      'Major Wonders (${majorFlags.length})', _majorTab),
                  for (final continent in continents)
                    _filterTab(
                      '$continent (${allFlags.where((f) => f.continent == continent).length})',
                      continent,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (displayedFlags.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TeritoryColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      allFlags.isEmpty
                          ? Icons.flag_outlined
                          : Icons.filter_alt_off_rounded,
                      size: 40,
                      color: TeritoryColors.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      allFlags.isEmpty
                          ? 'No flags dropped yet'
                          : 'No flags in this filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allFlags.isEmpty
                          ? 'Flags you drop on the Explore map appear here.'
                          : 'Pick another filter to see your other flags.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final flag in displayedFlags) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _FlagListCard(
                  flag: flag,
                  onTap: () => LiveFlagDetailSheet.show(context, flag: flag),
                ),
              ),
            ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _filterTab(String label, String tabKey) {
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
          if (selected) setState(() => _activeTab = tabKey);
        },
      ),
    );
  }
}

// ─── Header & stats ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  backgroundColor: TeritoryColors.surfaceContainer,
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? const Icon(Icons.person_rounded,
                          size: 34, color: TeritoryColors.textMuted)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    Text(
                      '@${profile.handle}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    if (profile.locationLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: TeritoryColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              profile.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: TeritoryColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (profile.isTripMode) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: TeritoryColors.tripRoute.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'On a trip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.bio.trim().isNotEmpty)
            Text(
              profile.bio,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: TeritoryColors.textPrimary,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/profile/friends'),
                  icon: const Icon(Icons.people_outline_rounded, size: 18),
                  label: Text(
                    'Friends',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeritoryColors.textPrimary,
                    side: const BorderSide(color: TeritoryColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/profile/completed-trips'),
                  icon: const Icon(Icons.route_rounded, size: 18),
                  label: Text(
                    'Completed trips',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeritoryColors.textPrimary,
                    side: const BorderSide(color: TeritoryColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}

/// Rank, clan membership and rally count, all from live endpoints. Each chip
/// appears only once its data has arrived, so the row never shows placeholders.
class _ProfileBadges extends ConsumerWidget {
  const _ProfileBadges({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(myRankProvider).valueOrNull;
    final clanCount = ref.watch(myClanCountProvider).valueOrNull;

    final chips = <Widget>[
      if (rank != null && rank.globalRank > 0)
        _badge(
          Icons.emoji_events_rounded,
          'Rank #${rank.globalRank}',
          'of ${rank.totalUsers} travelers',
        ),
      if (clanCount != null && clanCount > 0)
        _badge(
          Icons.shield_rounded,
          '$clanCount',
          clanCount == 1 ? 'clan' : 'clans',
        ),
      if (profile.legendaryRalliesCount > 0)
        _badge(
          Icons.local_fire_department_rounded,
          '${profile.legendaryRalliesCount}',
          profile.legendaryRalliesCount == 1
              ? 'legendary rally'
              : 'legendary rallies',
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _badge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TeritoryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TeritoryColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: TeritoryColors.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final ApiUser profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
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
                border: Border.all(color: TeritoryColors.majorGold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: TeritoryColors.majorGold.withValues(alpha: 0.2),
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
                          color: TeritoryColors.majorGoldDark, size: 18),
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
                    '${profile.majorFlags}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: TeritoryColors.majorGoldDark,
                    ),
                  ),
                  Text(
                    'Iconic tourist wonders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          TeritoryColors.majorGoldDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _StatCard(
              value: '${profile.totalFlags}',
              title: 'Total Flags',
              icon: Icons.flag_rounded,
              color: TeritoryColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _StatCard(
              value:
                  '${profile.continentsVisited} / ${profile.countriesVisited}',
              title: 'Continents/Ctys',
              icon: Icons.travel_explore_rounded,
              color: TeritoryColors.sapphireBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String value;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

// ─── Map ────────────────────────────────────────────────────────────────────

class _FootprintMap extends StatelessWidget {
  const _FootprintMap({
    required this.mapController,
    required this.flags,
    required this.isOceanicTheme,
    required this.onThemeChanged,
    required this.onPreset,
  });

  final MapController mapController;
  final List<ApiFlag> flags;
  final bool isOceanicTheme;
  final ValueChanged<bool> onThemeChanged;
  final void Function(LatLng center, double zoom) onPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
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
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(30.0, 50.0),
                initialZoom: 2.2,
                minZoom: 1.5,
                maxZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onway.teritory',
                  tileBuilder: isOceanicTheme
                      ? (context, tileWidget, tile) => ColorFiltered(
                            colorFilter:
                                const ColorFilter.matrix(<double>[
                              -0.20, -0.15, -0.30, 0.0, 140,
                              -0.45, 0.20, -0.35, 0.0, 165,
                              -0.55, 0.05, -0.05, 0.0, 185,
                              0.0, 0.0, 0.0, 1.0, 0,
                            ]),
                            child: tileWidget,
                          )
                      : null,
                ),
                MarkerLayer(
                  markers: flags.map((flag) {
                    return Marker(
                      point: flag.coordinates,
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () =>
                            LiveFlagDetailSheet.show(context, flag: flag),
                        child: Container(
                          decoration: BoxDecoration(
                            color: flag.isMajorFlag
                                ? TeritoryColors.majorGold
                                : TeritoryColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
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
            if (flags.isEmpty)
              const Center(
                child: Text(
                  'No flags on the map yet',
                  style: TextStyle(color: TeritoryColors.textSecondary),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _themePill('🌊 Oceanic', true, isOceanicTheme, onThemeChanged),
                    _themePill('☀️ Daylight', false, isOceanicTheme, onThemeChanged),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _presetChip('🌍 World',
                        () => onPreset(const LatLng(25, 40), 1.8)),
                    _presetChip('🇮🇳 India / Asia',
                        () => onPreset(const LatLng(20, 78), 4.2)),
                    _presetChip('🇪🇺 Europe',
                        () => onPreset(const LatLng(48, 12), 4.0)),
                    _presetChip('🇦🇪 Middle East',
                        () => onPreset(const LatLng(25, 55), 5.0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themePill(
    String label,
    bool isOceanic,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    final isSelected = selected == isOceanic;
    return GestureDetector(
      onTap: () => onChanged(isOceanic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isOceanic
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFF59E0B))
                : TeritoryColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
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
}

// ─── Stamps ─────────────────────────────────────────────────────────────────

class _StampsShelf extends StatelessWidget {
  const _StampsShelf({required this.stamps});

  final List<ApiPassportStamp> stamps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                '${stamps.length} Stamps',
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
        if (stamps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No stamps yet — they are awarded by the server as you travel.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: TeritoryColors.textMuted,
              ),
            ),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: stamps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final stamp = stamps[index];
                final color = _colorFromHex(stamp.badgeColor);
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
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.stars_rounded,
                                size: 14, color: color),
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
      ],
    );
  }

  static Color _colorFromHex(String value) {
    final hex = value.replaceAll('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return TeritoryColors.majorGold;
    return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}

// ─── Flag list card ─────────────────────────────────────────────────────────

class _FlagListCard extends StatelessWidget {
  const _FlagListCard({required this.flag, required this.onTap});

  final ApiFlag flag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = [flag.city, flag.country]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: flag.photoUrl.isEmpty
                  ? Container(
                      width: 72,
                      height: 72,
                      color: TeritoryColors.surfaceContainer,
                      child: const Icon(Icons.image,
                          color: TeritoryColors.textMuted),
                    )
                  : Image.network(
                      flag.photoUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 72,
                        height: 72,
                        color: TeritoryColors.surfaceContainer,
                        child: const Icon(Icons.image,
                            color: TeritoryColors.textMuted),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (flag.isMajorFlag)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TeritoryColors.majorGoldLight,
                            borderRadius: BorderRadius.circular(6),
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
                    location.isEmpty ? flag.continent : location,
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
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 52, color: TeritoryColors.textMuted),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
