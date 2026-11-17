import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/trips_provider.dart';

class TripPlanDetailScreen extends ConsumerStatefulWidget {
  final String tripPlanId;

  const TripPlanDetailScreen({super.key, required this.tripPlanId});

  @override
  ConsumerState<TripPlanDetailScreen> createState() =>
      _TripPlanDetailScreenState();
}

class _TripPlanDetailScreenState extends ConsumerState<TripPlanDetailScreen> {
  bool _saving = false;
  bool _voting = false;
  bool _starting = false;

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Could not load this plan. Check the API and retry.';

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  Future<void> _toggleSave(TripPlan plan) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await TeritoryRepository.instance.togglePlanSaved(plan.id);
      if (!mounted) return;
      ref.invalidate(savedPlanIdsProvider);
      ref.invalidate(tripsHubProvider);
      _toast(saved ? 'Saved to your plans' : 'Removed from saved plans');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not update your saved plans.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleVote(TripPlan plan) async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      final voted = await TeritoryRepository.instance.toggleTripPlanVote(plan.id);
      if (!mounted) return;
      ref.invalidate(planDetailLiveProvider(widget.tripPlanId));
      _toast(voted ? 'Vote added' : 'Vote removed');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not save your vote. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _startTrip(TripPlan plan) async {
    if (_starting) return;
    if (plan.status == TripPlanStatus.active) {
      _toast('This plan is already active.');
      return;
    }

    setState(() => _starting = true);
    try {
      final trip = await TeritoryRepository.instance.startTrip(plan.id);
      if (!mounted) return;
      ref.invalidate(tripsHubProvider);
      ref.invalidate(planDetailLiveProvider(widget.tripPlanId));
      context.push('/trips/${trip.id}/active');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not start this trip. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(planDetailLiveProvider(widget.tripPlanId));
    final detail = detailAsync.valueOrNull;

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Plan')),
        body: Center(
          child: detailAsync.hasError
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 44, color: TeritoryColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage(detailAsync.error),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref
                            .invalidate(planDetailLiveProvider(widget.tripPlanId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(
                  color: TeritoryColors.tripRoute),
        ),
      );
    }

    final plan = detail.plan;
    final isSaved = ref.watch(savedPlanIdsProvider).valueOrNull
            ?.contains(plan.id) ??
        false;
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
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved ? TeritoryColors.primary : null,
                    size: 22,
                  ),
            tooltip: isSaved ? 'Remove bookmark' : 'Save plan',
            onPressed: _saving ? null : () => _toggleSave(plan),
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
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
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

                  // ── Stats ──
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
                          _StatItem(
                            value: '${plan.estimatedDistanceKm.toInt()} km',
                            label: 'Distance',
                            icon: Icons.straighten_rounded,
                          ),
                          _StatItem(
                            value: durationText,
                            label: 'Duration',
                            icon: Icons.schedule_rounded,
                          ),
                          _StatItem(
                            value: '${plan.waypoints.length}',
                            label: 'Waypoints',
                            icon: Icons.flag_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Waypoint timeline ──
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
                  if (plan.waypoints.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'This plan has no waypoints yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: plan.waypoints.length,
                      itemBuilder: (context, index) {
                        return _WaypointTimelineItem(
                          waypoint: plan.waypoints[index],
                          index: index,
                          isLast: index == plan.waypoints.length - 1,
                        );
                      },
                    ),
                  const SizedBox(height: 22),

                  // ── Gear ──
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
                                size: 16, color: TeritoryColors.gearAmber),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
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

          // ── Bottom actions ──
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
                    child: ElevatedButton(
                      onPressed: _starting ? null : () => _startTrip(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeritoryColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              plan.status == TripPlanStatus.active
                                  ? 'Trip Already Active'
                                  : 'Start Trip',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _voting ? null : () => _toggleVote(plan),
                    icon: _voting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            detail.hasVoted
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_outlined,
                          ),
                    color: TeritoryColors.validatedGreen,
                    tooltip: detail.hasVoted ? 'Remove vote' : 'Vote for this plan',
                  ),
                  Text(
                    '${plan.voteScore}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: TeritoryColors.textPrimary,
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
