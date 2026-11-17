import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_trip.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/trips_provider.dart';

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
  bool _validating = false;
  bool _completing = false;

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
    if (widget.tripId != null) {
      SocketService.instance.joinTrip(widget.tripId!);
    }
  }

  @override
  void dispose() {
    if (widget.tripId != null) {
      SocketService.instance.leaveTrip(widget.tripId!);
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Could not load this trip. Check the API and retry.';

  Future<void> _validateWaypoint(
    ActiveTripDetail detail,
    String tripId,
    String waypointId,
  ) async {
    if (_validating) return;
    if (!detail.hasPosition) {
      _toast(
        'No GPS position recorded for this trip yet, so this stop cannot be '
        'validated.',
        error: true,
      );
      return;
    }

    setState(() => _validating = true);
    try {
      final result = await TeritoryRepository.instance.validateWaypointAt(
        tripId: tripId,
        waypointId: waypointId,
        latitude: detail.currentLat!,
        longitude: detail.currentLng!,
      );
      if (!mounted) return;
      ref.invalidate(activeTripDetailProvider(tripId));
      ref.invalidate(tripsHubProvider);
      _toast(result.message, error: !result.isValid);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not validate this stop. Check your connection.',
          error: true);
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _completeTrip(String tripId) async {
    if (_completing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete this trip?'),
        content: const Text(
            'Stops you have not validated will count as missed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _completing = true);
    try {
      await TeritoryRepository.instance.completeTrip(tripId);
      if (!mounted) return;
      ref.invalidate(tripsHubProvider);
      ref.invalidate(tripHistoryLiveProvider);
      _toast('Trip completed');
      if (context.canPop()) context.pop();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not complete this trip. Check your connection.',
          error: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId;
    if (tripId == null) {
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

    final detailAsync = ref.watch(activeTripDetailProvider(tripId));
    final detail = detailAsync.valueOrNull;

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
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
                        onPressed: () =>
                            ref.invalidate(activeTripDetailProvider(tripId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(
                  color: TeritoryColors.validatedGreen),
        ),
      );
    }

    final trip = detail.trip;
    final waypoints = detail.waypoints;
    final waypointPoints =
        waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
    final validatedCount = detail.validatedWaypointIds.length;
    final totalCount = waypoints.length;
    final nextWaypoint = detail.nextWaypoint;
    final currentPos = detail.hasPosition
        ? LatLng(detail.currentLat!, detail.currentLng!)
        : (waypointPoints.isNotEmpty
            ? waypointPoints[0]
            : const LatLng(10.0889, 77.0595));

    final nextDistanceKm = nextWaypoint != null && detail.hasPosition
        ? const Distance().as(
            LengthUnit.Kilometer,
            currentPos,
            LatLng(nextWaypoint.latitude, nextWaypoint.longitude),
          )
        : null;

    return Scaffold(
      body: Stack(
        children: [
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
              MarkerLayer(
                markers: waypoints.map((w) {
                  final isValidated = detail.validatedWaypointIds.contains(w.id);
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
              if (detail.hasPosition)
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
                              color: TeritoryColors.primary.withValues(
                                  alpha: _pulseAnimation.value * 0.3),
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

          // ── Progress header ──
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
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/trips');
                            }
                          },
                          icon:
                              const Icon(Icons.arrow_back_rounded, size: 20),
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
                          '$validatedCount of $totalCount stops validated',
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
                        value: totalCount > 0 ? validatedCount / totalCount : 0,
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

          // ── Participants ──
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
                              _ParticipantAvatar(
                                name: p.userName,
                                avatarUrl: p.userAvatar,
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

                    if (nextWaypoint == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          waypoints.isEmpty
                              ? 'This trip has no waypoints.'
                              : 'All stops validated. Complete the trip to log it.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                      )
                    else ...[
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
                            nextDistanceKm == null
                                ? 'Live position unavailable'
                                : '${nextDistanceKm.toStringAsFixed(1)} km away',
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
                        onPressed: nextWaypoint == null ||
                                _validating ||
                                !detail.hasPosition
                            ? null
                            : () => _validateWaypoint(
                                  detail,
                                  tripId,
                                  nextWaypoint.id,
                                ),
                        icon: _validating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.flag_rounded, size: 20),
                        label: Text(
                          detail.hasPosition
                              ? 'Flag This Stop'
                              : 'Live position unavailable',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeritoryColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _completing ? null : () => _completeTrip(tripId),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: TeritoryColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _completing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Complete Trip',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: TeritoryColors.textPrimary,
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

class _ParticipantAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _ParticipantAvatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: TeritoryColors.surfaceContainer,
        backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        onBackgroundImageError: avatarUrl.isEmpty ? null : (_, _) {},
        child: avatarUrl.isEmpty
            ? Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textSecondary,
                ),
              )
            : null,
      ),
    );
  }
}
