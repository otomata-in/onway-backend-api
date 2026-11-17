import 'package:flutter/foundation.dart';
import '../models/api_clan.dart';
import '../models/api_flag.dart';
import '../models/api_trip.dart';
import '../models/api_user.dart';
import '../models/user_models.dart';
import '../models/clan_models.dart';
import '../models/community_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/leaderboard_models.dart';
import '../models/notification_models.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class TeritoryRepository {
  static final TeritoryRepository _instance = TeritoryRepository._internal();
  static TeritoryRepository get instance => _instance;

  TeritoryRepository._internal();

  final TeritoryApiService _api = TeritoryApiService.instance;

  // ─── AUTH & PROFILE ──────────────────────────────────────────────────

  Future<User?> loginWithOtp(String phone, String otp) async {
    try {
      final res = await _api.post('/auth/verify-otp', body: {
        'phone': phone,
        'otp': otp,
      });

      if (res is Map<String, dynamic> && res['accessToken'] != null) {
        await _api.saveToken(res['accessToken'] as String);
        return await fetchMyProfile();
      }
    } catch (e) {
      if (kDebugMode) print('❌ [TeritoryRepository.loginWithOtp] Error: $e');
    }
    return null;
  }

  Future<User> fetchMyProfile() async {
    try {
      final res = await _api.get('/users/me');
      if (res is Map<String, dynamic>) {
        return User.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [TeritoryRepository.fetchMyProfile] Falling back to mock: $e');
    }
    return MockDataService.instance.currentUser;
  }

  // ─── CLANS ───────────────────────────────────────────────────────────

  Future<List<Clan>> fetchClans() async {
    try {
      final res = await _api.get('/clans');
      if (res is List) {
        return res.map((e) => Clan.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchClans] Falling back to mock: $e');
    }
    return MockDataService.instance.clans;
  }

  Future<Clan?> fetchClanById(String id) async {
    try {
      final res = await _api.get('/clans/$id');
      if (res is Map<String, dynamic>) {
        return Clan.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchClanById] Falling back to mock: $e');
    }
    return MockDataService.instance.clanById(id);
  }

  // ─── COMMUNITIES ─────────────────────────────────────────────────────

  Future<List<Community>> fetchCommunities({String? clanId}) async {
    try {
      final res = await _api.get(
        '/communities',
        queryParams: clanId != null ? {'clanId': clanId} : null,
      );
      if (res is List) {
        return res.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchCommunities] Falling back to mock: $e');
    }
    return clanId != null
        ? MockDataService.instance.communitiesByClan(clanId)
        : MockDataService.instance.communities;
  }

  Future<Community?> fetchCommunityById(String id) async {
    try {
      final res = await _api.get('/communities/$id');
      if (res is Map<String, dynamic>) {
        return Community.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchCommunityById] Falling back to mock: $e');
    }
    return MockDataService.instance.communityById(id);
  }

  Future<List<CommunityMember>> fetchCommunityMembers(String id) async {
    try {
      final res = await _api.get('/communities/$id/members');
      if (res is List) {
        return res.map((e) {
          final m = e as Map<String, dynamic>;
          String uName = '';
          String uAvatar = '';
          if (m['user'] is Map) {
            uName = m['user']['displayName'] as String? ?? '';
            uAvatar = m['user']['avatarUrl'] as String? ?? '';
          }
          final roleStr = (m['role'] as String? ?? 'member').toLowerCase();
          CommunityRole role = CommunityRole.member;
          if (roleStr == 'creator') role = CommunityRole.creator;
          if (roleStr == 'moderator') role = CommunityRole.moderator;

          return CommunityMember(
            id: m['id'] as String? ?? '',
            communityId: m['communityId'] as String? ?? id,
            userId: m['userId'] as String? ?? '',
            userName: uName,
            userAvatar: uAvatar,
            role: role,
            joinedAt: m['joinedAt'] != null
                ? DateTime.parse(m['joinedAt'] as String)
                : DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchCommunityMembers] Falling back to mock: $e');
    }
    return MockDataService.instance.communityMembers(id);
  }

  Future<List<CommunityMessage>> fetchCommunityMessages(String id) async {
    try {
      final res = await _api.get('/communities/$id/messages');
      if (res is List) {
        return res
            .map((e) => CommunityMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchCommunityMessages] Falling back to mock: $e');
    }
    return MockDataService.instance.messagesByCommunity(id);
  }

  Future<CommunityMessage?> sendCommunityMessage(String id, String text) async {
    try {
      final res = await _api.post('/communities/$id/messages', body: {'text': text});
      if (res is Map<String, dynamic>) {
        return CommunityMessage.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('❌ [sendCommunityMessage] Error: $e');
    }
    return null;
  }

  // ─── TRIPS & PLANS ───────────────────────────────────────────────────

  Future<List<TripPlan>> fetchProposedTripPlans() async {
    try {
      final res = await _api.get('/trips/hub');
      if (res is Map<String, dynamic> && res['proposedPlans'] is List) {
        return (res['proposedPlans'] as List)
            .map((e) => TripPlan.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchProposedTripPlans] Falling back to mock: $e');
    }
    return MockDataService.instance.tripPlans;
  }

  Future<List<Trip>> fetchActiveTrips() async {
    try {
      final res = await _api.get('/trips/hub');
      if (res is Map<String, dynamic> && res['activeTrip'] != null) {
        return [Trip.fromJson(res['activeTrip'] as Map<String, dynamic>)];
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchActiveTrips] Falling back to mock: $e');
    }
    return MockDataService.instance.activeTrips
        .where((t) => t.status == TripStatus.active)
        .toList();
  }

  Future<Map<String, dynamic>?> validateWaypoint(
    String tripId,
    String waypointId,
    double lat,
    double lng,
  ) async {
    try {
      final res = await _api.post('/trips/$tripId/validate-waypoint', body: {
        'waypointId': waypointId,
        'latitude': lat,
        'longitude': lng,
      });
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      if (kDebugMode) print('❌ [validateWaypoint] Error: $e');
    }
    return null;
  }

  // ─── RANKINGS ────────────────────────────────────────────────────────

  /// Live-only rankings. The server requires the geo value for geo scopes and
  /// authentication for friends/clan/community, so its errors are surfaced
  /// rather than replaced with a mock board.
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    LeaderboardPeriod period = LeaderboardPeriod.alltime,
    String? country,
    String? state,
    String? district,
    int limit = 100,
  }) async {
    final res = await _api.get(
      '/rankings',
      queryParams: {
        'scope': scope.name.toUpperCase(),
        'period': period.name.toUpperCase(),
        if (country != null && country.isNotEmpty) 'country': country,
        if (state != null && state.isNotEmpty) 'state': state,
        if (district != null && district.isNotEmpty) 'district': district,
        'limit': limit,
      },
    );
    if (res is! List) {
      throw ApiException('Unexpected response while loading rankings');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }

  Future<MyRank> fetchMyRank() async {
    final res = await _api.get('/rankings/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading your rank');
    }
    return MyRank.fromJson(res);
  }

  // ─── RALLIES ─────────────────────────────────────────────────────────

  Future<List<LegendaryRally>> fetchRallies() async {
    try {
      final res = await _api.get('/rallies/nearby');
      if (res is List) {
        return res.map((e) => LegendaryRally.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchRallies] Falling back to mock: $e');
    }
    return MockDataService.instance.rallies;
  }

  // ─── SERVICES ────────────────────────────────────────────────────────

  Future<List<ServiceListing>> fetchServices() async {
    try {
      final res = await _api.get('/services/gear');
      if (res is List) {
        final List<ServiceListing> listings = [];
        for (final provider in res) {
          if (provider is Map<String, dynamic> && provider['listings'] is List) {
            final pName = provider['name'] as String? ?? '';
            final pId = provider['id'] as String? ?? '';
            final pLat = (provider['latitude'] as num?)?.toDouble() ?? 0.0;
            final pLng = (provider['longitude'] as num?)?.toDouble() ?? 0.0;
            final pRating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
            for (final l in provider['listings']) {
              if (l is Map<String, dynamic>) {
                listings.add(ServiceListing.fromJson({
                  ...l,
                  'providerId': pId,
                  'providerName': pName,
                  'latitude': pLat,
                  'longitude': pLng,
                  'rating': pRating,
                }));
              }
            }
          }
        }
        if (listings.isNotEmpty) return listings;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchServices] Falling back to mock: $e');
    }
    return MockDataService.instance.serviceListings;
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────

  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final res = await _api.get('/notifications');
      if (res is List) {
        return res.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchNotifications] Falling back to mock: $e');
    }
    return MockDataService.instance.notifications;
  }

  // ─── FRIENDS, SEARCH & INVITES ───────────────────────────────────────

  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await _api.get('/users/search', queryParams: {'q': query.trim()});
      if (res is List) {
        return res.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('❌ [searchUsers] Error: $e');
    }
    return [];
  }

  Future<bool> inviteFriends(List<String> targetUserIds, String type, String targetId) async {
    try {
      final res = await _api.post('/users/invites', body: {
        'targetUserIds': targetUserIds,
        'type': type,
        'targetId': targetId,
      });
      return res != null;
    } catch (e) {
      if (kDebugMode) print('❌ [inviteFriends] Error: $e');
    }
    return false;
  }

  Future<Community?> createCommunity({
    required String name,
    required String parentClanId,
    String description = '',
    List<String> interestTags = const [],
    bool isPublic = true,
    String? coverImageUrl,
  }) async {
    try {
      final res = await _api.post('/communities', body: {
        'name': name,
        'parentClanId': parentClanId,
        'description': description,
        'interestTags': interestTags,
        'isPublic': isPublic,
        'coverImageUrl': coverImageUrl ??
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      });
      if (res is Map<String, dynamic>) {
        return Community.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('❌ [createCommunity] Error: $e');
    }
    return null;
  }

  /// Creates a flag. Failures propagate as [ApiException] so the drop-flag
  /// sheet can show the server's own message; there is no success/failure
  /// boolean to misinterpret.
  Future<void> dropFlag({
    required String placeName,
    required double latitude,
    required double longitude,
    String city = '',
    String country = 'India',
    String countryCode = 'IN',
    String continent = 'Asia',
    bool isMajorFlag = false,
    String category = 'General',
    String notes = '',
    String? photoUrl,
  }) async {
    await _api.post('/flags', body: {
      'placeName': placeName,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'continent': continent,
      'latitude': latitude,
      'longitude': longitude,
      'isMajorFlag': isMajorFlag,
      'category': category,
      'notes': notes,
      'photoUrl': photoUrl,
    });
  }

  // ─── EXPLORE MAP (live-only, no mock fallback) ───────────────────────
  //
  // The methods below intentionally let ApiException propagate. Explore is the
  // first page migrated to "honest" data loading: the UI must be able to show a
  // retry state instead of silently rendering bundled sample pins.

  Future<List<ApiFlag>> fetchExploreFlags({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    String? category,
  }) async {
    final res = await _api.get(
      '/flags/explore',
      queryParams: {
        'lat': latitude,
        'lng': longitude,
        'radiusKm': radiusKm,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    if (res is! List) {
      throw ApiException('Unexpected response while loading flags');
    }

    return res
        .whereType<Map<String, dynamic>>()
        .map(ApiFlag.fromJson)
        .toList();
  }

  Future<ApiFlagDetail> fetchFlagDetail(String flagId) async {
    final res = await _api.get('/flags/$flagId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading flag detail');
    }
    return ApiFlagDetail.fromJson(res);
  }

  /// Toggles an `EPIC` / `HIDDEN_GEM` / `GREAT_SHOT` reaction.
  /// Returns the resulting state (`true` = now reacted).
  Future<bool> toggleFlagReaction(String flagId, String type) async {
    final res = await _api.post(
      '/flags/$flagId/reactions',
      body: {'type': type},
    );
    if (res is Map<String, dynamic>) {
      return res['reacted'] as bool? ?? false;
    }
    return false;
  }

  /// Increments kudos and returns the new total.
  Future<int> addFlagKudos(String flagId) async {
    final res = await _api.post('/flags/$flagId/kudos');
    if (res is Map<String, dynamic>) {
      return (res['kudos'] as num?)?.toInt() ?? 0;
    }
    throw ApiException('Unexpected response while recording kudos');
  }

  Future<ApiFlagComment> postFlagComment(String flagId, String text) async {
    final res = await _api.post(
      '/flags/$flagId/comments',
      body: {'text': text},
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while posting comment');
    }
    return ApiFlagComment.fromJson(res);
  }

  /// Accepted friend ids, used by the Explore "Friends" filter.
  Future<Set<String>> fetchFriendIds() async {
    final res = await _api.get('/users/friends');
    if (res is! List) {
      throw ApiException('Unexpected response while loading friends');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map((user) => user['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ─── CLANS (live-only, no mock fallback) ────────────────────────────

  Future<List<Clan>> fetchClansLive({String? search, String? region}) async {
    final res = await _api.get(
      '/clans',
      queryParams: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (region != null && region.trim().isNotEmpty)
          'region': region.trim(),
      },
    );
    if (res is! List) {
      throw ApiException('Unexpected response while loading clans');
    }
    return res.whereType<Map<String, dynamic>>().map(Clan.fromJson).toList();
  }

  Future<ApiClanDetail> fetchClanDetail(String clanId) async {
    final res = await _api.get('/clans/$clanId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading this clan');
    }
    return ApiClanDetail.fromJson(res);
  }

  /// Ids of the clans the signed-in traveler belongs to (`GET /clans/my`).
  Future<Set<String>> fetchMyClanIds() async {
    final res = await _api.get('/clans/my');
    if (res is! List) {
      throw ApiException('Unexpected response while loading your clans');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map((clan) => clan['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> joinClan(String clanId) async {
    await _api.post('/clans/$clanId/join');
  }

  Future<void> leaveClan(String clanId) async {
    await _api.post('/clans/$clanId/leave');
  }

  Future<Clan> createClan({
    required String name,
    String description = '',
    String region = '',
    String interestTag = '',
    String? coverImageUrl,
  }) async {
    final res = await _api.post('/clans', body: {
      'name': name,
      'description': description,
      'region': region,
      'interestTag': interestTag,
      if (coverImageUrl != null && coverImageUrl.isNotEmpty)
        'coverImageUrl': coverImageUrl,
    });
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while founding the clan');
    }
    return Clan.fromJson(res);
  }

  // ─── COMMUNITIES (live-only, no mock fallback) ─────────────────────

  Future<Community> fetchCommunityDetail(String communityId) async {
    final res = await _api.get('/communities/$communityId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading this community');
    }
    return Community.fromJson(res);
  }

  Future<List<CommunityMember>> fetchCommunityMembersLive(
      String communityId) async {
    final res = await _api.get('/communities/$communityId/members');
    if (res is! List) {
      throw ApiException('Unexpected response while loading community members');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(CommunityMember.fromJson)
        .toList();
  }

  Future<List<CommunityActivity>> fetchCommunityFeed(
      String communityId) async {
    final res = await _api.get('/communities/$communityId/feed');
    if (res is! List) {
      throw ApiException('Unexpected response while loading the community feed');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(CommunityActivity.fromJson)
        .toList();
  }

  Future<List<TripPlan>> fetchCommunityTripPlans(String communityId) async {
    final res = await _api.get('/communities/$communityId/trip-plans');
    if (res is! List) {
      throw ApiException('Unexpected response while loading trip plans');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(TripPlan.fromJson)
        .toList();
  }

  Future<List<CommunityMessage>> fetchCommunityMessagesLive(
      String communityId) async {
    final res = await _api.get('/communities/$communityId/messages');
    if (res is! List) {
      throw ApiException('Unexpected response while loading messages');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(CommunityMessage.fromJson)
        .toList();
  }

  Future<CommunityMessage> sendCommunityMessageLive(
      String communityId, String text) async {
    final res = await _api.post(
      '/communities/$communityId/messages',
      body: {'text': text},
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while sending your message');
    }
    return CommunityMessage.fromJson(res);
  }

  Future<void> joinCommunity(String communityId) async {
    await _api.post('/communities/$communityId/join');
  }

  Future<void> leaveCommunity(String communityId) async {
    await _api.post('/communities/$communityId/leave');
  }

  /// Toggles the signed-in traveler's vote; returns whether it is now voted.
  Future<bool> toggleTripPlanVote(String planId) async {
    final res = await _api.post('/trips/plans/$planId/vote');
    if (res is Map<String, dynamic> && res['voted'] is bool) {
      return res['voted'] as bool;
    }
    throw ApiException('Unexpected response while recording your vote');
  }

  Future<List<User>> fetchFriendsLive() async {
    final res = await _api.get('/users/friends');
    if (res is! List) {
      throw ApiException('Unexpected response while loading friends');
    }
    return res.whereType<Map<String, dynamic>>().map(User.fromJson).toList();
  }

  // ─── PROFILE & SOCIAL (live-only, no mock fallback) ──────────────────

  Future<ApiUser> fetchMyProfileLive() async {
    final res = await _api.get('/users/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading your profile');
    }
    return ApiUser.fromJson(res);
  }

  Future<ApiUser> fetchUserProfile(String userId) async {
    final res = await _api.get('/users/$userId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading this traveler');
    }
    return ApiUser.fromJson(res);
  }

  /// One traveler's footprint. `GET /flags?userId=` ignores the radius filters,
  /// so this works without a map centre.
  Future<List<ApiFlag>> fetchUserFlags(String userId) async {
    final res = await _api.get('/flags', queryParams: {'userId': userId});
    if (res is! List) {
      throw ApiException('Unexpected response while loading flags');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(ApiFlag.fromJson)
        .toList();
  }

  Future<List<ApiFriend>> fetchFriends() async {
    final res = await _api.get('/users/friends');
    if (res is! List) {
      throw ApiException('Unexpected response while loading friends');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(ApiFriend.fromJson)
        .toList();
  }

  Future<FriendRequestsSnapshot> fetchFriendRequests() async {
    final res = await _api.get('/users/friends/requests');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading friend requests');
    }
    return FriendRequestsSnapshot.fromJson(res);
  }

  Future<void> respondToFriendRequest(
    String relationshipId, {
    required bool accept,
  }) async {
    await _api.post(
      '/users/friends/requests/$relationshipId/respond',
      body: {'action': accept ? 'ACCEPT' : 'DECLINE'},
    );
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    await _api.post(
      '/users/friends/request',
      body: {'targetUserId': targetUserId},
    );
  }

  Future<void> cancelFriendRequest(String relationshipId) async {
    await _api.delete('/users/friends/requests/$relationshipId');
  }

  Future<void> removeFriend(String relationshipId) async {
    await _api.delete('/users/friends/$relationshipId');
  }

  /// `PATCH /users/me` with only the fields the caller changed.
  Future<ApiUser> updateMyProfile(Map<String, dynamic> changes) async {
    final res = await _api.patch('/users/me', body: changes);
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while saving your profile');
    }
    return ApiUser.fromJson(res);
  }

  // ─── TRIPS (live-only, no mock fallback) ───────────────────────────

  Future<TripsHubSnapshot> fetchTripsHub() async {
    final res = await _api.get('/trips/hub');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading your trips');
    }

    List<TripPlan> plans(Object? raw) => (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TripPlan.fromJson)
        .toList();

    final active = res['activeTrip'];
    return TripsHubSnapshot(
      activeTrip: active is Map<String, dynamic> ? Trip.fromJson(active) : null,
      proposedPlans: plans(res['proposedPlans']),
      savedPlans: plans(res['savedPlans']),
    );
  }

  Future<List<TripHistoryEntry>> fetchTripHistory() async {
    final res = await _api.get('/trips/history');
    if (res is! List) {
      throw ApiException('Unexpected response while loading trip history');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(TripHistoryEntry.fromJson)
        .toList();
  }

  Future<Trip> startTrip(String planId) async {
    final res = await _api.post('/trips/plans/$planId/start');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while starting the trip');
    }
    return Trip.fromJson(res);
  }

  Future<TripPlanDetail> fetchPlanDetail(String planId) async {
    final res = await _api.get('/trips/plans/$planId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading this plan');
    }
    return TripPlanDetail.fromJson(res);
  }

  Future<Set<String>> fetchSavedPlanIds() async {
    final res = await _api.get('/trips/plans/saved');
    if (res is! List) {
      throw ApiException('Unexpected response while loading saved plans');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map((plan) => plan['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Toggles the bookmark; returns whether the plan is now saved.
  Future<bool> togglePlanSaved(String planId) async {
    final res = await _api.post('/trips/plans/$planId/save');
    if (res is Map<String, dynamic> && res['isSaved'] is bool) {
      return res['isSaved'] as bool;
    }
    throw ApiException('Unexpected response while saving this plan');
  }

  Future<ActiveTripDetail> fetchActiveTripDetail(
    String tripId, {
    String? userId,
  }) async {
    final res = await _api.get('/trips/$tripId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading this trip');
    }
    return ActiveTripDetail.fromJson(res, userId: userId);
  }

  Future<WaypointValidationResult> validateWaypointAt({
    required String tripId,
    required String waypointId,
    required double latitude,
    required double longitude,
  }) async {
    final res = await _api.post('/trips/$tripId/validate-waypoint', body: {
      'waypointId': waypointId,
      'latitude': latitude,
      'longitude': longitude,
    });
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while validating this waypoint');
    }
    return WaypointValidationResult.fromJson(res);
  }

  Future<void> completeTrip(String tripId) async {
    await _api.post('/trips/$tripId/complete');
  }

  Future<List<TripPlan>> fetchSavedPlans() async {
    final res = await _api.get('/trips/plans/saved');
    if (res is! List) {
      throw ApiException('Unexpected response while loading saved plans');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(TripPlan.fromJson)
        .toList();
  }

  /// Creates a plan and lets [ApiException] through, unlike the legacy
  /// `createTripPlan` that returned null and looked like success.
  Future<TripPlan> createPlan({
    required String name,
    required String originName,
    required String destinationName,
    String description = '',
    String? communityId,
    double totalDistanceKm = 0.0,
    int estimatedDays = 1,
    List<Map<String, dynamic>> waypoints = const [],
  }) async {
    final res = await _api.post('/trips/plans', body: {
      'name': name,
      'description': description,
      'originName': originName,
      'destinationName': destinationName,
      'communityId': ?communityId,
      'totalDistanceKm': totalDistanceKm,
      'estimatedDays': estimatedDays,
      'waypoints': waypoints,
    });
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while creating this plan');
    }
    return TripPlan.fromJson(res);
  }

  /// Live community list with no mock fallback, used by the planner's
  /// optional community selector.
  Future<List<Community>> fetchCommunitiesLive() async {
    final res = await _api.get('/communities');
    final list = res is Map<String, dynamic> ? res['communities'] : res;
    if (list is! List) {
      throw ApiException('Unexpected response while loading communities');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Community.fromJson)
        .toList();
  }

  // Legacy `createTripPlan` removed with the planner migration: it swallowed
  // errors and returned null, which the UI reported as success.

  /// Community invite flow: unlike the fire-and-forget `inviteFriends`, failures
  /// propagate and the number of invitations actually created is returned.
  Future<int> sendInvites({
    required List<String> userIds,
    required String type,
    String? targetId,
  }) async {
    final res = await _api.post('/users/invites', body: {
      'targetUserIds': userIds,
      'type': type,
      'targetId': targetId,
    });
    if (res is Map<String, dynamic> && res['invitedCount'] is int) {
      return res['invitedCount'] as int;
    }
    throw ApiException('Unexpected response while sending invitations');
  }
}
