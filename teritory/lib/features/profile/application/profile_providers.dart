import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/api_user.dart';
import '../../../core/services/teritory_repository.dart';

/// Live-only profile/social providers. `ApiException` propagates so each screen
/// can render the server message with a retry, instead of sample rows.

final myProfileProvider = FutureProvider.autoDispose<ApiUser>((ref) {
  return TeritoryRepository.instance.fetchMyProfileLive();
});

final userProfileProvider =
    FutureProvider.autoDispose.family<ApiUser, String>((ref, userId) {
  return TeritoryRepository.instance.fetchUserProfile(userId);
});

final userFlagsProvider =
    FutureProvider.autoDispose.family<List<ApiFlag>, String>((ref, userId) {
  return TeritoryRepository.instance.fetchUserFlags(userId);
});

final friendsLiveProvider = FutureProvider.autoDispose<List<ApiFriend>>((ref) {
  return TeritoryRepository.instance.fetchFriends();
});

final friendRequestsLiveProvider =
    FutureProvider.autoDispose<FriendRequestsSnapshot>((ref) {
  return TeritoryRepository.instance.fetchFriendRequests();
});
