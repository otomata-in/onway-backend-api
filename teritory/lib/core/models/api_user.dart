/// Models for the user/profile/social endpoints. They mirror the JSON returned
/// by `teritory-api` and are never seeded from bundled assets, so the profile
/// and friend surfaces can only render what the backend confirms.
library;

import '../config/app_config.dart';

class ApiPassportStamp {
  final String id;
  final String title;
  final String category;
  final String date;
  final String badgeColor;
  final String icon;

  const ApiPassportStamp({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.badgeColor = '#F59E0B',
    this.icon = 'star',
  });

  factory ApiPassportStamp.fromJson(Map<String, dynamic> json) {
    return ApiPassportStamp(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Passport stamp',
      category: json['category'] as String? ?? '',
      date: json['date'] as String? ?? '',
      badgeColor: json['badgeColor'] as String? ?? '#F59E0B',
      icon: json['icon'] as String? ?? 'star',
    );
  }
}

class ApiUserClan {
  final String id;
  final String name;
  final String tag;
  final String avatarUrl;
  final String category;
  final String role;
  final int memberCount;

  const ApiUserClan({
    required this.id,
    required this.name,
    this.tag = '',
    this.avatarUrl = '',
    this.category = '',
    this.role = 'MEMBER',
    this.memberCount = 1,
  });

  factory ApiUserClan.fromJson(Map<String, dynamic> json) {
    return ApiUserClan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      avatarUrl: AppConfig.resolveMediaUrl(json['avatarUrl'] as String? ?? ''),
      category: json['category'] as String? ?? '',
      role: json['role'] as String? ?? 'MEMBER',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
    );
  }
}

class ApiMutualFriend {
  final String id;
  final String displayName;
  final String handle;
  final String avatarUrl;

  const ApiMutualFriend({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
  });

  factory ApiMutualFriend.fromJson(Map<String, dynamic> json) {
    return ApiMutualFriend(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Traveler',
      handle: json['handle'] as String? ?? 'traveler',
      avatarUrl: AppConfig.resolveMediaUrl(json['avatarUrl'] as String? ?? ''),
    );
  }
}

class ApiMutualExploredAreas {
  final List<String> commonCountries;
  final List<String> commonStates;
  final List<String> commonContinents;

  const ApiMutualExploredAreas({
    this.commonCountries = const [],
    this.commonStates = const [],
    this.commonContinents = const [],
  });

  bool get isEmpty =>
      commonCountries.isEmpty &&
      commonStates.isEmpty &&
      commonContinents.isEmpty;

  bool get isNotEmpty => !isEmpty;

  factory ApiMutualExploredAreas.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) {
      final list = json[key];
      if (list is List) {
        return list
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return ApiMutualExploredAreas(
      commonCountries: parseList('commonCountries'),
      commonStates: parseList('commonStates'),
      commonContinents: parseList('commonContinents'),
    );
  }
}

class ApiUserRelationship {
  final String status;
  final String? relationshipId;
  final String? category;
  final DateTime? since;

  const ApiUserRelationship({
    this.status = 'NONE',
    this.relationshipId,
    this.category,
    this.since,
  });

  bool get isSelf => status == 'SELF';
  bool get isFriends => status == 'FRIENDS';
  bool get isRequestSent => status == 'REQUEST_SENT';
  bool get isRequestReceived => status == 'REQUEST_RECEIVED';
  bool get isNone => status == 'NONE';

  factory ApiUserRelationship.fromJson(Map<String, dynamic> json) {
    return ApiUserRelationship(
      status: (json['status'] as String? ?? 'NONE').toUpperCase(),
      relationshipId: json['relationshipId'] as String?,
      category: json['category'] as String?,
      since: json['since'] != null
          ? DateTime.tryParse(json['since'] as String)
          : null,
    );
  }
}

/// A traveler as returned by `GET /users/me`, `GET /users/:id` and the friend
/// endpoints. The nested `passportStamps` array is folded into [passportStamps].
class ApiUser {
  final String id;
  final String displayName;
  final String handle;
  final String avatarUrl;
  final String coverImageUrl;
  final String bio;
  final String phone;
  final String email;
  final String country;
  final String countryCode;
  final String state;
  final String district;
  final int totalFlags;
  final int majorFlags;
  final int countriesVisited;
  final int continentsVisited;
  final int totalTravelDays;
  final int completedTripsCount;
  final int legendaryRalliesCount;
  final String mapStyle;
  final bool isPrivate;
  final bool isTripMode;
  final DateTime? createdAt;
  final List<ApiPassportStamp> passportStamps;
  final List<ApiUserClan> clans;
  final List<ApiMutualFriend> mutualFriends;
  final ApiMutualExploredAreas mutualExploredAreas;
  final ApiUserRelationship? relationship;

