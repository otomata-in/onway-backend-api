enum RallyInviteType { community, friends, open }

enum RallyStatus { pending, active, completed, expired }

class LegendaryRally {
  final String id;
  final String name;
  final String organizerId;
  final String organizerName;
  final String locationName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final RallyInviteType inviteType;
  final String? communityId;
  final DateTime windowStartTime;
  final DateTime windowEndTime;
  final RallyStatus status;
  final int participantCount;
  final DateTime createdAt;

  const LegendaryRally({
    required this.id,
    required this.name,
    required this.organizerId,
    required this.organizerName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 500,
    required this.inviteType,
    this.communityId,
    required this.windowStartTime,
    required this.windowEndTime,
    this.status = RallyStatus.pending,
    this.participantCount = 0,
    required this.createdAt,
  });

  factory LegendaryRally.fromJson(Map<String, dynamic> json) {
    return LegendaryRally(
      id: json['id'] as String,
      name: json['name'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 500,
      inviteType: RallyInviteType.values.firstWhere(
        (e) => e.name == json['inviteType'] as String,
        orElse: () => RallyInviteType.open,
      ),
      communityId: json['communityId'] as String?,
      windowStartTime:
          DateTime.parse(json['windowStartTime'] as String),
      windowEndTime: DateTime.parse(json['windowEndTime'] as String),
      status: RallyStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => RallyStatus.pending,
      ),
      participantCount: json['participantCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'inviteType': inviteType.name,
        'communityId': communityId,
        'windowStartTime': windowStartTime.toIso8601String(),
        'windowEndTime': windowEndTime.toIso8601String(),
        'status': status.name,
        'participantCount': participantCount,
        'createdAt': createdAt.toIso8601String(),
      };
}

class RallyParticipant {
  final String id;
  final String rallyId;
  final String userId;
  final String userName;
  final String userAvatar;
  final DateTime joinedAt;
  final bool isWithinRadius;
  final double latitude;
  final double longitude;

  const RallyParticipant({
    required this.id,
    required this.rallyId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.joinedAt,
    this.isWithinRadius = false,
    required this.latitude,
    required this.longitude,
  });

  factory RallyParticipant.fromJson(Map<String, dynamic> json) {
    return RallyParticipant(
      id: json['id'] as String,
      rallyId: json['rallyId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isWithinRadius: json['isWithinRadius'] as bool? ?? false,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rallyId': rallyId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'joinedAt': joinedAt.toIso8601String(),
        'isWithinRadius': isWithinRadius,
        'latitude': latitude,
        'longitude': longitude,
      };
}
