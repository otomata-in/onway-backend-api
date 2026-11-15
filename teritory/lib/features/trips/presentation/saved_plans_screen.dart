import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/teritory_theme.dart';

class SavedPlansScreen extends ConsumerWidget {
  const SavedPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlans = ref.watch(savedPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Plans',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: savedPlans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 64, color: TeritoryColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No saved plans',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plans you save will appear here',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedPlans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = savedPlans[index];
                return _SavedPlanCard(plan: plan);
              },
            ),
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  final TripPlan plan;

  const _SavedPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final sourceLabel =
        plan.communityName ?? 'Personal';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.originName} → ${plan.destinationName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Info chips
          Row(
            children: [
              _buildChip('${plan.waypoints.length} waypoints',
                  Icons.flag_rounded),
              const SizedBox(width: 8),
              _buildChip('${plan.estimatedDistanceKm.toInt()} km',
                  Icons.straighten_rounded),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TeritoryColors.communityIndigo
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sourceLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.communityIndigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing plan...')),
                  );
                },
                child: Text(
                  'View',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting trip...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeritoryColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Start',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan deleted')),
                  );
                },
                icon: const Icon(Icons.delete_outline_rounded),
                color: TeritoryColors.expiredRed,
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TeritoryColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: TeritoryColors.textSecondary),
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
