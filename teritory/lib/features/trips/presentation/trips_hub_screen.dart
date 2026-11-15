import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/teritory_theme.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/models/trip_models.dart';

class TripsHubScreen extends ConsumerStatefulWidget {
  const TripsHubScreen({super.key});

  @override
  ConsumerState<TripsHubScreen> createState() => _TripsHubScreenState();
}

class _TripsHubScreenState extends ConsumerState<TripsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TeritoryColors.tripRoute.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.explore_rounded, color: TeritoryColors.tripRoute, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Expedition Hub',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: TeritoryColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: TeritoryColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: TeritoryColors.primary,
          unselectedLabelColor: TeritoryColors.textMuted,
          indicatorColor: TeritoryColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Active Trips'),
            Tab(text: 'My Plans'),
            Tab(text: 'Trip History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveTripsTab(),
          _MyPlansTab(),
          _TripHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/planner'),
        backgroundColor: TeritoryColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Plan New Trip',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Active Trips Tab ──────────────────────────────────────────────────

class _ActiveTripsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrips = ref.watch(activeTripProvider);
    final tripPlans = ref.watch(tripPlansProvider);

    if (activeTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.route_rounded,
        title: 'No Active Trips',
        subtitle: 'Start a trip from your plans to see it here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTrips.length,
      itemBuilder: (context, index) {
        final trip = activeTrips[index];
        final plan = tripPlans.where((p) => p.id == trip.tripPlanId).firstOrNull;
        return _ActiveTripCard(trip: trip, plan: plan);
      },
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final Trip trip;
  final TripPlan? plan;

  const _ActiveTripCard({required this.trip, this.plan});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(trip.startedAt);
    final elapsedHours = elapsed.inHours;
    final totalHours = plan?.estimatedDurationHours ?? 48;
    final progress = (elapsedHours / totalHours).clamp(0.0, 1.0);
    final participantCount = trip.participants.length;
    final activeParticipants =
        trip.participants.where((p) => p.status == ParticipantStatus.inProgress).length;
    final totalWaypoints = plan?.waypoints.length ?? 0;
    final validatedWaypoints =
        plan?.waypoints.where((w) => w.isValidated).length ?? 0;

    return GestureDetector(
      onTap: () => context.go('/trips/${trip.id}/active'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TeritoryColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TeritoryColors.tripRoute.withValues(alpha: 0.1),
                    TeritoryColors.tripRoute.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TeritoryColors.validatedGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${elapsedHours}h elapsed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trip.tripName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${plan!.originName} → ${plan!.destinationName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trip Progress',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.tripRoute,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: TeritoryColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation(TeritoryColors.tripRoute),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_rounded,
                        label: '$activeParticipants/$participantCount active',
                        color: TeritoryColors.communityIndigo,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.flag_rounded,
                        label: '$validatedWaypoints/$totalWaypoints waypoints',
                        color: TeritoryColors.validatedGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Participant avatars
                  Row(
                    children: [
                      ...trip.participants.take(4).map((p) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(p.userAvatar),
                          backgroundColor: TeritoryColors.surfaceContainer,
                        ),
                      )),
                      if (participantCount > 4)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: TeritoryColors.surfaceContainer,
                          child: Text(
                            '+${participantCount - 4}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: TeritoryColors.textSecondary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: TeritoryColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'View Map',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Plans Tab ──────────────────────────────────────────────────────

class _MyPlansTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripPlans = ref.watch(tripPlansProvider);

    if (tripPlans.isEmpty) {
      return _buildEmptyState(
        icon: Icons.map_rounded,
        title: 'No Plans Yet',
        subtitle: 'Create your first expedition plan!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tripPlans.length,
      itemBuilder: (context, index) {
        return _PlanCard(plan: tripPlans[index]);
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TripPlan plan;
  const _PlanCard({required this.plan});

  Color _statusColor(TripPlanStatus status) {
    switch (status) {
      case TripPlanStatus.draft:
        return TeritoryColors.textMuted;
      case TripPlanStatus.proposed:
        return TeritoryColors.sapphireBlue;
      case TripPlanStatus.voted:
        return TeritoryColors.rallyGold;
      case TripPlanStatus.active:
        return TeritoryColors.validatedGreen;
      case TripPlanStatus.completed:
        return TeritoryColors.tripRoute;
    }
  }

  String _statusLabel(TripPlanStatus status) {
    switch (status) {
      case TripPlanStatus.draft:
        return 'Draft';
      case TripPlanStatus.proposed:
        return 'Proposed';
      case TripPlanStatus.voted:
        return 'Voted';
      case TripPlanStatus.active:
        return 'Active';
      case TripPlanStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () => context.go('/trips/${plan.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TeritoryColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.originName} → ${plan.destinationName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(plan.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(plan.status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(plan.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TeritoryColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Info chips row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.straighten_rounded,
                  label: '${plan.estimatedDistanceKm.toInt()} km',
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: '${plan.estimatedDurationHours.toInt()}h',
                ),
                _InfoChip(
                  icon: Icons.flag_rounded,
                  label: '${plan.waypoints.length} waypoints',
                ),
                if (plan.voteScore > 0)
                  _InfoChip(
                    icon: Icons.thumb_up_rounded,
                    label: '${plan.voteScore} votes',
                    color: TeritoryColors.rallyGold,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Text(
                  'by ${plan.createdByName} · ${dateFormat.format(plan.createdAt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TeritoryColors.textMuted,
                  ),
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Start',
                  color: TeritoryColors.validatedGreen,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: TeritoryColors.sapphireBlue,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trip History Tab ──────────────────────────────────────────────────

class _TripHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(tripHistoryProvider);

    if (completions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No Trip History',
        subtitle: 'Complete trips to see your expedition log.',
      );
    }

    final completed = completions.where((c) => c.badge != TripBadge.none).toList();
    final incomplete = completions.where((c) => c.badge == TripBadge.none).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (completed.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            color: TeritoryColors.validatedGreen,
            count: completed.length,
          ),
          const SizedBox(height: 8),
          ...completed.map((c) => _HistoryCard(completion: c, isCompleted: true)),
        ],
        if (incomplete.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.cancel_rounded,
            label: 'Incomplete',
            color: TeritoryColors.expiredRed,
            count: incomplete.length,
          ),
          const SizedBox(height: 8),
          ...incomplete.map((c) => _HistoryCard(completion: c, isCompleted: false)),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TripCompletion completion;
  final bool isCompleted;
  const _HistoryCard({required this.completion, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeritoryColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? TeritoryColors.validatedGreen.withValues(alpha: 0.12)
                  : TeritoryColors.expiredRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.close_rounded,
              color: isCompleted ? TeritoryColors.validatedGreen : TeritoryColors.expiredRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip #${completion.tripId}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(completion.completedAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TeritoryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${completion.totalDistanceKm.toInt()} km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textPrimary,
                ),
              ),
              Text(
                '${completion.waypointsValidated}/${completion.totalWaypoints} ✓',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? TeritoryColors.validatedGreen : TeritoryColors.expiredRed,
                ),
              ),
            ],
          ),
          if (completion.badge == TripBadge.full) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TeritoryColors.rallyGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: TeritoryColors.rallyGold, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? TeritoryColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TeritoryColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int count;
  const _SectionHeader({required this.icon, required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TeritoryColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: TeritoryColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: TeritoryColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
