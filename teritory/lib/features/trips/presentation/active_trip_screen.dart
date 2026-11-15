import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const ActiveTripScreen({super.key, this.tripId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find the active trip
    final trips = MockDataService.instance.activeTrips
        .where((t) => t.status == TripStatus.active)
        .toList();
    final trip = widget.tripId != null
        ? trips.where((t) => t.id == widget.tripId).firstOrNull ?? trips.firstOrNull
        : trips.firstOrNull;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: Center(
          child: Text(
            'No active trip',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Get the associated plan for waypoints
    final plan = MockDataService.instance.tripPlans
        .where((p) => p.id == trip.tripPlanId)
        .firstOrNull;

    final waypoints = plan?.waypoints ?? [];
    final waypointPoints =
        waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();

    // Mock: 2 of the waypoints are validated
    final validatedCount = 2;
    final totalCount = waypoints.length;

    // Current position from first participant
    final currentParticipant = trip.participants.isNotEmpty
        ? trip.participants.first
        : null;
    final currentPos = currentParticipant != null &&
            currentParticipant.currentLat != null &&
            currentParticipant.currentLng != null
        ? LatLng(currentParticipant.currentLat!, currentParticipant.currentLng!)
        : waypointPoints.isNotEmpty
            ? waypointPoints[0]
            : const LatLng(10.0889, 77.0595);

    // Next waypoint is the one after validated ones
    final nextWaypointIndex = validatedCount < waypoints.length ? validatedCount : waypoints.length - 1;
    final nextWaypoint = waypoints.isNotEmpty ? waypoints[nextWaypointIndex] : null;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──
          FlutterMap(
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onway.teritory',
                tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.20, -0.15, -0.30, 0.0, 140,
                    -0.45, 0.20, -0.35, 0.0, 165,
                    -0.55, 0.05, -0.05, 0.0, 185,
                    0.0, 0.0, 0.0, 1.0, 0,
                  ]),
                  child: tileWidget,
                ),
              ),
              if (waypointPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: waypointPoints,
                      strokeWidth: 4.0,
                      color: TeritoryColors.tripRoute,
                    ),
                  ],
                ),
              // Waypoint radius circles (rendered as circle markers)
              CircleLayer(
                circles: waypoints.map((w) {
                  return CircleMarker(
                    point: LatLng(w.latitude, w.longitude),
                    radius: 40,
                    color: TeritoryColors.tripRoute.withValues(alpha: 0.1),
                    borderStrokeWidth: 1.5,
                    borderColor:
                        TeritoryColors.tripRoute.withValues(alpha: 0.4),
                  );
                }).toList(),
              ),
              // Waypoint markers
              MarkerLayer(
                markers: waypoints.map((w) {
                  final isValidated = w.orderIndex < validatedCount;
                  return Marker(
                    point: LatLng(w.latitude, w.longitude),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isValidated
                            ? TeritoryColors.validatedGreen
                            : TeritoryColors.tripRoute,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isValidated
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : Text(
                              '${w.orderIndex + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
              // Current position beacon
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 36,
                    height: 36,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: TeritoryColors.primary
                                .withValues(alpha: _pulseAnimation.value * 0.3),
                            border: Border.all(
                              color: TeritoryColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: TeritoryColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Progress bar at top ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: TeritoryColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.tripName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$validatedCount of $totalCount waypoints validated',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalCount > 0
                            ? validatedCount / totalCount
                            : 0,
                        minHeight: 6,
                        backgroundColor: TeritoryColors.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation(
                            TeritoryColors.validatedGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Participant avatars ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 90),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ...trip.participants.take(5).map((p) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      NetworkImage(p.userAvatar),
                                  backgroundColor:
                                      TeritoryColors.surfaceContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.userName.split(' ').first,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: TeritoryColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (nextWaypoint != null) ...[
                      Text(
                        'NEXT WAYPOINT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextWaypoint.placeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.straighten_rounded,
                              size: 14,
                              color: TeritoryColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '2.4 km away',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.schedule_rounded,
                              size: 14,
                              color: TeritoryColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '~15 min',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (nextWaypoint == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text('Validating waypoint via GPS...'),
                            ),
                          );
                          final result = await TeritoryRepository.instance.validateWaypoint(
                            trip.id,
                            nextWaypoint.id,
                            nextWaypoint.latitude,
                            nextWaypoint.longitude,
                          );
                          if (!context.mounted) return;
                          if (result != null && result['isWithinRadius'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: TeritoryColors.validatedGreen,
                                content: Text('🎯 ${nextWaypoint.placeName} Validated! Flag added to passport.'),
                              ),
                            );
                            ref.read(activeTripNotifierProvider.notifier).refresh();
                          } else {
                            final dist = result?['distanceMeters'] != null
                                ? '${((result!['distanceMeters'] as num) / 1000).toStringAsFixed(1)}km'
                                : 'beyond 15km';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.orange.shade800,
                                content: Text('📍 Out of radius ($dist). Must be within 15km to flag!'),
                              ),
                            );
                          }
                        },
                        icon:
                            const Icon(Icons.flag_rounded, size: 20),
                        label: Text(
                          'Flag This Stop',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeritoryColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
  }
}
