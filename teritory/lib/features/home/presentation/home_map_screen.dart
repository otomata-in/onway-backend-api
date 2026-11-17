import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/api_flag.dart';
import '../../../core/models/teritory_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/teritory_logo.dart';
import '../../explore/application/explore_flags_provider.dart';
import '../../flag/presentation/drop_flag_modal.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  // Single source of truth: the explore query and the marker share one centre.
  static const LatLng _currentLocation = LatLng(
    ExploreFlagsNotifier.centerLat,
    ExploreFlagsNotifier.centerLng,
  );
  String _selectedFilter = 'All';
  bool _isDarkTheme = true; // true: Midnight Oceanic (Teal/Blue/Black mix), false: Daylight White map
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterToUser() {
    _mapController.move(_currentLocation, 13.0);
  }

  Future<void> _openDropFlag() async {
    await DropFlagModal.show(
      context,
      coordinates: _currentLocation,
      suggestedPlaceName: 'Marine Drive Waterfront, Kochi',
    );
    if (!mounted) return;
    // Refresh unconditionally: a flag may have been created even if the sheet was
    // dismissed before it could report success.
    await ref.read(exploreFlagsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final exploreAsync = ref.watch(exploreFlagsProvider);
    final currentUserId = ref.watch(currentUserProvider).id;
    final live = exploreAsync.valueOrNull ??
        const ExploreFlagsData(flags: [], friendIds: <String>{});

    // Filters run against live flags only; ownership and friendship are server
    // facts, not bundled sample data.
    final visible = switch (_selectedFilter) {
      'My Flags' => live.mine(currentUserId),
      'Friends' => live.friends(currentUserId),
      'Major Wonders' => live.major(),
      _ => live.flags,
    };
    final otherFlags =
        visible.where((f) => !f.isOwnedBy(currentUserId)).toList();
    final friendFlags = otherFlags.map((f) => f.toFriendFlag()).toList();
    // Distinct travelers, not flags: one friend with three pins is one person.
    final friendsActiveCount =
        live.friends(currentUserId).map((f) => f.userId).toSet().length;

    List<Marker> markers = [];

    // 1. User Current Location Pulsing Pin
    markers.add(
      Marker(
        point: _currentLocation,
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: _buildCurrentLocationMarker(),
      ),
    );

    // 2. Live flag pins (own pins + other travelers' pins)
    for (final flag in visible) {
      final isMine = flag.isOwnedBy(currentUserId);
      markers.add(
        Marker(
          point: flag.coordinates,
          width: isMine ? 130 : 140,
          height: isMine ? 70 : 75,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => LiveFlagDetailSheet.show(context, flag: flag),
            child: isMine
                ? _buildUserFlagPin(flag.toFlagItem())
                : _buildFriendFlagPin(flag.toFriendFlag()),
          ),
        ),
      );
    }

    return Scaffold(
          body: Stack(
            children: [
              // ── Interactive Map Canvas (100% Free OSM with Classic Dark Mode) ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 12.0,
                  minZoom: 2.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.onway.teritory',
                    tileBuilder: _isDarkTheme
                        ? (context, tileWidget, tile) => ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                -0.20, -0.15, -0.30, 0.0, 140,
                                -0.45,  0.20, -0.35, 0.0, 165,
                                -0.55,  0.05, -0.05, 0.0, 185,
                                 0.0,   0.0,   0.0,  1.0, 0,
                              ]),
                              child: tileWidget,
                            )
                        : null,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // ── Top Gradient Scrim for Readability ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: _isDarkTheme ? 0.65 : 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top Header & Filter Chips ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Header Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isDarkTheme
                              ? const Color(0xF21E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: _isDarkTheme
                              ? Border.all(
                                  color: const Color(0xFF334155), width: 1.0)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            TeritoryLogo(
                              size: 34,
                              showText: true,
                              subtitle: 'FOOTPRINTS',
                              isDark: _isDarkTheme,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isDarkTheme
                                    ? const Color(0xFF0F172A)
                                    : TeritoryColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: _isDarkTheme
                                    ? Border.all(
                                        color: const Color(0xFF334155),
                                        width: 0.8)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_rounded,
                                      size: 14,
                                      color: TeritoryColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$friendsActiveCount Friends Active',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: TeritoryColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', Icons.travel_explore_rounded),
                            _buildFilterChip(
                                'Friends', Icons.people_outline_rounded),
                            _buildFilterChip('My Flags', Icons.flag_outlined),
                            _buildFilterChip(
                                'Major Wonders', Icons.star_border_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Right Side Navigation Buttons ──
              Positioned(
                right: 16,
                bottom: 160,
                child: Column(
                  children: [
                    // Map Theme Selector (Midnight Oceanic / Daylight White Map)
                    FloatingActionButton.small(
                      heroTag: 'theme_toggle_btn',
                      tooltip: _isDarkTheme
                          ? 'Switch to Daylight White Map'
                          : 'Switch to Midnight Oceanic Map',
                      backgroundColor:
                          _isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _isDarkTheme
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFF59E0B),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _isDarkTheme
                            ? const BorderSide(
                                color: Color(0xFF334155), width: 1.0)
                            : BorderSide.none,
                      ),
                      onPressed: () {
                        setState(() {
                          _isDarkTheme = !_isDarkTheme;
                        });
                      },
                      child: Icon(_isDarkTheme
                          ? Icons.water_drop_rounded
                          : Icons.light_mode_rounded),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'recenter_btn',
                      backgroundColor:
                          _isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _isDarkTheme
                          ? Colors.white
                          : TeritoryColors.textPrimary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _isDarkTheme
                            ? const BorderSide(
                                color: Color(0xFF334155), width: 1.0)
                            : BorderSide.none,
                      ),
                      onPressed: _recenterToUser,
                      child: const Icon(Icons.my_location_rounded),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_in_btn',
                      backgroundColor:
                          _isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _isDarkTheme
                          ? Colors.white
                          : TeritoryColors.textPrimary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _isDarkTheme
                            ? const BorderSide(
                                color: Color(0xFF334155), width: 1.0)
                            : BorderSide.none,
                      ),
                      onPressed: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          current + 1,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out_btn',
                      backgroundColor:
                          _isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: _isDarkTheme
                          ? Colors.white
                          : TeritoryColors.textPrimary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _isDarkTheme
                            ? const BorderSide(
                                color: Color(0xFF334155), width: 1.0)
                            : BorderSide.none,
                      ),
                      onPressed: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          current - 1,
                        );
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),

              // ── Bottom Friends Footprint Radar Carousel ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 84,
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: friendFlags.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, index) {
                      final f = friendFlags[index];
                      final apiFlag = otherFlags[index];
                      return GestureDetector(
                        onTap: () {
                          _mapController.move(f.coordinates, 14.5);
                          LiveFlagDetailSheet.show(context, flag: apiFlag);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                          decoration: BoxDecoration(
                            color: _isDarkTheme
                                ? const Color(0xF21E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: f.isMajorFlag
                                  ? TeritoryColors.majorGold
                                  : (_isDarkTheme
                                      ? const Color(0xFF334155)
                                      : Colors.white),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(f.friendAvatar),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        f.friendName.split(' ').first,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isDarkTheme
                                              ? Colors.white
                                              : TeritoryColors.textPrimary,
                                        ),
                                      ),
                                      if (f.isMajorFlag) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded,
                                            size: 14,
                                            color: TeritoryColors.majorGold),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    f.placeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: _isDarkTheme
                                          ? const Color(0xFF94A3B8)
                                          : TeritoryColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Primary Action Button: "Flag Current Teritory" ──
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _openDropFlag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeritoryColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor:
                          TeritoryColors.primary.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_rounded,
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Flag My Teritory Here',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Live data state overlay ──
              if (exploreAsync.isLoading)
                const _MapStatusBanner(
                  icon: Icons.cloud_sync_rounded,
                  message: 'Loading live flags…',
                  color: TeritoryColors.sapphireBlue,
                ),
              if (exploreAsync.hasError)
                _MapStatusBanner(
                  icon: Icons.cloud_off_rounded,
                  message: 'Teritory is unreachable. Check the API and retry.',
                  color: TeritoryColors.expiredRed,
                  onRetry: () =>
                      ref.read(exploreFlagsProvider.notifier).refresh(),
                ),
              if (live.flags.isEmpty &&
                  !exploreAsync.isLoading &&
                  !exploreAsync.hasError)
                const _MapStatusBanner(
                  icon: Icons.flag_outlined,
                  message: 'No flags here yet — be the first to drop one.',
                  color: TeritoryColors.primary,
                ),
            ],
          ),
        );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TeritoryColors.primary
                : (_isDarkTheme ? const Color(0xF21E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: _isDarkTheme && !isSelected
                ? Border.all(color: const Color(0xFF334155), width: 1.0)
                : null,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? TeritoryColors.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (_isDarkTheme ? const Color(0xFFCBD5E1) : TeritoryColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (_isDarkTheme ? const Color(0xFFCBD5E1) : TeritoryColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Current Location Pulsing Pin (Classic Coral Travel Beacon)
  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.4);
        final opacity = 1.0 - _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TeritoryColors.primary.withValues(alpha: opacity * 0.45),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TeritoryColors.primary,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Pin for User's own flagged locations
  Widget _buildUserFlagPin(FlagItem flag) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: flag.isMajorFlag
                ? TeritoryColors.majorGoldDark
                : TeritoryColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                flag.isMajorFlag
                    ? Icons.military_tech_rounded
                    : Icons.flag_rounded,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  flag.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: flag.isMajorFlag
              ? TeritoryColors.majorGoldDark
              : TeritoryColors.primary,
        ),
      ],
    );
  }

  // Pin for Friend's Flagged locations
  Widget _buildFriendFlagPin(FriendFlag fFlag) {
    final pinBg = _isDarkTheme ? const Color(0xF21E293B) : Colors.white;
    final pinBorder = fFlag.isMajorFlag
        ? TeritoryColors.majorGold
        : TeritoryColors.sapphireBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: pinBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pinBorder,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: TeritoryColors.surfaceContainer,
                backgroundImage: fFlag.friendAvatar.isNotEmpty
                    ? NetworkImage(fFlag.friendAvatar)
                    : null,
                child: fFlag.friendAvatar.isEmpty
                    ? const Icon(Icons.person_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  fFlag.friendName.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _isDarkTheme ? Colors.white : TeritoryColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.flag_rounded,
                size: 13,
                color: pinBorder,
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: pinBorder,
        ),
      ],
    );
  }
}

/// Small floating banner used for loading / error / empty states over the map.
class _MapStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onRetry;

  const _MapStatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Right inset clears the map's FAB column (right: 16, bottom: 160) so the
    // banner and its Retry button never sit under those buttons.
    return Positioned(
      left: 16,
      right: 72,
      bottom: 160,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