  const ApiUser({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    this.coverImageUrl = '',
    this.bio = '',
    this.phone = '',
    this.email = '',
    this.country = '',
    this.countryCode = '',
    this.state = '',
    this.district = '',
    this.totalFlags = 0,
    this.majorFlags = 0,
    this.countriesVisited = 0,
    this.continentsVisited = 0,
    this.totalTravelDays = 0,
    this.completedTripsCount = 0,
    this.legendaryRalliesCount = 0,
    this.mapStyle = '',
    this.isPrivate = false,
    this.isTripMode = false,
    this.createdAt,
    this.passportStamps = const [],
    this.clans = const [],
    this.mutualFriends = const [],
    this.mutualExploredAreas = const ApiMutualExploredAreas(),
    this.relationship,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final rawStamps = json['passportStamps'];
    final stamps = rawStamps is List
        ? rawStamps
            .whereType<Map<String, dynamic>>()
            .map(ApiPassportStamp.fromJson)
            .toList()
        : <ApiPassportStamp>[];

    final rawClans = json['clans'];
    final clans = rawClans is List
        ? rawClans
            .whereType<Map<String, dynamic>>()
            .map(ApiUserClan.fromJson)
            .toList()
        : <ApiUserClan>[];

    final rawMutualFriends = json['mutualFriends'];
    final mutualFriends = rawMutualFriends is List
        ? rawMutualFriends
            .whereType<Map<String, dynamic>>()
            .map(ApiMutualFriend.fromJson)
            .toList()
        : <ApiMutualFriend>[];

    final rawAreas = json['mutualExploredAreas'];
    final mutualAreas = rawAreas is Map<String, dynamic>
        ? ApiMutualExploredAreas.fromJson(rawAreas)
        : const ApiMutualExploredAreas();

    final rawRel = json['relationship'];
    final relationship = rawRel is Map<String, dynamic>
        ? ApiUserRelationship.fromJson(rawRel)
        : null;

    int intOf(String key) => (json[key] as num?)?.toInt() ?? 0;

    return ApiUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Traveler',
      handle: json['handle'] as String? ?? 'traveler',
      avatarUrl: AppConfig.resolveMediaUrl(json['avatarUrl'] as String? ?? ''),
      coverImageUrl:
          AppConfig.resolveMediaUrl(json['coverImageUrl'] as String? ?? ''),
      bio: json['bio'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      totalFlags: intOf('totalFlags'),
      majorFlags: intOf('majorFlags'),
      countriesVisited: intOf('countriesVisited'),
      continentsVisited: intOf('continentsVisited'),
      totalTravelDays: intOf('totalTravelDays'),
      completedTripsCount: intOf('completedTripsCount'),
      legendaryRalliesCount: intOf('legendaryRalliesCount'),
      mapStyle: json['mapStyle'] as String? ?? '',
      isPrivate: json['isPrivate'] as bool? ?? false,
      isTripMode: json['isTripMode'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      passportStamps: stamps,
      clans: clans,
      mutualFriends: mutualFriends,
      mutualExploredAreas: mutualAreas,
      relationship: relationship,
    );
  }

  /// "Palakkad, Kerala, India" with empty parts skipped.
  String get locationLabel => [district, state, country]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');
}

/// One accepted friend: the other traveler plus the relationship metadata the
/// list needs (`relationshipId` is what remove-friend and invites address).
class ApiFriend {
  final ApiUser user;
  final String relationshipId;
  final String category;
  final DateTime? since;

  const ApiFriend({
    required this.user,
    required this.relationshipId,
    this.category = '',
    this.since,
  });

  factory ApiFriend.fromJson(Map<String, dynamic> json) {
    return ApiFriend(
      user: ApiUser.fromJson(json),
      relationshipId: json['relationshipId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      since: json['since'] != null
          ? DateTime.tryParse(json['since'] as String)
          : null,
    );
  }
}

/// A pending friend request in either direction.
class ApiFriendRequest {
  final ApiUser user;
  final String relationshipId;
  final String category;
  final DateTime? since;

  const ApiFriendRequest({
    required this.user,
    required this.relationshipId,
    this.category = '',
    this.since,
  });

  factory ApiFriendRequest.fromJson(Map<String, dynamic> json) {
    return ApiFriendRequest(
      user: ApiUser.fromJson(json),
      relationshipId: json['relationshipId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      since: json['since'] != null
          ? DateTime.tryParse(json['since'] as String)
          : null,
    );
  }
}

/// `GET /users/friends/requests` payload: both directions at once.
class FriendRequestsSnapshot {
  final List<ApiFriendRequest> incoming;
  final List<ApiFriendRequest> outgoing;

  const FriendRequestsSnapshot({
    required this.incoming,
    required this.outgoing,
  });

  int get total => incoming.length + outgoing.length;

  factory FriendRequestsSnapshot.fromJson(Map<String, dynamic> json) {
    List<ApiFriendRequest> parse(Object? raw) => (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ApiFriendRequest.fromJson)
        .toList();

    return FriendRequestsSnapshot(
      incoming: parse(json['incoming']),
      outgoing: parse(json['outgoing']),
    );
  }
}
