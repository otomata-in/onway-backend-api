import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/teritory_repository.dart';

/// The two backend reads the Explore map needs, as a seam so tests can drive the
/// map without a live API. Production always uses [LiveExploreDataSource].
abstract class ExploreDataSource {
  Future<List<ApiFlag>> fetchExploreFlags({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  Future<Set<String>> fetchFriendIds();
}

class LiveExploreDataSource implements ExploreDataSource {
  const LiveExploreDataSource();

  @override
  Future<List<ApiFlag>> fetchExploreFlags({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    return TeritoryRepository.instance.fetchExploreFlags(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<Set<String>> fetchFriendIds() {
    return TeritoryRepository.instance.fetchFriendIds();
  }
}

final exploreDataSourceProvider = Provider<ExploreDataSource>(
  (ref) => const LiveExploreDataSource(),
);

/// Everything the Explore map needs for one render pass.
///
/// Loaded from the backend only. If the API is unreachable the provider enters an
/// error state and the UI offers a retry — it never substitutes bundled/mock pins.
class ExploreFlagsData {
  final List<ApiFlag> flags;
  final Set<String> friendIds;

  const ExploreFlagsData({required this.flags, required this.friendIds});

  List<ApiFlag> mine(String? currentUserId) =>
      flags.where((f) => f.isOwnedBy(currentUserId)).toList();

  List<ApiFlag> friends(String? currentUserId) => flags
      .where((f) => !f.isOwnedBy(currentUserId) && friendIds.contains(f.userId))
      .toList();

  List<ApiFlag> major() => flags.where((f) => f.isMajorFlag).toList();
}

/// Haversine distance in metres. Plenty accurate for "is this a different
/// neighbourhood, worth another 100 km query?".
double distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
}

class ExploreFlagsNotifier extends AsyncNotifier<ExploreFlagsData> {
  static const double radiusKm = 100;

  /// How far the traveller must move before the 100 km query is worth repeating:
  /// GPS drift and a walk to the next street must not re-fire it.
  static const double requeryMeters = 2000;

  /// Centre of the newest query and its future — in flight or already resolved.
  /// A position re-emitted from the same neighbourhood reuses it, so a burst of
  /// fixes while a query is running cannot fire a second request.
  LatLng? _lastCenter;
  Future<ExploreFlagsData>? _lastLoad;

  /// The cached or fresh device position when we have one, else the labelled
  /// Kochi fallback — the query centre is never a silent hardcoded guess.
  /// If a user explicitly searches for a place, [customExploreTargetProvider] overrides
  /// the centre so flags at that destination are retrieved and displayed.
  @override
  Future<ExploreFlagsData> build() {
    final customTarget = ref.watch(customExploreTargetProvider);
    final location =
        ref.watch(mapLocationProvider).valueOrNull ?? MapLocation.fallback;
    final center = customTarget?.coordinates ?? location.coordinates;

    final isCustom = customTarget != null;
    final queried = _lastCenter;
    final pending = _lastLoad;
    if (!isCustom &&
        queried != null &&
        pending != null &&
        distanceMeters(queried, center) < requeryMeters) {
      // Same neighbourhood: reuse the running/finished query instead of
      // spending a request on every 50 m fix.
      return pending;
    }

    _lastCenter = center;
    final load = _load(center, customTarget?.focusedFlag);
    _lastLoad = load;
    return load;
  }

  Future<ExploreFlagsData> _load(LatLng center, [ApiFlag? focusedFlag]) async {
    final dataSource = ref.read(exploreDataSourceProvider);

    // Friend ids are an enhancement, not a requirement: if that call fails the
    // map still renders live flags, and the Friends filter simply stays empty.
    final friendIdsFuture = dataSource.fetchFriendIds().catchError(
      (_) => <String>{},
    );

    // Both requests are in flight; awaiting the flags first keeps their
    // ApiException intact instead of wrapping it in ParallelWaitError.
    var flags = await dataSource.fetchExploreFlags(
      latitude: center.latitude,
      longitude: center.longitude,
      radiusKm: radiusKm,
    );

    // Guarantee the searched flag is included even if it lies outside the default query window
    if (focusedFlag != null && !flags.any((f) => f.id == focusedFlag.id)) {
      flags = [focusedFlag, ...flags];
    }

    final friendIds = await friendIdsFuture;

    return ExploreFlagsData(flags: flags, friendIds: friendIds);
  }

  /// Reloads without dropping the pins already on screen: the previous data is
  /// carried into the loading state and also kept if the refresh fails, so the
  /// map shows stale-but-real flags plus a retry banner instead of going blank.
  Future<void> refresh() async {
    state = const AsyncLoading<ExploreFlagsData>().copyWithPrevious(state);
    final customTarget = ref.read(customExploreTargetProvider);
    final location =
        ref.read(mapLocationProvider).valueOrNull ?? MapLocation.fallback;
    final center = customTarget?.coordinates ?? location.coordinates;
    _lastCenter = center;
    final load = _load(center, customTarget?.focusedFlag);
    _lastLoad = load;
    state = (await AsyncValue.guard(() => load)).copyWithPrevious(state);
  }
}

/// Target destination set when an explorer searches for a place or flag.
class ExploreTarget {
  final LatLng coordinates;
  final String label;
  final String? subtitle;
  final ApiFlag? focusedFlag;

  const ExploreTarget({
    required this.coordinates,
    required this.label,
    this.subtitle,
    this.focusedFlag,
  });
}

/// If non-null, the Explore map is focused on this searched destination rather than GPS.
final customExploreTargetProvider = StateProvider<ExploreTarget?>((ref) => null);

final exploreFlagsProvider =
    AsyncNotifierProvider<ExploreFlagsNotifier, ExploreFlagsData>(
      ExploreFlagsNotifier.new,
    );

/// Hidden gems within 5 km of the Explore centre (`GET /flags/sub-territories`).
/// Queried only while the Sub-Spots filter is selected, so opening the map does
/// not pay for an extra request nobody asked for.
final subSpotsProvider = FutureProvider.autoDispose<List<ApiFlag>>((ref) {
  final customTarget = ref.watch(customExploreTargetProvider);
  final location =
      ref.watch(mapLocationProvider).valueOrNull ?? MapLocation.fallback;
  final center = customTarget?.coordinates ?? location.coordinates;
  // Snapped to a ~1 km grid: the 5 km shelf follows the traveller without
  // re-firing on every position update while they walk.
  final latitude = (center.latitude * 100).roundToDouble() / 100;
  final longitude = (center.longitude * 100).roundToDouble() / 100;
  return TeritoryRepository.instance.fetchSubTerritories(
    latitude: latitude,
    longitude: longitude,
  );
});

/// Full social payload for one flag, loaded on demand by the detail sheet.
final flagDetailProvider = FutureProvider.autoDispose
    .family<ApiFlagDetail, String>((ref, flagId) {
      return TeritoryRepository.instance.fetchFlagDetail(flagId);
    });
