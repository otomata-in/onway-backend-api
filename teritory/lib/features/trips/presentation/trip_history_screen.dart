import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/api_trip.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/trips_provider.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tripHistoryLiveProvider);

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
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeritoryColors.tripRoute),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 44, color: TeritoryColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  error is ApiException
                      ? error.message
                      : 'Could not load your trip history.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(tripHistoryLiveProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
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
            );
          }

          final completed = entries.where((e) => e.isCompleted).toList();
          final incomplete = entries.where((e) => !e.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                ...completed.map((e) => _HistoryCard(entry: e)),
              ],
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
                ...incomplete.map((e) => _HistoryCard(entry: e)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TripHistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final accentColor = entry.isCompleted
        ? TeritoryColors.validatedGreen
        : TeritoryColors.expiredRed;

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
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
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
                          entry.tripName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                      ),
                      if (entry.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry.badge == TripBadge.full
                                ? TeritoryColors.majorGoldLight
                                : TeritoryColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.badge == TripBadge.full
                                ? '🏆 Full Completion'
                                : '⭐ Partial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: entry.badge == TripBadge.full
                                  ? TeritoryColors.majorGoldDark
                                  : TeritoryColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.completedAt == null
                        ? 'Date not recorded'
                        : dateFormat.format(entry.completedAt!),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (entry.distanceKm > 0) ...[
                        Text(
                          '${entry.distanceKm.toInt()} km',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        '${entry.totalWaypoints} waypoints',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
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
