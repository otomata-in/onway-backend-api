import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/community_models.dart';
import '../../../core/models/leaderboard_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';

/// Country/state/district values taken from the live standings, so the filters
/// can only offer places that actually have ranked travelers.
class RankingsFacets {
  final List<String> countries;
  final List<String> states;
  final List<String> districts;

  const RankingsFacets({
    required this.countries,
    required this.states,
    required this.districts,
  });
}

final rankingsFacetsProvider =
    FutureProvider.autoDispose<RankingsFacets>((ref) async {
  final entries =
      await TeritoryRepository.instance.fetchLeaderboard(limit: 200);

  List<String> distinct(Iterable<String> values) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    result.sort();
    return result;
  }

  return RankingsFacets(
    countries: distinct(entries.map((e) => e.country)),
    states: distinct(entries.map((e) => e.state)),
    districts: distinct(entries.map((e) => e.district)),
  );
});

final rankingsProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, LeaderboardQuery>((ref, query) {
  return TeritoryRepository.instance.fetchLeaderboard(
    scope: query.scope,
    period: query.period,
    country: query.country,
    state: query.state,
    district: query.district,
    clanId: query.clanId,
    communityId: query.communityId,
    page: query.page,
  );
});

final myRankProvider = FutureProvider.autoDispose<MyRank>((ref) {
  return TeritoryRepository.instance.fetchMyRank();
});

/// Communities the signed-in traveler belongs to, used by the leaderboard
/// scope selector.
final myCommunitiesProvider =
    FutureProvider.autoDispose<List<Community>>((ref) {
  return TeritoryRepository.instance.fetchMyCommunities();
});

/// Mutable page state for one leaderboard filter combination.
class LeaderboardFeedState {
  final List<LeaderboardEntry> entries;
  final bool hasMore;
  final bool loadingMore;
  final int total;
  final String? loadMoreError;

  const LeaderboardFeedState({
    required this.entries,
    required this.hasMore,
    this.loadingMore = false,
    this.total = 0,
    this.loadMoreError,
  });

  LeaderboardFeedState copyWith({
    bool? hasMore,
    bool? loadingMore,
    int? total,
    String? loadMoreError,
    bool clearError = false,
  }) {
    return LeaderboardFeedState(
      entries: entries,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      total: total ?? this.total,
      loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

/// Pages the leaderboard without refetching page 1. The server ranks the full
/// set before slicing, so appended entries keep their global ranks.
class LeaderboardFeedNotifier
    extends AutoDisposeFamilyAsyncNotifier<LeaderboardFeedState, LeaderboardQuery> {
  int _page = 1;

  @override
  Future<LeaderboardFeedState> build(LeaderboardQuery query) async {
    _page = 1;
    final page = await _fetch(query, 1);
    return LeaderboardFeedState(
      entries: page.entries,
      hasMore: page.hasMore,
      total: page.total,
    );
  }

  Future<LeaderboardPage> _fetch(LeaderboardQuery query, int page) {
    return TeritoryRepository.instance.fetchLeaderboardPage(
      scope: query.scope,
      period: query.period,
      country: query.country,
      state: query.state,
      district: query.district,
      clanId: query.clanId,
      communityId: query.communityId,
      page: page,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true, clearError: true));
    try {
      final next = await _fetch(arg, _page + 1);
      final seen = current.entries.map((entry) => entry.userId).toSet();
      final merged = [
        ...current.entries,
        ...next.entries.where((entry) => !seen.contains(entry.userId)),
      ];
      _page += 1;
      state = AsyncData(
        LeaderboardFeedState(
          entries: merged,
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          loadingMore: false,
          loadMoreError: error is ApiException
              ? error.message
              : 'Could not load more rankings.',
        ),
      );
    }
  }
}

final leaderboardFeedProvider = AsyncNotifierProvider.autoDispose.family<
    LeaderboardFeedNotifier, LeaderboardFeedState, LeaderboardQuery>(
  LeaderboardFeedNotifier.new,
);
