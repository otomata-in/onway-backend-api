import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(tripHistoryProvider);

    final completed =
        completions.where((c) => c.badge != TripBadge.none).toList();
    final incomplete =
        completions.where((c) => c.badge == TripBadge.none).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: completions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: TeritoryColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No trip history yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Completed Trips ──
                if (completed.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: TeritoryColors.validatedGreen),
                      const SizedBox(width: 6),
                      Text(
                        '✅ Completed Trips',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...completed.map((c) => _buildHistoryCard(
                        completion: c,
                        isCompleted: true,
                      )),
                ],

                // ── Incomplete Trips ──
                if (incomplete.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.cancel_rounded,
                          size: 18, color: TeritoryColors.expiredRed),
                      const SizedBox(width: 6),
                      Text(
                        '❌ Incomplete Trips',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...incomplete.map((c) => _buildHistoryCard(
                        completion: c,
                        isCompleted: false,
                      )),
                ],
              ],
            ),
    );
  }

  Widget _buildHistoryCard({
    required TripCompletion completion,
    required bool isCompleted,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final accentColor =
        isCompleted ? TeritoryColors.validatedGreen : TeritoryColors.expiredRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Accent left border
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Trip #${completion.tripId}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: completion.badge == TripBadge.full
                                ? TeritoryColors.majorGoldLight
                                : TeritoryColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            completion.badge == TripBadge.full
                                ? '🏆 Full Completion'
                                : '⭐ Partial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: completion.badge == TripBadge.full
                                  ? TeritoryColors.majorGoldDark
                                  : TeritoryColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(completion.completedAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isCompleted)
                    Row(
                      children: [
                        Text(
                          '${completion.totalDistanceKm.toInt()} km',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${completion.waypointsValidated}/${completion.totalWaypoints} waypoints',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: TeritoryColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          completion.userName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Incomplete — ${completion.totalWaypoints - completion.waypointsValidated} waypoints missed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: TeritoryColors.expiredRed,
                        fontWeight: FontWeight.w600,
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
