import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_clan.dart';
import '../models/api_flag.dart';
import '../models/api_trip.dart';
import '../models/api_user.dart';
import '../models/flag_style.dart';
import '../models/user_models.dart';
import '../models/clan_models.dart';
import '../models/community_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/leaderboard_models.dart';
import '../models/notification_models.dart';
import '../models/search_models.dart';
import 'api_service.dart';
import 'offline_cache_service.dart';

class TeritoryRepository {
  static final TeritoryRepository _instance = TeritoryRepository._internal();
  static TeritoryRepository get instance => _instance;

  TeritoryRepository._internal();

  final TeritoryApiService _api = TeritoryApiService.instance;

  // ─── AUTH & PROFILE ──────────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    await _api.post('/auth/send-otp', body: {'phone': phone});
  }

  /// Signs in and returns the live profile. Errors propagate so the login
  /// screen can show the server message instead of failing silently.
  Future<User> loginWithOtp(String phone, String otp) async {
    final res = await _api.post(
      '/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );

    if (res is! Map<String, dynamic> || res['accessToken'] == null) {
      throw ApiException('Sign-in failed: the server did not return a session');
    }

    await _api.saveTokens(
      accessToken: res['accessToken'] as String,
      refreshToken: res['refreshToken'] as String?,
    );
    return fetchMyProfileOrThrow();
  }

  /// Live-only profile read: throws [ApiException] so callers can show the
  /// server message and a retry.
  Future<User> fetchMyProfileOrThrow() async {
    final res = await _api.get('/users/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading your profile');
    }
    return User.fromJson(res);
  }

  /// Revokes the refresh token server-side, then clears the local session.
  Future<void> logout() async {
    try {
      await _api.post(
        '/auth/logout',
        body: {'refreshToken': _api.refreshToken},
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [TeritoryRepository.logout] Server revoke failed: $e');
      }
    } finally {
      await _api.clearTokens();
    }
  }

  /// Toggles the "On a trip" state shown to friends; returns the stored value.
  Future<bool> setTripMode(bool enabled) async {
    final res = await _api.patch(
      '/users/me/trip-mode',
      body: {'isTripMode': enabled},
    );
    if (res is Map<String, dynamic> && res['isTripMode'] is bool) {
      return res['isTripMode'] as bool;
    }
    throw ApiException('Unexpected response while updating trip mode');
  }

  /// Registers or refreshes the device's Push Notification (FCM) token.
  Future<void> updateFcmToken(String fcmToken) async {
    await _api.patch('/users/me', body: {'fcmToken': fcmToken});
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
    String? clanId,
    String? communityId,
    int limit = 100,
    int page = 1,
  }) async {
    final result = await fetchLeaderboardPage(
      scope: scope,
      period: period,
      country: country,
      state: state,
      district: district,
      clanId: clanId,
      communityId: communityId,
      limit: limit,
      page: page,
    );
    return result.entries;
  }

  /// One page of rankings plus the server's `meta` paging flags.
  Future<LeaderboardPage> fetchLeaderboardPage({
    LeaderboardScope scope = LeaderboardScope.global,
    LeaderboardPeriod period = LeaderboardPeriod.alltime,
    String? country,
    String? state,
    String? district,
    String? clanId,
    String? communityId,
    int limit = 50,
    int page = 1,
  }) async {
    final envelope = await _api.getEnvelope(
      '/rankings',
      queryParams: {
        'scope': scope.name.toUpperCase(),
        'period': period.name.toUpperCase(),
        if (country != null && country.isNotEmpty) 'country': country,
        if (state != null && state.isNotEmpty) 'state': state,
        if (district != null && district.isNotEmpty) 'district': district,
        if (clanId != null && clanId.isNotEmpty) 'clanId': clanId,
        if (communityId != null && communityId.isNotEmpty)
          'communityId': communityId,
        'limit': limit,
        'page': page,
      },
    );
    final res = envelope['data'];
    if (res is! List) {
      throw ApiException('Unexpected response while loading rankings');
    }
    final meta = envelope['meta'] is Map
        ? (envelope['meta'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return LeaderboardPage(
      entries: res
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList(),
      hasMore: meta['hasMore'] == true,
      total: (meta['total'] as num?)?.toInt() ?? res.length,
      page: (meta['page'] as num?)?.toInt() ?? page,
    );
  }

  /// Communities the signed-in traveler belongs to, for scoped filters.
  Future<List<Community>> fetchMyCommunities() async {
    final res = await _api.get('/communities/mine');
    if (res is! List) {
      throw ApiException('Unexpected response while loading your communities');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(Community.fromJson)
        .toList();
  }

  Future<MyRank> fetchMyRank() async {
    final res = await _api.get('/rankings/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading your rank');
    }
    return MyRank.fromJson(res);
  }

  // ─── LEGENDARY RALLIES (live-only, no mock fallback) ─────────────────

  Future<List<LegendaryRally>> fetchNearbyRallies({
    double? latitude,
    double? longitude,
    double radiusKm = 100,
  }) async {
    final res = await _api.get(
      '/rallies/nearby',
      queryParams: {
        if (latitude != null && longitude != null) 'lat': latitude,
        if (latitude != null && longitude != null) 'lng': longitude,
        if (latitude != null && longitude != null) 'radiusKm': radiusKm,
      },
    );
    if (res is! List) {
      throw ApiException('Unexpected response while loading rallies');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(LegendaryRally.fromJson)
        .toList();
  }

  Future<RallyDetail> fetchRallyDetail(
    String rallyId, {
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.get(
      '/rallies/$rallyId',
      queryParams: {
        if (latitude != null && longitude != null) 'lat': latitude,
        if (latitude != null && longitude != null) 'lng': longitude,
      },
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading the rally');
    }
    return RallyDetail.fromJson(res);
  }

  Future<LegendaryRally> createRally({
    required String name,
    required String placeName,
    required double latitude,
    required double longitude,
    String description = '',
    int minParticipants = 2,
    int expiresHours = 2,
  }) async {
    final res = await _api.post(
      '/rallies',
      body: {
        'name': name,
        'description': description,
        'placeName': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'minParticipants': minParticipants,
        'expiresHours': expiresHours,
      },
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while creating the rally');
    }
    return LegendaryRally.fromJson(res);
  }

  Future<void> joinRally(String rallyId) async {
    await _api.post('/rallies/$rallyId/join');
  }

  Future<RallyArrivalResult> markRallyArrival(
    String rallyId, {
    required double latitude,
    required double longitude,
  }) async {
    final res = await _api.post(
      '/rallies/$rallyId/arrive',
      body: {'latitude': latitude, 'longitude': longitude},
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while checking your arrival');
    }
    return RallyArrivalResult.fromJson(res);
  }

  Future<void> completeRally(String rallyId) async {
    await _api.post('/rallies/$rallyId/complete');
  }

  /// Legacy mock-fallback getter kept for the still-mock rally surfaces.

  // ─── SERVICES ────────────────────────────────────────────────────────

  /// Live `GET /services/gear`, distance-sorted by the API when a centre is
  /// supplied. Throws [ApiException] so the sheet can show the server message.
  Future<List<ServiceProvider>> fetchGearProviders({
    double? latitude,
    double? longitude,
  }) => _fetchServiceProviders(
    '/services/gear',
    latitude: latitude,
    longitude: longitude,
  );

  /// Live `GET /services/nearby-food` (the API keeps a 10 km radius).
  Future<List<ServiceProvider>> fetchNearbyFoodProviders({
    double? latitude,
    double? longitude,
  }) => _fetchServiceProviders(
    '/services/nearby-food',
    latitude: latitude,
    longitude: longitude,
  );

  Future<List<ServiceProvider>> _fetchServiceProviders(
    String path, {
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.get(
      path,
      queryParams: {
        if (latitude != null && longitude != null) ...{
          'lat': latitude.toStringAsFixed(5),
          'lng': longitude.toStringAsFixed(5),
        },
      },
    );
    if (res is! List) {
      throw ApiException('Unexpected response while loading nearby services');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(ServiceProvider.fromJson)
        .toList();
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────

  /// Live-only notification read: throws [ApiException] so the bell and the
  /// notifications screen show the server's own message instead of mock rows.
  Future<List<NotificationItem>> fetchNotifications() async {
    final res = await _api.get('/notifications');
    if (res is! List) {
      throw ApiException('Unexpected response while loading notifications');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.patch('/notifications/read-all');
  }

  // ─── FRIENDS, SEARCH & INVITES ───────────────────────────────────────

  /// Live-only people search. An empty query short-circuits locally; every
  /// other outcome is the server's, including failures, which propagate as
  /// [ApiException] so callers can show the real message.
  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _api.get(
      '/users/search',
      queryParams: {'q': query.trim()},
    );
    if (res is! List) {
      throw ApiException('Unexpected response while searching travellers');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  /// Omni-Search across flags, travelers, clans, and places.
  Future<OmniSearchResult> searchOmni({
    required String query,
    String type = 'all',
  }) async {
    final trimmed = query.trim();
    List<ApiFlag> flags = [];
    List<ApiUser> users = [];
    List<Clan> clans = [];
    List<SearchLocation> locations = [];

    try {
      final res = await _api.get(
        '/search',
        queryParams: {
          'q': trimmed,
          'type': type,
        },
      );
      if (res is Map<String, dynamic>) {
        if (res['flags'] is List) {
          flags = (res['flags'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ApiFlag.fromJson)
              .toList();
        }
        if (res['users'] is List) {
          users = (res['users'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ApiUser.fromJson)
              .toList();
        }
        if (res['clans'] is List) {
          clans = (res['clans'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Clan.fromJson)
              .toList();
        }
        if (res['locations'] is List) {
          locations = (res['locations'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SearchLocation.fromJson)
              .toList();
        }
      }
    } catch (_) {
      // Fallback if unified /search is not yet reached
      if (trimmed.isNotEmpty) {
        final flagResults = await searchFlags(trimmed).catchError((_) => <ApiFlag>[]);
        final clanResults = await fetchClansLive(search: trimmed).catchError((_) => <Clan>[]);
        flags = flagResults;
        clans = clanResults;
      }
    }

    // Geocoding enrichment for global destinations
    if (trimmed.length >= 3 && (type == 'all' || type == 'places')) {
      try {
        final geocoded = await geocodeLocation(trimmed);
        if (geocoded != null) {
          // Avoid duplicate if same city already in locations
          final exists = locations.any(
            (l) => l.title.toLowerCase() == geocoded.title.toLowerCase(),
          );
          if (!exists) {
            locations.insert(0, geocoded);
          }
        }
      } catch (_) {}
    }

    return OmniSearchResult(
      flags: flags,
      users: users,
      clans: clans,
      locations: locations,
    );
  }

  /// Direct flag search by query (`GET /flags/search?q=...`)
  Future<List<ApiFlag>> searchFlags(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    try {
      final res = await _api.get(
        '/flags/search',
        queryParams: {'q': trimmed},
      );
      if (res is! List) return [];
      return res
          .whereType<Map<String, dynamic>>()
          .map(ApiFlag.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Worldwide OpenStreetMap Nominatim geocoding lookup
  Future<SearchLocation?> geocodeLocation(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'TeritoryApp/1.0.0 (com.onway.teritory)',
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List && list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.tryParse('${first['lat']}');
          final lon = double.tryParse('${first['lon']}');
          if (lat != null && lon != null) {
            final name = '${first['display_name']}';
            final parts = name.split(',');
            final title = parts.first.trim();
            final subtitle = parts.length > 1
                ? parts.sublist(1, math.min(3, parts.length)).join(',').trim()
                : '';
            return SearchLocation(
              title: title,
              subtitle: subtitle,
              latitude: lat,
              longitude: lon,
              isGeocoded: true,
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Founds a community. Returns the created row or throws [ApiException]
  /// carrying the server's validation message so the create screen can show it.
  Future<Community> createCommunity({
    required String name,
    required String parentClanId,
    String description = '',
    List<String> interestTags = const [],
    bool isPublic = true,
    String? coverImageUrl,
  }) async {
    final res = await _api.post(
      '/communities',
      body: {
        'name': name,
        'parentClanId': parentClanId,
        'description': description,
        'interestTags': interestTags,
        'isPublic': isPublic,
        // No stock default: an empty cover is rendered as a gradient by the UI,
        // so every community does not share the same stock photo.
        if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
          'coverImageUrl': coverImageUrl.trim(),
      },
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while creating the community');
    }
    return Community.fromJson(res);
  }

  // ─── UPLOAD ──────────────────────────────────────────────────────────

  /// Uploads an image file and returns the server-relative URL
  /// (e.g. `/uploads/abc123.jpg`).
  Future<String> uploadImage(String filePath) async {
    final res = await _api.uploadFile('/upload', filePath: filePath);
    if (res is Map<String, dynamic> && res['url'] is String) {
      return res['url'] as String;
    }
    throw ApiException('Unexpected response from upload endpoint');
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
    FlagStyle? flagStyle,
  }) async {
    await _api.post(
      '/flags',
      body: {
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
        // Omitted when the flag should use the traveller's signature; the
        // server resolves signature then product default and always stores a
        // concrete snapshot.
        if (flagStyle != null) 'flagStyle': flagStyle.toJson(),
      },
    );
  }

  /// Removes a flag staked by the current user.
  Future<void> deleteFlag(String flagId) async {
    await _api.delete('/flags/$flagId');
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

    return res.whereType<Map<String, dynamic>>().map(ApiFlag.fromJson).toList();
  }

  /// Hidden gems within 5 km of a point (`GET /flags/sub-territories`). The
  /// server sorts by HIDDEN_GEM reactions, then distance, and returns
  /// `distanceKm`/`hiddenGemCount` per row.
  Future<List<ApiFlag>> fetchSubTerritories({
    required double latitude,
    required double longitude,
  }) async {
    final res = await _api.get(
      '/flags/sub-territories',
      queryParams: {'lat': latitude, 'lng': longitude},
    );
    if (res is! List) {
      throw ApiException('Unexpected response while loading sub-territories');
    }
    return res.whereType<Map<String, dynamic>>().map(ApiFlag.fromJson).toList();
  }

  Future<ApiFlagDetail> fetchFlagDetail(String flagId) async {
    final res = await _api.get('/flags/$flagId');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while loading flag detail');
    }
    return ApiFlagDetail.fromJson(res);
  }

  /// Toggles saving a flag to the traveler's wishlist (`POST /flags/:id/save`).
  Future<bool> toggleSaveFlag(String flagId) async {
    final res = await _api.post('/flags/$flagId/save');
    if (res is Map<String, dynamic> && res['isSaved'] is bool) {
      return res['isSaved'] as bool;
    }
    throw ApiException('Unexpected response while saving this flag');
  }

  /// Loads flags saved to the traveler's wishlist (`GET /flags/saved`).
  Future<List<ApiFlag>> fetchSavedFlags() async {
    try {
      final res = await _api.get('/flags/saved');
      if (res is List) {
        final list = res.whereType<Map<String, dynamic>>().toList();
        OfflineCacheService.instance.cacheSavedFlags(list);
        return list.map(ApiFlag.fromJson).toList();
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached = await OfflineCacheService.instance.getCachedSavedFlags();
      if (cached != null) {
        return cached.map(ApiFlag.fromJson).toList();
      }
      rethrow;
    }
    throw ApiException('Unexpected response while loading saved flags');
  }

  /// Major wonders registry (`GET /flags/wonders`), derived server-side from
  /// flags staked as major wonders. Live-only: no bundled catalogue exists.
  Future<List<ApiWonder>> fetchWonders() async {
    final res = await _api.get('/flags/wonders');
    if (res is! List) {
      throw ApiException(
        'Unexpected response while loading the wonders registry',
      );
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(ApiWonder.fromJson)
        .toList();
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
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
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
    final res = await _api.post(
      '/clans',
      body: {
        'name': name,
        'description': description,
        'region': region,
        'interestTag': interestTag,
        if (coverImageUrl != null && coverImageUrl.isNotEmpty)
          'coverImageUrl': coverImageUrl,
      },
    );
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
    String communityId,
  ) async {
    final res = await _api.get('/communities/$communityId/members');
    if (res is! List) {
      throw ApiException('Unexpected response while loading community members');
    }
    return res
        .whereType<Map<String, dynamic>>()
        .map(CommunityMember.fromJson)
        .toList();
  }

  Future<List<CommunityActivity>> fetchCommunityFeed(String communityId) async {
    final res = await _api.get('/communities/$communityId/feed');
    if (res is! List) {
      throw ApiException(
        'Unexpected response while loading the community feed',
      );
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
    String communityId,
  ) async {
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
    String communityId,
    String text, {
    String? imageUrl,
  }) async {
    final res = await _api.post(
      '/communities/$communityId/messages',
      body: {
        'text': text,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
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
    return res.whereType<Map<String, dynamic>>().map(ApiFlag.fromJson).toList();
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

  /// `PATCH /users/me` with only the fields the caller changed; the backend
  /// ignores any key outside its allow-list.
  Future<ApiUser> updateMyProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverImageUrl,
    String? country,
    String? state,
    String? district,
    String? mapStyle,
    bool? isPrivate,
  }) async {
    final changes = <String, dynamic>{
      'displayName': ?displayName,
      'bio': ?bio,
      'avatarUrl': ?avatarUrl,
      'coverImageUrl': ?coverImageUrl,
      'country': ?country,
      'state': ?state,
      'district': ?district,
      'mapStyle': ?mapStyle,
      'isPrivate': ?isPrivate,
    };

    final res = await _api.patch('/users/me', body: changes);
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while saving your profile');
    }
    return ApiUser.fromJson(res);
  }

  /// Saves the traveller's signature flag (`PATCH /users/me/flag-style`).
  ///
  /// Kept separate from [updateMyProfile] so a profile edit and a style edit
  /// cannot overwrite each other. Errors propagate; the caller keeps the old
  /// style and shows the server message.
  Future<FlagStyle> updateMyFlagStyle(FlagStyle style) async {
    final res = await _api.patch(
      '/users/me/flag-style',
      body: {'style': style.toJson()},
    );
    if (res is Map<String, dynamic> && res['flagStyle'] is Map) {
      return FlagStyle.fromJson(res['flagStyle']);
    }
    throw ApiException('Unexpected response while saving your flag style');
  }

  /// Permanently deletes own traveler account (`DELETE /users/me`).
  Future<void> deleteMyAccount() async {
    await _api.delete('/users/me');
  }

  // ─── TRIPS (live-only, no mock fallback) ───────────────────────────

  TripsHubSnapshot _tripsHubFromJson(Map<String, dynamic> res) {
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

  /// Live trips hub, persisted so the active expedition stays viewable when the
  /// traveler loses signal. Server refusals are surfaced, never masked by cache.
  Future<TripsHubSnapshot> fetchTripsHub() async {
    try {
      final res = await _api.get('/trips/hub');
      if (res is! Map<String, dynamic>) {
        throw ApiException('Unexpected response while loading your trips');
      }
      await OfflineCacheService.instance.cacheTripsHub(res);
      return _tripsHubFromJson(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached = await OfflineCacheService.instance.getCachedTripsHub();
      if (cached != null) return _tripsHubFromJson(cached);
      rethrow;
    }
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
    try {
      final res = await _api.get('/trips/$tripId');
      if (res is! Map<String, dynamic>) {
        throw ApiException('Unexpected response while loading this trip');
      }
      await OfflineCacheService.instance.cacheActiveTrip(tripId, res);
      return ActiveTripDetail.fromJson(res, userId: userId);
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached =
          await OfflineCacheService.instance.getCachedActiveTrip(tripId);
      if (cached != null) {
        return ActiveTripDetail.fromJson(cached, userId: userId);
      }
      rethrow;
    }
  }

  /// Joins an in-progress expedition (`POST /trips/:tripId/join`).
  Future<void> joinActiveTrip(String tripId) async {
    await _api.post('/trips/$tripId/join');
  }

  Future<WaypointValidationResult> validateWaypointAt({
    required String tripId,
    required String waypointId,
    required double latitude,
    required double longitude,
  }) async {
    final res = await _api.post(
      '/trips/$tripId/validate-waypoint',
      body: {
        'waypointId': waypointId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    if (res is! Map<String, dynamic>) {
      throw ApiException('Unexpected response while validating this waypoint');
    }
    return WaypointValidationResult.fromJson(res);
  }

  /// Completes the trip and returns this traveler's badge (`FULL`, `PARTIAL`
  /// or `NONE`) as evaluated by the server.
  Future<String> completeTrip(String tripId) async {
    final res = await _api.post('/trips/$tripId/complete');
    if (res is Map<String, dynamic>) {
      return res['myBadge'] as String? ?? 'NONE';
    }
    return 'NONE';
  }

  Future<List<TripPlan>> fetchSavedPlans() async {
    try {
      final res = await _api.get('/trips/plans/saved');
      if (res is List) {
        final list = res.whereType<Map<String, dynamic>>().toList();
        OfflineCacheService.instance.cacheSavedPlans(list);
        return list.map(TripPlan.fromJson).toList();
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached = await OfflineCacheService.instance.getCachedSavedPlans();
      if (cached != null) {
        return cached.map(TripPlan.fromJson).toList();
      }
      rethrow;
    }
    throw ApiException('Unexpected response while loading saved plans');
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
    final res = await _api.post(
      '/trips/plans',
      body: {
        'name': name,
        'description': description,
        'originName': originName,
        'destinationName': destinationName,
        'communityId': ?communityId,
        'totalDistanceKm': totalDistanceKm,
        'estimatedDays': estimatedDays,
        'waypoints': waypoints,
      },
    );
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
    String? title,
    String? message,
  }) async {
    final res = await _api.post(
      '/users/invites',
      body: {
        'targetUserIds': userIds,
        'type': type,
        'targetId': targetId,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    if (res is Map<String, dynamic> && res['invitedCount'] is int) {
      return res['invitedCount'] as int;
    }
    throw ApiException('Unexpected response while sending invitations');
  }

  // ─── SERVICE PROVIDERS ───────────────────────────────────────────────

  /// Records a contact intent (call / website / navigate) for a service
  /// provider. Best-effort: callers must never block opening the dialer or a
  /// map on this request.
  Future<void> recordServiceInquiry(String providerId, String type) async {
    await _api.post(
      '/services/$providerId/inquiry',
      body: {'type': type},
    );
  }

  // ─── DIRECTIONS ──────────────────────────────────────────────────────

  /// Fetches road-geometry polyline coordinates from the OSRM proxy.
  /// [waypoints] is a list of `LatLng` pairs; the backend expects
  /// `lng,lat;lng,lat` format. Returns raw GeoJSON coordinates or empty list
  /// if the routing service is unreachable.
  Future<DirectionsResult> fetchDirections(List<List<double>> waypoints) async {
    if (waypoints.length < 2) {
      return const DirectionsResult(coordinates: [], distanceM: 0, durationS: 0, fallback: true);
    }
    final formatted =
        waypoints.map((w) => '${w[1]},${w[0]}').join(';'); // lng,lat
    final res = await _api.get(
      '/trips/directions',
      queryParams: {'waypoints': formatted},
    );
    if (res is Map<String, dynamic>) {
      final coords = (res['coordinates'] as List<dynamic>? ?? [])
          .map((c) => [
                (c[1] as num).toDouble(), // lat
                (c[0] as num).toDouble(), // lng
              ])
          .toList();
      return DirectionsResult(
        coordinates: coords,
        distanceM: (res['distance_m'] as num?)?.toInt() ?? 0,
        durationS: (res['duration_s'] as num?)?.toInt() ?? 0,
        fallback: res['fallback'] as bool? ?? true,
      );
    }
    return const DirectionsResult(coordinates: [], distanceM: 0, durationS: 0, fallback: true);
  }
}

/// Result from the OSRM directions proxy.
class DirectionsResult {
  final List<List<double>> coordinates; // [[lat, lng], ...]
  final int distanceM;
  final int durationS;
  final bool fallback;

  const DirectionsResult({
    required this.coordinates,
    required this.distanceM,
    required this.durationS,
    required this.fallback,
  });
}
