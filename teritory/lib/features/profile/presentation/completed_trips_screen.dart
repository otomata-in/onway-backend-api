import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/api_trip.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../trips/application/trips_provider.dart';

class CompletedTripsScreen extends ConsumerWidget {
  const CompletedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tripHistoryLiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Completed Expeditions',
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
                      : 'Could not load completed expeditions.',
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
          final completed = entries.where((entry) => entry.isCompleted).toList();

          if (completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_off_rounded,
                      size: 64, color: TeritoryColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No completed expeditions yet',
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: completed.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _CompletionCard(entry: completed[index]),
          );
        },
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final TripHistoryEntry entry;

  const _CompletionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.tripName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              if (entry.distanceKm > 0)
                _StatChip(
                  icon: Icons.straighten_rounded,
                  label: '${entry.distanceKm.toInt()} km',
                ),
              if (entry.distanceKm > 0) const SizedBox(width: 10),
              _StatChip(
                icon: Icons.flag_rounded,
                label: '${entry.totalWaypoints} waypoints',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (entry.badge == TripBadge.full)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeritoryColors.majorGold),
                  ),
                  child: Text(
                    '🏆 Full Completion',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.majorGoldDark,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TeritoryColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeritoryColors.border),
                  ),
                  child: Text(
                    '⭐ Partial',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: TeritoryColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: TeritoryColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TeritoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
