import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/theme/teritory_theme.dart';

class TripPlanDetailScreen extends ConsumerWidget {
  final String tripPlanId;

  const TripPlanDetailScreen({super.key, required this.tripPlanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = MockDataService.instance.tripPlans
        .where((p) => p.id == tripPlanId)
        .firstOrNull;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Plan')),
        body: Center(
          child: Text(
            'Plan not found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final durationHours = plan.estimatedDurationHours.toInt();
    final days = durationHours ~/ 24;
    final hrs = durationHours % 24;
    final durationText =
        days > 0 ? '$days days $hrs hrs' : '$durationHours hrs';

    final waypointPoints =
        plan.waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          plan.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing trip plan...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Map ──
                  SizedBox(
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: waypointPoints.isNotEmpty
                            ? waypointPoints[0]
                            : const LatLng(10.0889, 77.0595),
                        initialZoom: 8.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.onway.teritory',
                          tileBuilder: (context, tileWidget, tile) =>
                              ColorFiltered(
                            colorFilter:
                                const ColorFilter.matrix(<double>[
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
                                strokeWidth: 3.0,
                                color: TeritoryColors.tripRoute,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: plan.waypoints.map((w) {
                            return Marker(
                              point: LatLng(w.latitude, w.longitude),
                              width: 28,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: TeritoryColors.tripRoute,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${w.orderIndex + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Trip Stats Card ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TeritoryColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            '${plan.estimatedDistanceKm.toInt()} km',
                            'Distance',
                            Icons.straighten_rounded,
                          ),
                          _buildStatItem(
                            durationText,
                            'Duration',
                            Icons.schedule_rounded,
                          ),
                          _buildStatItem(
                            '${plan.waypoints.length}',
                            'Waypoints',
                            Icons.flag_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Waypoint Timeline ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Waypoint Timeline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: plan.waypoints.length,
                    itemBuilder: (context, index) {
                      final waypoint = plan.waypoints[index];
                      final isLast = index == plan.waypoints.length - 1;
                      return _WaypointTimelineItem(
                        waypoint: waypoint,
                        index: index,
                        isLast: isLast,
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // ── Gear Recommendations ──
                  if (plan.gearSuggestions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Gear Recommendations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: plan.gearSuggestions.map((gear) {
                          return Chip(
                            label: Text(
                              gear,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TeritoryColors.majorGoldDark,
                              ),
                            ),
                            backgroundColor: TeritoryColors.gearAmber
                                .withValues(alpha: 0.15),
                            side: BorderSide(
                              color: TeritoryColors.gearAmber
                                  .withValues(alpha: 0.4),
                            ),
                            avatar: const Icon(Icons.backpack_rounded,
                                size: 16,
                                color: TeritoryColors.gearAmber),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: TeritoryColors.border),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Starting trip...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeritoryColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Start Trip',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Forking plan...')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: TeritoryColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Fork & Customize',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Vote buttons
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upvoted!')),
                      );
                    },
                    icon: const Icon(Icons.thumb_up_outlined),
                    color: TeritoryColors.validatedGreen,
                  ),
                  Text(
                    '${plan.voteScore}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downvoted')),
                      );
                    },
                    icon: const Icon(Icons.thumb_down_outlined),
                    color: TeritoryColors.expiredRed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: TeritoryColors.tripRoute),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: TeritoryColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WaypointTimelineItem extends StatelessWidget {
  final TripWaypoint waypoint;
  final int index;
  final bool isLast;

  const _WaypointTimelineItem({
    required this.waypoint,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: TeritoryColors.tripRoute,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: TeritoryColors.tripRoute.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waypoint.placeName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${waypoint.category} • ${waypoint.flagCount} flags'
                          '${waypoint.distanceFromPrevKm > 0 ? ' • ${waypoint.distanceFromPrevKm.toInt()} km from prev' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (waypoint.isValidated)
                    const Icon(Icons.check_circle_rounded,
                        color: TeritoryColors.validatedGreen, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
