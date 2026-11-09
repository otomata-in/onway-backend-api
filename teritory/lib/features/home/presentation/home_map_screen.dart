import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/teritory_models.dart';
import '../../../core/services/teritory_data_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/drop_flag_modal.dart';
import '../../flag/presentation/flag_detail_sheet.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  final LatLng _currentLocation = const LatLng(9.9790, 76.2760); // Kochi center
  String _selectedFilter = 'All';
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

  void _openDropFlag() {
    DropFlagModal.show(
      context,
      coordinates: _currentLocation,
      suggestedPlaceName: 'Marine Drive Waterfront, Kochi',
    );
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

        final userFlags = dataService.userFlags;
        final friendFlags = dataService.friendFlags;

        // Apply filter
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

        // 2. User Flagged Pins
        if (_selectedFilter == 'All' || _selectedFilter == 'My Flags') {
          for (final flag in userFlags) {
            markers.add(
              Marker(
                point: flag.coordinates,
                width: 130,
                height: 70,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => FlagDetailSheet.show(context, userFlag: flag),
                  child: _buildUserFlagPin(flag),
                ),
              ),
            );
          }
        }

        // 3. Friend Flags Pins
        if (_selectedFilter == 'All' ||
            _selectedFilter == 'Friends' ||
            _selectedFilter == 'Major Wonders') {
          for (final fFlag in friendFlags) {
            if (_selectedFilter == 'Major Wonders' && !fFlag.isMajorFlag) {
              continue;
            }
            markers.add(
              Marker(
                point: fFlag.coordinates,
                width: 140,
                height: 75,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () =>
                      FlagDetailSheet.show(context, friendFlag: fFlag),
                  child: _buildFriendFlagPin(fFlag),
                ),
              ),
            );
          }
        }

        return Scaffold(
          body: Stack(
            children: [
              // ── Interactive Map Canvas (OSM) ──
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
                          Colors.black.withValues(alpha: 0.45),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: TeritoryColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'TERITORY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: TeritoryColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: TeritoryColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_rounded,
                                      size: 14, color: TeritoryColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${friendFlags.length} Friends Active',
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

              // ── Right Side Quick Navigation Buttons ──
              Positioned(
                right: 16,
                bottom: 160,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: TeritoryColors.textPrimary,
                      elevation: 4,
                      onPressed: _recenterToUser,
                      child: const Icon(Icons.my_location_rounded),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_in_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: TeritoryColors.textPrimary,
                      elevation: 4,
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
                      backgroundColor: Colors.white,
                      foregroundColor: TeritoryColors.textPrimary,
                      elevation: 4,
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
                      return GestureDetector(
                        onTap: () {
                          _mapController.move(f.coordinates, 14.5);
                          FlagDetailSheet.show(context, friendFlag: f);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: f.isMajorFlag
                                  ? TeritoryColors.majorGold
                                  : Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
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
                                          color: TeritoryColors.textPrimary,
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
                                      color: TeritoryColors.textSecondary,
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
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? TeritoryColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                color: isSelected ? Colors.white : TeritoryColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color:
                      isSelected ? Colors.white : TeritoryColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Current Location Pulsing Pin
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
                  color: TeritoryColors.primary.withValues(alpha: opacity * 0.4),
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
                    color: Colors.black.withValues(alpha: 0.25),
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
                color: Colors.black.withValues(alpha: 0.2),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fFlag.isMajorFlag
                  ? TeritoryColors.majorGold
                  : TeritoryColors.sapphireBlue,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                backgroundImage: NetworkImage(fFlag.friendAvatar),
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
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.flag_rounded,
                size: 13,
                color: fFlag.isMajorFlag
                    ? TeritoryColors.majorGold
                    : TeritoryColors.sapphireBlue,
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: fFlag.isMajorFlag
              ? TeritoryColors.majorGold
              : TeritoryColors.sapphireBlue,
        ),
      ],
    );
  }
}
