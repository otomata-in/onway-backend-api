import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class CompletedTripsScreen extends ConsumerWidget {
  const CompletedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(tripHistoryProvider);

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
      body: completions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_off_rounded,
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
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: completions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final completion = completions[index];
                return _CompletionCard(completion: completion);
              },
            ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final TripCompletion completion;

  const _CompletionCard({required this.completion});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final durationHours = completion.totalDurationHours.toInt();
    final durationDays = durationHours ~/ 24;
    final remainingHours = durationHours % 24;
    final durationText = durationDays > 0
        ? '$durationDays days $remainingHours hrs'
        : '$durationHours hrs';

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
          // Trip name and date
          Text(
            'Trip #${completion.tripId}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(completion.completedAt),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _buildStatChip(Icons.straighten_rounded,
                  '${completion.totalDistanceKm.toInt()} km'),
              const SizedBox(width: 10),
              _buildStatChip(Icons.schedule_rounded, durationText),
              const SizedBox(width: 10),
              _buildStatChip(Icons.flag_rounded,
                  '${completion.waypointsValidated}/${completion.totalWaypoints} validated'),
            ],
          ),
          const SizedBox(height: 14),

          // Badge and participants row
          Row(
            children: [
              // Badge
              if (completion.badge == TripBadge.full)
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
              else if (completion.badge == TripBadge.partial)
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
              const Spacer(),

              // Mock participant avatars
              SizedBox(
                width: 80,
                height: 28,
                child: Stack(
                  children: List.generate(4, (i) {
                    return Positioned(
                      left: i * 18.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(
                            'https://picsum.photos/seed/avatar_$i/100',
                          ),
                          backgroundColor: TeritoryColors.surfaceContainer,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Expanded(
      child: Container(
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
