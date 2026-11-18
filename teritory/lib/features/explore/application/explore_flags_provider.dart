import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/teritory_repository.dart';

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

class ExploreFlagsNotifier extends AsyncNotifier<ExploreFlagsData> {
  static const double radiusKm = 100;

  /// Centre and payload of the last completed query, so a re-emitted location
  /// that is effectively the same place does not trigger another request.
  LatLng? _lastCenter;
  ExploreFlagsData? _lastData;

  /// The cached or fresh device position when we have one, else the labelled
  /// Kochi fallback — the query centre is never a silent hardcoded guess.
  ///
  /// Watches the whole value rather than `.future`: the location provider emits
  /// a cached position (or the fallback) first, so the first query runs without
  /// waiting on GPS, and a second one runs when the real fix arrives.
  @override
  Future<ExploreFlagsData> build() {
    final location =
        ref.watch(mapLocationProvider).valueOrNull ?? MapLocation.resolving;
    final center = location.coordinates;

    final previous = _lastData;
    final lastCenter = _lastCenter;
    if (previous != null && lastCenter != null && _sameCenter(lastCenter, center)) {
      return Future.value(previous);
    }

    _lastCenter = center;
    return _load(center);
  }

  static bool _sameCenter(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 0.0001 &&
      (a.longitude - b.longitude).abs() < 0.0001;

  Future<ExploreFlagsData> _load(LatLng center) async {
    final repository = TeritoryRepository.instance;

    // Friend ids are an enhancement, not a requirement: if that call fails the
    // map still renders live flags, and the Friends filter simply stays empty.
    final friendIdsFuture = repository.fetchFriendIds().catchError(
      (_) => <String>{},
    );

    // Both requests are in flight; awaiting the flags first keeps their
    // ApiException intact instead of wrapping it in ParallelWaitError.
    final flags = await repository.fetchExploreFlags(
      latitude: center.latitude,
      longitude: center.longitude,
      radiusKm: radiusKm,
    );
    final friendIds = await friendIdsFuture;

    final data = ExploreFlagsData(flags: flags, friendIds: friendIds);
    _lastData = data;
    return data;
  }

  /// Reloads without dropping the pins already on screen: the previous data is
  /// carried into the loading state and also kept if the refresh fails, so the
  /// map shows stale-but-real flags plus a retry banner instead of going blank.
  Future<void> refresh() async {
    state = const AsyncLoading<ExploreFlagsData>().copyWithPrevious(state);
    // Re-read the fix so a recentre after granting permission queries from the
    // traveller's actual position.
    final location =
        ref.read(mapLocationProvider).valueOrNull ?? MapLocation.resolving;
    final next = await AsyncValue.guard(() => _load(location.coordinates));
    state = next.copyWithPrevious(state);
  }
}

final exploreFlagsProvider =
    AsyncNotifierProvider<ExploreFlagsNotifier, ExploreFlagsData>(
      ExploreFlagsNotifier.new,
    );

/// Hidden gems within 5 km of the Explore centre (`GET /flags/sub-territories`).
/// Queried only while the Sub-Spots filter is selected, so opening the map does
/// not pay for an extra request nobody asked for.
final subSpotsProvider = FutureProvider.autoDispose<List<ApiFlag>>((ref) {
  final location =
      ref.watch(mapLocationProvider).valueOrNull ?? MapLocation.resolving;
  return TeritoryRepository.instance.fetchSubTerritories(
    latitude: location.coordinates.latitude,
    longitude: location.coordinates.longitude,
  );
});

/// Full social payload for one flag, loaded on demand by the detail sheet.
final flagDetailProvider = FutureProvider.autoDispose
    .family<ApiFlagDetail, String>((ref, flagId) {
      return TeritoryRepository.instance.fetchFlagDetail(flagId);
    });
