import 'package:latlong2/latlong.dart';

class FlagItem {
  final String id;
  final String placeName;
  final String city;
  final String country;
  final String countryCode;
  final String continent;
  final double latitude;
  final double longitude;
  final bool isMajorFlag;
  final String category;
  final String flaggedDate;
  final String notes;
  final String photoUrl;
  final int kudos;

  const FlagItem({
    required this.id,
    required this.placeName,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.isMajorFlag,
    required this.category,
    required this.flaggedDate,
    required this.notes,
    required this.photoUrl,
    this.kudos = 0,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory FlagItem.fromJson(Map<String, dynamic> json) {
    return FlagItem(
      id: json['id'] as String? ?? '',
      placeName: json['placeName'] as String? ?? 'Unknown Place',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'GL',
      continent: json['continent'] as String? ?? 'World',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isMajorFlag: json['isMajorFlag'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      flaggedDate: json['flaggedDate'] as String? ?? 'Recently',
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      kudos: json['kudos'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placeName': placeName,
    'city': city,
    'country': country,
    'countryCode': countryCode,
    'continent': continent,
    'latitude': latitude,
    'longitude': longitude,
    'isMajorFlag': isMajorFlag,
    'category': category,
    'flaggedDate': flaggedDate,
    'notes': notes,
    'photoUrl': photoUrl,
    'kudos': kudos,
  };
}

class FriendFlag {
  final String id;
  final String friendName;
  final String friendAvatar;
  final String placeName;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final bool isMajorFlag;
  final String flagColor;
  final String flaggedTimeAgo;
  final String caption;
  final String photoUrl;
  final int kudosCount;

  const FriendFlag({
    required this.id,
    required this.friendName,
    required this.friendAvatar,
    required this.placeName,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isMajorFlag,
    required this.flagColor,
    required this.flaggedTimeAgo,
    required this.caption,
    required this.photoUrl,
    this.kudosCount = 0,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory FriendFlag.fromJson(Map<String, dynamic> json) {
    return FriendFlag(
      id: json['id'] as String? ?? '',
      friendName: json['friendName'] as String? ?? 'Friend',
      friendAvatar: json['friendAvatar'] as String? ?? '',
      placeName: json['placeName'] as String? ?? 'Unknown Location',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isMajorFlag: json['isMajorFlag'] as bool? ?? false,
      flagColor: json['flagColor'] as String? ?? '#FF5722',
      flaggedTimeAgo: json['flaggedTimeAgo'] as String? ?? 'Recently',
      caption: json['caption'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      kudosCount: json['kudosCount'] as int? ?? 0,
    );
  }
}

class PassportStamp {
  final String id;
  final String title;
  final String date;
  final String category;
  final String badgeColor;
  final String icon;

  const PassportStamp({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.badgeColor,
    required this.icon,
  });

  factory PassportStamp.fromJson(Map<String, dynamic> json) {
    return PassportStamp(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      category: json['category'] as String? ?? '',
      badgeColor: json['badgeColor'] as String? ?? '#F59E0B',
      icon: json['icon'] as String? ?? 'star',
    );
  }
}

class UserStats {
  final int totalFlags;
  final int majorFlags;
  final int countriesVisited;
  final int continentsVisited;
  final int passportStamps;
  final int travelDays;

  const UserStats({
    required this.totalFlags,
    required this.majorFlags,
    required this.countriesVisited,
    required this.continentsVisited,
    required this.passportStamps,
    required this.travelDays,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalFlags: json['totalFlags'] as int? ?? 0,
      majorFlags: json['majorFlags'] as int? ?? 0,
      countriesVisited: json['countriesVisited'] as int? ?? 0,
      continentsVisited: json['continentsVisited'] as int? ?? 0,
      passportStamps: json['passportStamps'] as int? ?? 0,
      travelDays: json['travelDays'] as int? ?? 0,
    );
  }

  UserStats copyWith({
    int? totalFlags,
    int? majorFlags,
    int? countriesVisited,
    int? continentsVisited,
    int? passportStamps,
    int? travelDays,
  }) {
    return UserStats(
      totalFlags: totalFlags ?? this.totalFlags,
      majorFlags: majorFlags ?? this.majorFlags,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      continentsVisited: continentsVisited ?? this.continentsVisited,
      passportStamps: passportStamps ?? this.passportStamps,
      travelDays: travelDays ?? this.travelDays,
    );
  }
}

class CurrentUserProfile {
  final String id;
  final String name;
  final String handle;
  final String avatar;
  final String bio;
  final String nomadRank;
  final int nomadLevel;
  final int xp;
  final int xpNextLevel;
  final UserStats stats;
  final List<PassportStamp> passportStamps;

  const CurrentUserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatar,
    required this.bio,
    required this.nomadRank,
    required this.nomadLevel,
    required this.xp,
    required this.xpNextLevel,
    required this.stats,
    required this.passportStamps,
  });

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final stampsJson = json['passportStamps'] as List<dynamic>? ?? [];

    return CurrentUserProfile(
      id: json['id'] as String? ?? 'u1',
      name: json['name'] as String? ?? 'Explorer',
      handle: json['handle'] as String? ?? '@explorer',
      avatar: json['avatar'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      nomadRank: json['nomadRank'] as String? ?? 'Urban Scout',
      nomadLevel: json['nomadLevel'] as int? ?? 1,
      xp: json['xp'] as int? ?? 100,
      xpNextLevel: json['xpNextLevel'] as int? ?? 500,
      stats: UserStats.fromJson(statsJson),
      passportStamps: stampsJson
          .map((s) => PassportStamp.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  CurrentUserProfile copyWith({
    String? name,
    String? handle,
    String? avatar,
    String? bio,
    String? nomadRank,
    int? nomadLevel,
    int? xp,
    int? xpNextLevel,
    UserStats? stats,
    List<PassportStamp>? passportStamps,
  }) {
    return CurrentUserProfile(
      id: id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      nomadRank: nomadRank ?? this.nomadRank,
      nomadLevel: nomadLevel ?? this.nomadLevel,
      xp: xp ?? this.xp,
      xpNextLevel: xpNextLevel ?? this.xpNextLevel,
      stats: stats ?? this.stats,
      passportStamps: passportStamps ?? this.passportStamps,
    );
  }
}

class MajorWonder {
  final String id;
  final String name;
  final String country;
  final String continent;
  final String category;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final bool isClaimed;
  final int totalFlagsClaimed;

  const MajorWonder({
    required this.id,
    required this.name,
    required this.country,
    required this.continent,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.isClaimed,
    required this.totalFlagsClaimed,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory MajorWonder.fromJson(Map<String, dynamic> json) {
    return MajorWonder(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      continent: json['continent'] as String? ?? '',
      category: json['category'] as String? ?? 'Wonder',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photoUrl'] as String? ?? '',
      isClaimed: json['isClaimed'] as bool? ?? false,
      totalFlagsClaimed: json['totalFlagsClaimed'] as int? ?? 0,
    );
  }
}

class TravelTribe {
  final String id;
  final String name;
  final String tagline;
  final int membersCount;
  final int totalFlagsDropped;
  final String badge;
  final String coverPhoto;

  const TravelTribe({
    required this.id,
    required this.name,
    required this.tagline,
    required this.membersCount,
    required this.totalFlagsDropped,
    required this.badge,
    required this.coverPhoto,
  });

  factory TravelTribe.fromJson(Map<String, dynamic> json) {
    return TravelTribe(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      membersCount: json['membersCount'] as int? ?? 0,
      totalFlagsDropped: json['totalFlagsDropped'] as int? ?? 0,
      badge: json['badge'] as String? ?? '🏕️',
      coverPhoto: json['coverPhoto'] as String? ?? '',
    );
  }
}

