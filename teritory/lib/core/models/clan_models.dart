class Clan {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final String region;
  final String interestTag;
  final int memberCount;
  final int communitiesCount;
  final String chieftainId;
  final String chieftainName;
  final bool isPublic;
  final DateTime createdAt;

  const Clan({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.region,
    required this.interestTag,
    required this.memberCount,
    required this.communitiesCount,
    required this.chieftainId,
    required this.chieftainName,
    this.isPublic = true,
    required this.createdAt,
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    String chName = json['chieftainName'] as String? ?? '';
    if (chName.isEmpty && json['chieftain'] is Map) {
      chName = json['chieftain']['displayName'] as String? ?? '';
    }

    int memCount = json['memberCount'] as int? ?? 0;
    if (memCount == 0 && json['_count'] is Map) {
      memCount = json['_count']['members'] as int? ?? 0;
    }

    int commCount = json['communitiesCount'] as int? ?? 0;
    if (commCount == 0 && json['_count'] is Map) {
      commCount = json['_count']['communities'] as int? ?? 0;
    }

    return Clan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      region: json['region'] as String? ?? '',
      interestTag: json['interestTag'] as String? ?? '',
      memberCount: memCount,
      communitiesCount: commCount,
      chieftainId: json['chieftainId'] as String? ?? (json['chieftain'] is Map ? json['chieftain']['id'] as String? ?? '' : ''),
      chieftainName: chName,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Clan copyWith({int? memberCount, int? communitiesCount}) => Clan(
        id: id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        region: region,
        interestTag: interestTag,
        memberCount: memberCount ?? this.memberCount,
        communitiesCount: communitiesCount ?? this.communitiesCount,
        chieftainId: chieftainId,
        chieftainName: chieftainName,
        isPublic: isPublic,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'region': region,
        'interestTag': interestTag,
        'memberCount': memberCount,
        'communitiesCount': communitiesCount,
        'chieftainId': chieftainId,
        'chieftainName': chieftainName,
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum ClanRole { chieftain, moderator, member }

class ClanMember {
  final String id;
  final String clanId;
  final String userId;
  final String userName;
  final String userAvatar;
  final ClanRole role;
  final DateTime joinedAt;

  const ClanMember({
    required this.id,
    required this.clanId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    return ClanMember(
      id: json['id'] as String,
      clanId: json['clanId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      role: ClanRole.values.firstWhere(
        (e) => e.name == json['role'] as String,
        orElse: () => ClanRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clanId': clanId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
