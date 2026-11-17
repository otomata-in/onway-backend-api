import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_flag.dart';
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
  /// Map centre used for the explore query (Kochi). Replace with device
  /// geolocation once location permission plumbing lands.
  static const double centerLat = 9.9790;
  static const double centerLng = 76.2760;
  static const double radiusKm = 100;

  @override
  Future<ExploreFlagsData> build() => _load();

  Future<ExploreFlagsData> _load() async {
    final repository = TeritoryRepository.instance;

    // Friend ids are an enhancement, not a requirement: if that call fails the
    // map still renders live flags, and the Friends filter simply stays empty.
    final friendIdsFuture =
        repository.fetchFriendIds().catchError((_) => <String>{});

    // Both requests are in flight; awaiting the flags first keeps their
    // ApiException intact instead of wrapping it in ParallelWaitError.
    final flags = await repository.fetchExploreFlags(
      latitude: centerLat,
      longitude: centerLng,
      radiusKm: radiusKm,
    );
    final friendIds = await friendIdsFuture;

    return ExploreFlagsData(flags: flags, friendIds: friendIds);
  }

  /// Reloads without dropping the pins already on screen: the previous data is
  /// carried into the loading state and also kept if the refresh fails, so the
  /// map shows stale-but-real flags plus a retry banner instead of going blank.
  Future<void> refresh() async {
    state = const AsyncLoading<ExploreFlagsData>().copyWithPrevious(state);
    final next = await AsyncValue.guard(_load);
    state = next.copyWithPrevious(state);
  }
}

final exploreFlagsProvider =
    AsyncNotifierProvider<ExploreFlagsNotifier, ExploreFlagsData>(
  ExploreFlagsNotifier.new,
);

/// Full social payload for one flag, loaded on demand by the detail sheet.
final flagDetailProvider =
    FutureProvider.autoDispose.family<ApiFlagDetail, String>((ref, flagId) {
  return TeritoryRepository.instance.fetchFlagDetail(flagId);
});
