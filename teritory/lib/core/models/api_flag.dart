import 'package:latlong2/latlong.dart';

import 'teritory_models.dart';

/// A flag exactly as returned by `teritory-api` (`/v1/flags`, `/v1/flags/explore`,
/// `/v1/flags/:id`). Unlike [FlagItem]/[FriendFlag] this model is never seeded from
/// bundled assets, so the Explore page can render only what the backend confirms.
class ApiFlag {
  final String id;
  final String userId;
  final String placeName;
  final String city;
  final String country;
  final String countryCode;
  final String continent;
  final double latitude;
  final double longitude;
  final bool isMajorFlag;
  final String category;
  final String notes;
  final String photoUrl;
  final int kudos;
  final double distanceKm;
  final DateTime createdAt;

  // Author (flattened from the nested `user` object).
  final String authorName;
  final String authorHandle;
  final String authorAvatar;

  const ApiFlag({
    required this.id,
    required this.userId,
    required this.placeName,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.isMajorFlag,
    required this.category,
    required this.notes,
    required this.photoUrl,
    required this.kudos,
    required this.distanceKm,
    required this.createdAt,
    required this.authorName,
    required this.authorHandle,
    required this.authorAvatar,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  bool isOwnedBy(String? currentUserId) =>
      currentUserId != null && currentUserId.isNotEmpty && userId == currentUserId;

  factory ApiFlag.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? user : null;
    String authorName = json['authorName'] as String? ?? '';
    String authorHandle = json['authorHandle'] as String? ?? '';
    String authorAvatar = json['authorAvatar'] as String? ?? '';
    if (userMap != null) {
      if (authorName.isEmpty) {
        authorName = userMap['displayName'] as String? ?? '';
      }
      if (authorHandle.isEmpty) authorHandle = userMap['handle'] as String? ?? '';
      if (authorAvatar.isEmpty) {
        authorAvatar = userMap['avatarUrl'] as String? ?? '';
      }
    }

    return ApiFlag(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? userMap?['id'] as String? ?? '',
      placeName: json['placeName'] as String? ?? 'Unknown place',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      continent: json['continent'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isMajorFlag: json['isMajorFlag'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      kudos: (json['kudos'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      authorName: authorName.isEmpty ? 'Traveler' : authorName,
      authorHandle: authorHandle,
      authorAvatar: authorAvatar,
    );
  }
}

/// Server reaction row (`GET /flags/:id` -> `reactions[]`).
class ApiFlagReaction {
  final String id;
  final String userId;
  final String type;

  const ApiFlagReaction({
    required this.id,
    required this.userId,
    required this.type,
  });

  factory ApiFlagReaction.fromJson(Map<String, dynamic> json) {
    return ApiFlagReaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: (json['type'] as String? ?? '').toUpperCase(),
    );
  }
}

/// Server comment row (`GET /flags/:id` -> `comments[]`).
class ApiFlagComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime createdAt;

  const ApiFlagComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory ApiFlagComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String userName = json['userName'] as String? ?? '';
    String userAvatar = json['userAvatar'] as String? ?? '';
    if (user is Map) {
      if (userName.isEmpty) userName = user['displayName'] as String? ?? '';
      if (userAvatar.isEmpty) userAvatar = user['avatarUrl'] as String? ?? '';
    }
    return ApiFlagComment(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: userName.isEmpty ? 'Traveler' : userName,
      userAvatar: userAvatar,
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Full flag payload with social data, from `GET /v1/flags/:id`.
class ApiFlagDetail {
  final ApiFlag flag;
  final List<ApiFlagReaction> reactions;
  final List<ApiFlagComment> comments;

  const ApiFlagDetail({
    required this.flag,
    required this.reactions,
    required this.comments,
  });

  factory ApiFlagDetail.fromJson(Map<String, dynamic> json) {
    return ApiFlagDetail(
      flag: ApiFlag.fromJson(json),
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ApiFlagReaction.fromJson)
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ApiFlagComment.fromJson)
          .toList(),
    );
  }

  /// Reaction counts keyed by the API enum (`EPIC`, `HIDDEN_GEM`, `GREAT_SHOT`).
  Map<String, int> get reactionCounts {
    final counts = <String, int>{'EPIC': 0, 'HIDDEN_GEM': 0, 'GREAT_SHOT': 0};
    for (final reaction in reactions) {
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  bool hasReacted(String? userId, String type) {
    if (userId == null || userId.isEmpty) return false;
    return reactions.any((r) => r.userId == userId && r.type == type);
  }
}

/// Adapters so the existing map/profile widgets can keep their presentation
/// widgets while the data itself comes from the backend.
extension ApiFlagPresentation on ApiFlag {
  String get _flaggedDateLabel =>
      '${createdAt.day.toString().padLeft(2, '0')}/'
      '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

  String get _timeAgoLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  FlagItem toFlagItem() => FlagItem(
        id: id,
        placeName: placeName,
        city: city,
        country: country,
        countryCode: countryCode.isEmpty ? 'IN' : countryCode,
        continent: continent.isEmpty ? 'Asia' : continent,
        latitude: latitude,
        longitude: longitude,
        isMajorFlag: isMajorFlag,
        category: category,
        flaggedDate: _flaggedDateLabel,
        notes: notes,
        photoUrl: photoUrl,
        kudos: kudos,
      );

  FriendFlag toFriendFlag() => FriendFlag(
        id: id,
        friendName: authorName,
        friendAvatar: authorAvatar,
        placeName: placeName,
        city: city,
        country: country,
        latitude: latitude,
        longitude: longitude,
        isMajorFlag: isMajorFlag,
        flagColor: '#14B8A6',
        flaggedTimeAgo: _timeAgoLabel,
        caption: notes,
        photoUrl: photoUrl,
        kudosCount: kudos,
      );
}
