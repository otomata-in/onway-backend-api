import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../flag/presentation/live_flag_detail_sheet.dart';
import '../application/trips_provider.dart';

/// Combined screen for saved trip itineraries and wishlisted exploration spots.
class SavedPlansScreen extends ConsumerStatefulWidget {
  const SavedPlansScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends ConsumerState<SavedPlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startTrip(TripPlan plan) async {
    try {
      final trip = await TeritoryRepository.instance.startTrip(plan.id);
      if (!mounted) return;
      ref.invalidate(tripsHubProvider);
      context.push('/trips/${trip.id}/active');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this trip.')),
      );
    }
  }

  Future<void> _removeSavedPlan(TripPlan plan) async {
    try {
      await TeritoryRepository.instance.togglePlanSaved(plan.id);
      ref.invalidate(savedPlansLiveProvider);
      ref.invalidate(savedPlanIdsProvider);
      ref.invalidate(tripsHubProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${plan.name} from saved plans')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removeSavedFlag(ApiFlag flag) async {
    try {
      await TeritoryRepository.instance.toggleSaveFlag(flag.id);
      ref.invalidate(savedFlagsLiveProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${flag.placeName} from wishlist')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved & Wishlist',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
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
            Tab(
              icon: Icon(Icons.explore_rounded, size: 20),
              text: 'Expedition Plans',
            ),
            Tab(
              icon: Icon(Icons.bookmark_rounded, size: 20),
              text: 'Wishlist Spots',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SavedPlansTab(
            onStart: _startTrip,
            onRemove: _removeSavedPlan,
          ),
          _WishlistFlagsTab(
            onRemove: _removeSavedFlag,
          ),
        ],
      ),
    );
  }
}

// ─── SAVED PLANS TAB ─────────────────────────────────────────────────────────

class _SavedPlansTab extends ConsumerWidget {
  const _SavedPlansTab({
    required this.onStart,
    required this.onRemove,
  });

  final Future<void> Function(TripPlan plan) onStart;
  final Future<void> Function(TripPlan plan) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlansLiveProvider);
    void refresh() => ref.invalidate(savedPlansLiveProvider);

    return savedAsync.when(
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
                    'Bookmark an expedition plan and it will appear here',
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
                    onStart: () => onStart(plan),
                    onRemove: () => onRemove(plan),
                  );
                },
              ),
            ),
    );
  }
}

// ─── WISHLIST FLAGS TAB ──────────────────────────────────────────────────────

class _WishlistFlagsTab extends ConsumerWidget {
  const _WishlistFlagsTab({required this.onRemove});

  final Future<void> Function(ApiFlag flag) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(savedFlagsLiveProvider);
    void refresh() => ref.invalidate(savedFlagsLiveProvider);

    return flagsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TeritoryColors.primary),
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
                    : 'Could not load your wishlist.',
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
      data: (flags) => flags.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_outline_rounded,
                        size: 64, color: TeritoryColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No wishlist spots yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Save" on any spot or wonder on the map to add it to your travel wishlist',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: flags.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final flag = flags[index];
                  return _WishlistFlagCard(
                    flag: flag,
                    onView: () => LiveFlagDetailSheet.show(context, flag: flag),
                    onPlanRoute: () => context.push('/trips/planner'),
                    onRemove: () => onRemove(flag),
                  );
                },
              ),
            ),
    );
  }
}

// ─── CARDS ───────────────────────────────────────────────────────────────────

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
              fontSize: 15,
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
                icon: Icons.flag_rounded,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: '${plan.estimatedDistanceKm.toInt()} km',
                icon: Icons.straighten_rounded,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TeritoryColors.communityIndigo.withValues(alpha: 0.1),
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
                onPressed:
                    plan.status == TripPlanStatus.active ? null : onStart,
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

class _WishlistFlagCard extends StatelessWidget {
  const _WishlistFlagCard({
    required this.flag,
    required this.onView,
    required this.onPlanRoute,
    required this.onRemove,
  });

  final ApiFlag flag;
  final VoidCallback onView;
  final VoidCallback onPlanRoute;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: flag.isMajorFlag
                      ? TeritoryColors.majorGoldLight
                      : TeritoryColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      flag.isMajorFlag
                          ? Icons.stars_rounded
                          : Icons.place_rounded,
                      size: 13,
                      color: flag.isMajorFlag
                          ? TeritoryColors.majorGoldDark
                          : TeritoryColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      flag.isMajorFlag
                          ? 'MAJOR WONDER'
                          : flag.category.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: flag.isMajorFlag
                            ? TeritoryColors.majorGoldDark
                            : TeritoryColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (flag.city.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flag.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TeritoryColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            flag.placeName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            flag.locationLabel.isNotEmpty
                ? flag.locationLabel
                : '${flag.continent} • Coordinates: ${flag.latitude.toStringAsFixed(3)}, ${flag.longitude.toStringAsFixed(3)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: '${flag.kudos} kudos',
                icon: Icons.favorite_rounded,
              ),
              const SizedBox(width: 8),
              if (flag.hiddenGemCount > 0) ...[
                _InfoChip(
                  label: '${flag.hiddenGemCount} gems',
                  icon: Icons.diamond_outlined,
                ),
                const SizedBox(width: 8),
              ],
              _InfoChip(
                label: flag.authorName.isNotEmpty ? 'by ${flag.authorName}' : 'Explored',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: onView,
                child: Text(
                  'View Spot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onPlanRoute,
                icon: const Icon(Icons.add_road_rounded, size: 16),
                label: Text(
                  'Plan Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeritoryColors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove from wishlist',
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
