import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/community_models.dart';
import '../../../core/models/trip_models.dart';
import '../../../core/models/user_models.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/teritory_repository.dart';

final communityDetailProvider =
    FutureProvider.autoDispose.family<Community, String>((ref, communityId) {
  return TeritoryRepository.instance.fetchCommunityDetail(communityId);
});

final communityMembersLiveProvider = FutureProvider.autoDispose
    .family<List<CommunityMember>, String>((ref, communityId) {
  return TeritoryRepository.instance.fetchCommunityMembersLive(communityId);
});

final communityFeedProvider = FutureProvider.autoDispose
    .family<List<CommunityActivity>, String>((ref, communityId) {
  return TeritoryRepository.instance.fetchCommunityFeed(communityId);
});

final communityPlansProvider = FutureProvider.autoDispose
    .family<List<TripPlan>, String>((ref, communityId) {
  return TeritoryRepository.instance.fetchCommunityTripPlans(communityId);
});

/// Friends available to invite (live `GET /users/friends`).
final inviteCandidatesProvider =
    FutureProvider.autoDispose<List<User>>((ref) {
  return TeritoryRepository.instance.fetchFriendsLive();
});

/// Community chat: history from the API, new messages also arriving over the
/// socket. Sends await the POST and let `ApiException` reach the caller.
class CommunityMessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CommunityMessage>, String> {
  StreamSubscription<CommunityMessage>? _subscription;

  @override
  Future<List<CommunityMessage>> build(String communityId) async {
    SocketService.instance.joinCommunity(communityId);
    _subscription = SocketService.instance.messageStream.listen((message) {
      if (message.communityId != communityId) return;
      final current = state.valueOrNull ?? const <CommunityMessage>[];
      if (current.any((existing) => existing.id == message.id)) return;
      state = AsyncData([...current, message]);
    });

    ref.onDispose(() {
      _subscription?.cancel();
      SocketService.instance.leaveCommunity(communityId);
    });

    return TeritoryRepository.instance
        .fetchCommunityMessagesLive(communityId);
  }

  Future<void> sendMessage(String text) async {
    final message = await TeritoryRepository.instance
        .sendCommunityMessageLive(arg, text);
    final current = state.valueOrNull ?? const <CommunityMessage>[];
    if (!current.any((existing) => existing.id == message.id)) {
      state = AsyncData([...current, message]);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<CommunityMessage>>().copyWithPrevious(state);
    final next = await AsyncValue.guard(
        () => TeritoryRepository.instance.fetchCommunityMessagesLive(arg));
    state = next.copyWithPrevious(state);
  }
}

final communityMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityMessagesNotifier, List<CommunityMessage>, String>(
  CommunityMessagesNotifier.new,
);
