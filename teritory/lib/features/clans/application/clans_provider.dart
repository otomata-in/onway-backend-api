import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_clan.dart';
import '../../../core/models/clan_models.dart';
import '../../../core/services/teritory_repository.dart';

/// Clans plus the signed-in traveler's memberships, in one render pass.
class ClansData {
  final List<Clan> clans;
  final Set<String> myClanIds;

  const ClansData({required this.clans, required this.myClanIds});

  bool isMember(String clanId) => myClanIds.contains(clanId);

  List<Clan> get myClans =>
      clans.where((clan) => myClanIds.contains(clan.id)).toList();

  ClansData _copyWith({List<Clan>? clans, Set<String>? myClanIds}) =>
      ClansData(
        clans: clans ?? this.clans,
        myClanIds: myClanIds ?? this.myClanIds,
      );
}

class ClansNotifier extends AsyncNotifier<ClansData> {
  @override
  Future<ClansData> build() => _load();

  Future<ClansData> _load() async {
    final repository = TeritoryRepository.instance;

    // Membership is an enhancement: without it the list still renders and every
    // clan simply shows "Join".
    final myClanIdsFuture =
        repository.fetchMyClanIds().catchError((_) => <String>{});

    final clans = await repository.fetchClansLive();
    return ClansData(clans: clans, myClanIds: await myClanIdsFuture);
  }

  /// Keeps the current list on screen while reloading, and after a failed reload.
  Future<void> refresh() async {
    state = const AsyncLoading<ClansData>().copyWithPrevious(state);
    final next = await AsyncValue.guard(_load);
    state = next.copyWithPrevious(state);
  }

  /// Joins or leaves, then applies the result locally so the button and member
  /// count update without a second round trip.
  Future<void> toggleMembership(String clanId) async {
    final before = state.valueOrNull;
    if (before == null) return;

    final joining = !before.isMember(clanId);
    if (joining) {
      await TeritoryRepository.instance.joinClan(clanId);
    } else {
      await TeritoryRepository.instance.leaveClan(clanId);
    }

    // A refresh may have finished while the POST was in flight; patch the newest
    // state and never double-count a change the server already reported.
    final latest = state.valueOrNull ?? before;
    if (latest.isMember(clanId) == joining) return;

    final ids = Set<String>.of(latest.myClanIds);
    if (joining) {
      ids.add(clanId);
    } else {
      ids.remove(clanId);
    }

    state = AsyncData(latest._copyWith(
      myClanIds: ids,
      clans: [
        for (final clan in latest.clans)
          if (clan.id == clanId)
            clan.copyWith(
              memberCount: joining
                  ? clan.memberCount + 1
                  : (clan.memberCount > 0 ? clan.memberCount - 1 : 0),
            )
          else
            clan,
      ],
    ));
  }

  Future<Clan> createClan({
    required String name,
    String description = '',
    String region = '',
    String interestTag = '',
    String? coverImageUrl,
  }) async {
    final clan = await TeritoryRepository.instance.createClan(
      name: name,
      description: description,
      region: region,
      interestTag: interestTag,
      coverImageUrl: coverImageUrl,
    );

    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncData(data._copyWith(
        clans: [clan, ...data.clans],
        myClanIds: {...data.myClanIds, clan.id},
      ));
    }
    return clan;
  }
}

final clansProvider = AsyncNotifierProvider<ClansNotifier, ClansData>(
  ClansNotifier.new,
);

/// Clan header, communities and member roster from `GET /clans/:id`.
///
/// After a membership change the detail is invalidated, so its count and roster
/// come from the server instead of being guessed locally.
final clanDetailProvider =
    FutureProvider.autoDispose.family<ApiClanDetail, String>((ref, clanId) {
  return TeritoryRepository.instance.fetchClanDetail(clanId);
});
