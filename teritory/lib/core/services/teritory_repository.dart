import 'package:flutter/foundation.dart';
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

  Future<List<TripPlan>> fetchSavedPlans() async {
    try {
      final res = await _api.get('/trips/plans/saved');
      if (res is List) {
        return res.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchSavedPlans] Falling back to mock: $e');
    }
    return MockDataService.instance.savedPlans;
  }

  Future<bool> toggleSavePlan(String planId) async {
    try {
      final res = await _api.post('/trips/plans/$planId/save');
      if (res is Map<String, dynamic> && res['isSaved'] != null) {
        return res['isSaved'] as bool;
      }
    } catch (e) {
      if (kDebugMode) print('❌ [toggleSavePlan] Error: $e');
    }
    return false;
  }

  Future<bool> voteTripPlan(String planId) async {
    try {
      await _api.post('/trips/plans/$planId/vote');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ [voteTripPlan] Error: $e');
    }
    return false;
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

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    LeaderboardPeriod period = LeaderboardPeriod.alltime,
  }) async {
    try {
      final res = await _api.get(
        '/rankings',
        queryParams: {
          'scope': scope.name.toUpperCase(),
          'period': period.name.toUpperCase(),
        },
      );
      if (res is List) {
        return res.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [fetchLeaderboard] Falling back to mock: $e');
    }
    return MockDataService.instance.leaderboard(scope, period);
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
}
