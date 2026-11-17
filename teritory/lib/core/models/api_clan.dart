import 'clan_models.dart';
import 'community_models.dart';

/// One membership row from `GET /v1/clans/:id`. The API nests the person under
/// `user`, while [ClanMember] (asset-era model) expects flat `userName` fields.
class ApiClanMember {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final ClanRole role;
  final DateTime? joinedAt;

  const ApiClanMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  factory ApiClanMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? user : null;
    final rawRole = (json['role'] as String? ?? '').toUpperCase();

    return ApiClanMember(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? userMap?['id'] as String? ?? '',
      name: userMap?['displayName'] as String? ??
          userMap?['handle'] as String? ??
          'Traveler',
      avatarUrl: userMap?['avatarUrl'] as String? ?? '',
      role: ClanRole.values.firstWhere(
        (r) => r.name.toUpperCase() == rawRole,
        orElse: () => ClanRole.member,
      ),
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
    );
  }
}

/// `GET /v1/clans/:id` returns the clan plus its communities and a member page.
class ApiClanDetail {
  final Clan clan;
  final List<Community> communities;
  final List<ApiClanMember> members;

  const ApiClanDetail({
    required this.clan,
    required this.communities,
    required this.members,
  });

  factory ApiClanDetail.fromJson(Map<String, dynamic> json) {
    final communities = (json['communities'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Community.fromJson)
        .toList();
    final members = (json['members'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiClanMember.fromJson)
        .toList();

    return ApiClanDetail(
      // The detail payload has no clan-level `_count`, so the rendered
      // communities are the only truthful count on this screen.
      clan: Clan.fromJson(json).copyWith(communitiesCount: communities.length),
      communities: communities,
      members: members,
    );
  }
}
