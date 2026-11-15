class Community {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final String parentClanId;
  final String parentClanName;
  final int memberCount;
  final int activeTripPlansCount;
  final bool isPublic;
  final List<String> interestTags;
  final DateTime createdAt;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.parentClanId,
    required this.parentClanName,
    required this.memberCount,
    this.activeTripPlansCount = 0,
    this.isPublic = true,
    this.interestTags = const [],
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    String pClanName = json['parentClanName'] as String? ?? '';
    if (pClanName.isEmpty && json['clan'] is Map) {
      pClanName = json['clan']['name'] as String? ?? '';
    }

    int memCount = json['memberCount'] as int? ?? 0;
    if (memCount == 0 && json['_count'] is Map) {
      memCount = json['_count']['members'] as int? ?? 0;
    }

    int activePlans = json['activeTripPlansCount'] as int? ?? 0;
    if (activePlans == 0 && json['_count'] is Map) {
      activePlans = json['_count']['tripPlans'] as int? ?? 0;
    }

    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      parentClanId: json['parentClanId'] as String? ?? (json['clan'] is Map ? json['clan']['id'] as String? ?? '' : ''),
      parentClanName: pClanName,
      memberCount: memCount,
      activeTripPlansCount: activePlans,
      isPublic: json['isPublic'] as bool? ?? true,
      interestTags: (json['interestTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'parentClanId': parentClanId,
        'parentClanName': parentClanName,
        'memberCount': memberCount,
        'activeTripPlansCount': activeTripPlansCount,
        'isPublic': isPublic,
        'interestTags': interestTags,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum CommunityRole { creator, moderator, member }

class CommunityMember {
  final String id;
  final String communityId;
  final String userId;
  final String userName;
  final String userAvatar;
  final CommunityRole role;
  final DateTime joinedAt;

  const CommunityMember({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      role: CommunityRole.values.firstWhere(
        (e) => e.name == json['role'] as String,
        orElse: () => CommunityRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };
}

class CommunityMessage {
  final String id;
  final String communityId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime createdAt;

  const CommunityMessage({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    String uName = json['userName'] as String? ?? '';
    String uAvatar = json['userAvatar'] as String? ?? '';
    if (json['user'] is Map) {
      if (uName.isEmpty) uName = json['user']['displayName'] as String? ?? '';
      if (uAvatar.isEmpty) uAvatar = json['user']['avatarUrl'] as String? ?? '';
    }
    return CommunityMessage(
      id: json['id'] as String,
      communityId: json['communityId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: uName.isNotEmpty ? uName : 'Traveler',
      userAvatar: uAvatar,
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum CommunityActivityType {
  flagDrop,
  tripComplete,
  announcement,
  memberJoin,
}

class CommunityActivity {
  final String id;
  final String communityId;
  final CommunityActivityType type;
  final String title;
  final String description;
  final String userId;
  final String userName;
  final String userAvatar;
  final DateTime createdAt;

  const CommunityActivity({
    required this.id,
    required this.communityId,
    required this.type,
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
  });

  factory CommunityActivity.fromJson(Map<String, dynamic> json) {
    return CommunityActivity(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      type: CommunityActivityType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => CommunityActivityType.announcement,
      ),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'type': type.name,
        'title': title,
        'description': description,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'createdAt': createdAt.toIso8601String(),
      };
}
