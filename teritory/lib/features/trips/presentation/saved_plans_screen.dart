import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/trip_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/trips_provider.dart';

class SavedPlansScreen extends ConsumerWidget {
  const SavedPlansScreen({super.key});

  Future<void> _startTrip(BuildContext context, WidgetRef ref, TripPlan plan) async {
    try {
      final trip = await TeritoryRepository.instance.startTrip(plan.id);
      if (!context.mounted) return;
      ref.invalidate(tripsHubProvider);
      context.push('/trips/${trip.id}/active');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this trip.')),
      );
    }
  }

  Future<void> _removeSaved(
      BuildContext context, WidgetRef ref, TripPlan plan) async {
    try {
      await TeritoryRepository.instance.togglePlanSaved(plan.id);
      ref.invalidate(savedPlansLiveProvider);
      ref.invalidate(savedPlanIdsProvider);
      ref.invalidate(tripsHubProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlansLiveProvider);
    void refresh() => ref.invalidate(savedPlansLiveProvider);

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
      body: savedAsync.when(
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
                      : 'Could not load your saved plans.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: refresh, child: const Text('Retry')),
              ],
            ),
          ),
        ),
        data: (plans) => plans.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_border_rounded,
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
                      'Bookmark a plan and it will appear here',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _SavedPlanCard(
                      plan: plan,
                      onView: () => context.push('/trips/${plan.id}'),
                      onStart: () => _startTrip(context, ref, plan),
                      onRemove: () => _removeSaved(context, ref, plan),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  final TripPlan plan;
  final VoidCallback onView;
  final VoidCallback onStart;
  final VoidCallback onRemove;

  const _SavedPlanCard({
    required this.plan,
    required this.onView,
    required this.onStart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sourceLabel = plan.communityName ?? 'Personal';

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
          Row(
            children: [
              _InfoChip(
                  label: '${plan.waypoints.length} stops',
                  icon: Icons.flag_rounded),
              const SizedBox(width: 8),
              _InfoChip(
                  label: '${plan.estimatedDistanceKm.toInt()} km',
                  icon: Icons.straighten_rounded),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      TeritoryColors.communityIndigo.withValues(alpha: 0.1),
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
          Row(
            children: [
              TextButton(
                onPressed: onView,
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
                onPressed: plan.status == TripPlanStatus.active ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeritoryColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  plan.status == TripPlanStatus.active ? 'Active' : 'Start',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove bookmark',
                icon: const Icon(Icons.bookmark_remove_rounded),
                color: TeritoryColors.expiredRed,
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
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
