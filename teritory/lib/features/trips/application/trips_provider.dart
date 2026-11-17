import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_trip.dart';
import '../../../core/models/community_models.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/teritory_repository.dart';

class TripsHubNotifier extends AsyncNotifier<TripsHubSnapshot> {
  @override
  Future<TripsHubSnapshot> build() =>
      TeritoryRepository.instance.fetchTripsHub();

  /// Keeps the current cards on screen while reloading, and after a failed load.
  Future<void> refresh() async {
    state = const AsyncLoading<TripsHubSnapshot>().copyWithPrevious(state);
    final next = await AsyncValue.guard(
        () => TeritoryRepository.instance.fetchTripsHub());
    state = next.copyWithPrevious(state);
  }

  /// Starts the plan, then reloads so the Active tab reflects the new trip.
  Future<Trip> startTrip(String planId) async {
    final trip = await TeritoryRepository.instance.startTrip(planId);
    await refresh();
    return trip;
  }
}

final tripsHubProvider =
    AsyncNotifierProvider<TripsHubNotifier, TripsHubSnapshot>(
  TripsHubNotifier.new,
);

final tripHistoryLiveProvider =
    FutureProvider.autoDispose<List<TripHistoryEntry>>((ref) {
  return TeritoryRepository.instance.fetchTripHistory();
});

final planDetailLiveProvider =
    FutureProvider.autoDispose.family<TripPlanDetail, String>((ref, planId) {
  return TeritoryRepository.instance.fetchPlanDetail(planId);
});

/// Bookmark ids, kept separate so a failure here cannot hide the plan itself.
final savedPlanIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  return TeritoryRepository.instance.fetchSavedPlanIds();
});

final activeTripDetailProvider = FutureProvider.autoDispose
    .family<ActiveTripDetail, String>((ref, tripId) {
  final userId = ref.watch(currentUserProvider).id;
  return TeritoryRepository.instance
      .fetchActiveTripDetail(tripId, userId: userId);
});

final savedPlansLiveProvider =
    FutureProvider.autoDispose<List<TripPlan>>((ref) {
  return TeritoryRepository.instance.fetchSavedPlans();
});

/// Places the planner can use, taken from live flags. There is no geocoding
/// service, so a plan's stops are real flagged places rather than typed text
/// with invented coordinates.
///
/// Queried around the same centre the Explore map uses until device location
/// lands (see `ExploreFlagsNotifier`).
final plannerPlacesProvider = FutureProvider.autoDispose<List<ApiFlag>>((ref) {
  return TeritoryRepository.instance.fetchExploreFlags(
    latitude: 9.9790,
    longitude: 76.2760,
    radiusKm: 100,
  );
});

final plannerCommunitiesProvider =
    FutureProvider.autoDispose<List<Community>>((ref) {
  return TeritoryRepository.instance.fetchCommunitiesLive();
});
