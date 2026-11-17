/// Models for the user/profile/social endpoints. They mirror the JSON returned
/// by `teritory-api` and are never seeded from bundled assets, so the profile
/// and friend surfaces can only render what the backend confirms.
library;

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
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final rawStamps = json['passportStamps'];
    final stamps = rawStamps is List
        ? rawStamps
            .whereType<Map<String, dynamic>>()
            .map(ApiPassportStamp.fromJson)
            .toList()
        : <ApiPassportStamp>[];

    int intOf(String key) => (json[key] as num?)?.toInt() ?? 0;

    return ApiUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Traveler',
      handle: json['handle'] as String? ?? 'traveler',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
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
