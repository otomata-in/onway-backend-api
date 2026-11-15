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
    return Clan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      region: json['region'] as String? ?? '',
      interestTag: json['interestTag'] as String? ?? '',
      memberCount: json['memberCount'] as int? ?? 0,
      communitiesCount: json['communitiesCount'] as int? ?? 0,
      chieftainId: json['chieftainId'] as String,
      chieftainName: json['chieftainName'] as String? ?? '',
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

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
