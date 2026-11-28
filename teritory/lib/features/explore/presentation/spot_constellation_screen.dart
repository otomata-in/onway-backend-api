import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/flag_style.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/flag_style_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';

/// Nested "Imaginary Map View" for a crowded or Major Wonder location.
///
/// Places the primary/Major flag at the center monument and arranges all other
/// travelers' flags in concentric surrounding rings connected by radial lines.
/// Supports full filtering (`All`, `Friends`, `My Flags`, `Major Wonders`),
/// upright rotation, dynamic zoom scaling, and a quick-jump explorer carousel.
class SpotConstellationScreen extends ConsumerStatefulWidget {
  final List<ApiFlag> flags;
  final Set<String> friendIds;

  const SpotConstellationScreen({
    super.key,
    required this.flags,
    this.friendIds = const {},
  });

  static Future<void> open(
    BuildContext context, {
    required List<ApiFlag> flags,
    Set<String> friendIds = const {},
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpotConstellationScreen(
          flags: flags,
          friendIds: friendIds,
        ),
      ),
    );
  }

  @override
  ConsumerState<SpotConstellationScreen> createState() =>
      _SpotConstellationScreenState();
}

class _SpotConstellationScreenState
    extends ConsumerState<SpotConstellationScreen> {
  late final MapController _mapController;
  String _selectedFilter = 'All';
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  double get _flagZoomScale {
    if (_currentZoom >= 16.0) return 1.0;
    return math.pow(0.80, (16.0 - _currentZoom).clamp(0.0, 6.0))
        .toDouble()
        .clamp(0.28, 1.0);
  }

  List<ApiFlag> _filteredFlags(String currentUserId) {
    switch (_selectedFilter) {
      case 'My Flags':
        return widget.flags
            .where((f) => f.isOwnedBy(currentUserId))
            .toList();
      case 'Friends':
        return widget.flags
            .where(
              (f) =>
                  !f.isOwnedBy(currentUserId) &&
                  widget.friendIds.contains(f.userId),
            )
            .toList();
      case 'Major Wonders':
        return widget.flags.where((f) => f.isMajorFlag).toList();
      case 'All':
      default:
        return widget.flags;
    }
  }

  /// Assigns the center monument coordinate to the lead flag and distributes
  /// surrounding flags in clean concentric rings around it.
  List<_PlacedConstellationFlag> _layoutConstellation(
    LatLng center,
    List<ApiFlag> flags,
  ) {
    if (flags.isEmpty) return const [];

    final placed = <_PlacedConstellationFlag>[
      _PlacedConstellationFlag(
        flag: flags.first,
        position: center,
        isCenter: true,
      ),
    ];

    final surrounding = flags.skip(1).toList();
    if (surrounding.isEmpty) return placed;

    // Distribute into concentric rings so even 20+ flags never collide.
    var index = 0;
    var ring = 0;
    while (index < surrounding.length) {
      final capacity = 8 + ring * 6; // Ring 0: 8, Ring 1: 14, Ring 2: 20...
      final remaining = surrounding.length - index;
      final countInRing = math.min(capacity, remaining);
      final radiusDeg = 0.0014 + ring * 0.0012;
      final startAngle = ring * (math.pi / 6);

      for (var i = 0; i < countInRing; i++) {
        final angle = startAngle + (2 * math.pi * i / countInRing);
        // Correct longitude by cos(lat) so the ring looks circular on map tiles.
        final cosLat = math.cos(center.latitude * math.pi / 180).clamp(0.2, 1.0);
        final lat = center.latitude + radiusDeg * math.sin(angle);
        final lng = center.longitude + (radiusDeg / cosLat) * math.cos(angle);
        placed.add(
          _PlacedConstellationFlag(
            flag: surrounding[index],
            position: LatLng(lat, lng),
            isCenter: false,
          ),
        );
        index++;
      }
      ring++;
    }

    return placed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(mapThemeProvider);
    final currentUserId = ref.watch(currentUserProvider).id;
    final lead = widget.flags.first;
    final center = lead.coordinates;
    final visibleFlags = _filteredFlags(currentUserId);
    final placed = _layoutConstellation(center, visibleFlags);
    final friendsCount = widget.flags
        .where(
          (f) =>
              !f.isOwnedBy(currentUserId) &&
              widget.friendIds.contains(f.userId),
        )
        .length;

    // Radial connector lines from surrounding flags to the center monument.
    final connectors = <Polyline>[
      for (final item in placed.where((p) => !p.isCenter))
        Polyline(
          points: [center, item.position],
          strokeWidth: 1.5,
          color: (item.flag.isMajorFlag
                  ? TeritoryColors.majorGold
                  : (widget.friendIds.contains(item.flag.userId)
                      ? TeritoryColors.sapphireBlue
                      : TeritoryColors.primary))
              .withValues(alpha: isDark ? 0.55 : 0.45),
        ),
    ];

    final markers = <Marker>[
      for (final item in placed.reversed)
        Marker(
          point: item.position,
          width: item.isCenter ? 166 : 138,
          height: item.isCenter ? 96 : 78,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => LiveFlagDetailSheet.show(context, flag: item.flag),
            child: _buildConstellationPin(
              item.flag,
              currentUserId: currentUserId,
              isCenter: item.isCenter,
              isDark: isDark,
            ),
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              minZoom: 12.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, _) {
                if ((camera.zoom - _currentZoom).abs() >= 0.04) {
                  setState(() => _currentZoom = camera.zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onway.teritory',
                tileBuilder: isDark
                    ? (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.20, -0.15, -0.30, 0.0, 140,
                            -0.45, 0.20, -0.35, 0.0, 165,
                            -0.55, 0.05, -0.05, 0.0, 185,
                            0.0, 0.0, 0.0, 1.0, 0,
                          ]),
                          child: tileWidget,
                        )
                    : null,
              ),
              if (connectors.isNotEmpty) PolylineLayer(polylines: connectors),
              FlagMotionHost(
                child: MarkerLayer(markers: markers, rotate: true),
              ),
            ],
          ),

          // Top header & Explore-matching filter bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xF21E293B)
                          : Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: isDark
                          ? Border.all(color: const Color(0xFF334155))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 34,
                            height: 34,
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark
                                ? Colors.white
                                : TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${visibleFlags.length} of ${widget.flags.length} flags · Spot Constellation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : TeritoryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: TeritoryColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$friendsCount Friends',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All',
                          Icons.travel_explore_rounded,
                          isDark,
                        ),
                        _buildFilterChip(
                          'Friends',
                          Icons.people_outline_rounded,
                          isDark,
                        ),
                        _buildFilterChip(
                          'My Flags',
                          Icons.flag_outlined,
                          isDark,
                        ),
                        _buildFilterChip(
                          'Major Wonders',
                          Icons.star_outline_rounded,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (visibleFlags.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  'No $_selectedFilter flags at this spot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Re-center to monument button
          Positioned(
            right: 16,
            bottom: 124,
            child: FloatingActionButton.small(
              heroTag: 'constellation_recenter',
              backgroundColor: Colors.white,
              foregroundColor: TeritoryColors.textPrimary,
              onPressed: () => _mapController.move(center, 16.0),
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),

          // Bottom horizontal carousel of explorers at this spot
          if (placed.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 14,
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: placed.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, idx) {
                  final item = placed[idx];
                  final flag = item.flag;
                  return GestureDetector(
                    onTap: () {
                      _mapController.move(item.position, 17.0);
                      LiveFlagDetailSheet.show(context, flag: flag);
                    },
                    child: Container(
                      width: 210,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xF51E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: item.isCenter
                              ? TeritoryColors.majorGold
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : TeritoryColors.border),
                          width: item.isCenter ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: TeritoryColors.border,
                            backgroundImage: flag.authorAvatar.isNotEmpty
                                ? NetworkImage(flag.authorAvatar)
                                : null,
                            child: flag.authorAvatar.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flag.isOwnedBy(currentUserId)
                                      ? '${flag.authorName} (You)'
                                      : flag.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : TeritoryColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isCenter
                                      ? 'Center Monument · ${flag.kudos} kudos'
                                      : '${flag.category} · ${flag.kudos} kudos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: item.isCenter
                                        ? TeritoryColors.majorGoldDark
                                        : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : TeritoryColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          TeritoryFlag(
                            style: flag.flagStyle,
                            width: 28,
                            isMajor: flag.isMajorFlag,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? TeritoryColors.primary
              : (isDark ? const Color(0xF21E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? TeritoryColors.primary
                : (isDark ? const Color(0xFF334155) : TeritoryColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : TeritoryColors.textSecondary),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : TeritoryColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstellationPin(
    ApiFlag flag, {
    required String currentUserId,
    required bool isCenter,
    required bool isDark,
  }) {
    final isMajor = flag.isMajorFlag || isCenter;
    final double flagWidth = isCenter ? 38 : 28;
    final double flagHeight = isCenter ? 48 : 35;
    final double baseWidth = isCenter ? 30 : 20;
    final double poleCenterOffset = flagWidth * (1 - 0.15);
    final FlagStyle style = flag.effectiveStyle(
      currentUserId,
      ref.watch(flagStyleProvider),
    );
    final themeColor = isMajor
        ? TeritoryColors.majorGold
        : FlagStyleCatalog.primaryColor(style);
    final isMine = flag.isOwnedBy(currentUserId);

    return Transform.scale(
      scale: _flagZoomScale,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 9, 3),
            decoration: BoxDecoration(
              gradient: isMajor
                  ? const LinearGradient(
                      colors: [Color(0xFF1C1917), Color(0xFF451A03)],
                    )
                  : LinearGradient(
                      colors: isDark
                          ? const [Color(0xF50F172A), Color(0xF51E293B)]
                          : const [Colors.white, Color(0xFFF8FAFC)],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMajor
                    ? const Color(0xFFFBBF24)
                    : themeColor.withValues(alpha: 0.78),
                width: isMajor ? 1.5 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isMajor
                      ? TeritoryColors.majorGold.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: isMajor ? 10 : 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(1.3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor, width: 1.4),
                  ),
                  child: CircleAvatar(
                    radius: 8.5,
                    backgroundColor: themeColor.withValues(alpha: 0.2),
                    backgroundImage: flag.authorAvatar.isNotEmpty
                        ? NetworkImage(flag.authorAvatar)
                        : null,
                    child: flag.authorAvatar.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 11,
                            color: isMajor ? Colors.white : themeColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                if (isMajor) ...[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: Color(0xFFFEF08A),
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    isCenter
                        ? flag.placeName
                        : (isMine
                            ? 'You'
                            : flag.authorName.split(' ').first),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: isMajor
                          ? const Color(0xFFFEF3C7)
                          : (isDark
                              ? Colors.white
                              : TeritoryColors.textPrimary),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: flagHeight + (isMajor ? 9 : 6),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                FlagTerrainBase(
                  accentColor: themeColor,
                  isMajor: isMajor,
                  width: baseWidth,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: poleCenterOffset,
                    bottom: isMajor ? 7.5 : 5,
                  ),
                  child: FlagPinFlag(
                    style: style,
                    width: flagWidth,
                    height: flagHeight,
                    showPole: true,
                    isMajor: isMajor,
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

class _PlacedConstellationFlag {
  final ApiFlag flag;
  final LatLng position;
  final bool isCenter;

  const _PlacedConstellationFlag({
    required this.flag,
    required this.position,
    required this.isCenter,
  });
}

