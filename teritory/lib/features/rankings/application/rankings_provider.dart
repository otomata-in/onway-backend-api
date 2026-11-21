import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/leaderboard_models.dart';
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
