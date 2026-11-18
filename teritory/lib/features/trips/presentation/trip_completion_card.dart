import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/models/trip_models.dart';

/// A full-screen celebration dialog shown when a trip is completed.
///
/// Stats come from the live trip and the badge from the `POST
/// /trips/:tripId/complete` response, so nothing here is sample data.
class TripCompletionCard extends StatelessWidget {
  final Trip trip;
  final List<TripWaypoint> waypoints;
  final String badge;

  const TripCompletionCard({
    super.key,
    required this.trip,
    this.waypoints = const [],
    this.badge = 'NONE',
  });

  /// Convenience method to show the completion dialog.
  static Future<void> show(
    BuildContext context, {
    required Trip trip,
    List<TripWaypoint> waypoints = const [],
    String badge = 'NONE',
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) =>
          TripCompletionCard(trip: trip, waypoints: waypoints, badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int durationDays = (trip.estimatedDurationHours / 24).ceil().clamp(
      1,
      999,
    );
    final int stopCount = waypoints.length;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Big Checkmark Icon ──────────────────────────────────────
              const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: TeritoryColors.validatedGreen,
              ),
              const SizedBox(height: 16),

              // ── Title ──────────────────────────────────────────────────
              Text(
                'Expedition Complete!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // ── Trip Name Subtitle ─────────────────────────────────────
              Text(
                trip.tripName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Stats Row ──────────────────────────────────────────────
              Row(
                children: [
                  _StatItem(
                    icon: Icons.calendar_today_rounded,
                    value: '$durationDays',
                    label: 'Days',
                  ),
                  _StatItem(
                    icon: Icons.flag_rounded,
                    value: '$stopCount',
                    label: 'Stops',
                  ),
                  _StatItem(
                    icon: Icons.military_tech_rounded,
                    value: badge.toLowerCase(),
                    label: 'Badge',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Route Summary Card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TeritoryColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TeritoryColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Summary',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Origin
                    _RouteStop(
                      label: trip.originName.isEmpty
                          ? 'Origin'
                          : trip.originName,
                      isFirst: true,
                      isLast: waypoints.isEmpty,
                    ),
                    // Waypoints, flagged when this traveler validated them.
                    for (int i = 0; i < waypoints.length; i++)
                      _RouteStop(
                        label: waypoints[i].placeName,
                        isFirst: false,
                        isLast:
                            i == waypoints.length - 1 &&
                            trip.destinationName == trip.originName,
                      ),
                    // Destination (if different from origin)
                    if (trip.destinationName != trip.originName)
                      _RouteStop(
                        label: trip.destinationName,
                        isFirst: false,
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────────────────────────
              Row(
                children: [
                  // Share
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Text('📤', style: TextStyle(fontSize: 16)),
                      label: Text(
                        'Share',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TeritoryColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Add to Story
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Text('📖', style: TextStyle(fontSize: 16)),
                      label: Text(
                        'Story',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TeritoryColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Done
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Text('✅', style: TextStyle(fontSize: 16)),
                      label: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeritoryColors.validatedGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: TeritoryColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final String label;
  final bool isFirst;
  final bool isLast;

  const _RouteStop({
    required this.label,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isFirst
                ? Icons.trip_origin_rounded
                : isLast
                ? Icons.location_on_rounded
                : Icons.circle,
            size: isFirst || isLast ? 16 : 8,
            color: isFirst
                ? TeritoryColors.validatedGreen
                : isLast
                ? TeritoryColors.primary
                : TeritoryColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isFirst || isLast
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: TeritoryColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
