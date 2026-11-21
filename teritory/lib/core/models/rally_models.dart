import '../config/app_config.dart';

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
  final String? communityId;
  final DateTime windowStartTime;
  final DateTime windowEndTime;
  final RallyStatus status;
  final int participantCount;
  final DateTime createdAt;
  final double? distanceKm;
  final List<String> participantIds;
  final int arrivedCount;
  final int minParticipants;

  const LegendaryRally({
    required this.id,
    required this.name,
    required this.organizerId,
    required this.organizerName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 500,
    this.communityId,
    required this.windowStartTime,
    required this.windowEndTime,
    this.status = RallyStatus.pending,
    this.participantCount = 0,
    required this.createdAt,
    this.distanceKm,
    this.participantIds = const [],
    this.arrivedCount = 0,
    this.minParticipants = 3,
  });

  bool isParticipant(String? userId) =>
      userId != null && userId.isNotEmpty && participantIds.contains(userId);

  factory LegendaryRally.fromJson(Map<String, dynamic> json) {
    String orgId =
        json['organizerId'] as String? ?? json['createdById'] as String? ?? '';
    String orgName = json['organizerName'] as String? ?? '';
    if (json['host'] is Map) {
      if (orgId.isEmpty) {
        orgId = json['host']['id'] as String? ?? '';
      }
      if (orgName.isEmpty) {
        orgName = json['host']['displayName'] as String? ?? '';
      }
    }

    final pCount =
        json['participantCount'] as int? ??
        (json['participants'] is List
            ? (json['participants'] as List).length
            : 0);

    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    RallyStatus rStatus = RallyStatus.pending;
    if (statusStr == 'active') {
      rStatus = RallyStatus.active;
    } else if (statusStr == 'completed') {
      rStatus = RallyStatus.completed;
    } else if (statusStr == 'expired') {
      rStatus = RallyStatus.expired;
    } else {
      rStatus = RallyStatus.pending;
    }

    final start = json['windowStartTime'] != null
        ? DateTime.parse(json['windowStartTime'] as String)
        : (json['scheduledAt'] != null
              ? DateTime.parse(json['scheduledAt'] as String)
              : (json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'] as String)
                    : DateTime.now()));

    final end = json['windowEndTime'] != null
        ? DateTime.parse(json['windowEndTime'] as String)
        : (json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : DateTime.now().add(const Duration(days: 2)));

    final rawParticipants = json['participants'];
    final participantIds = rawParticipants is List
        ? rawParticipants
              .whereType<Map<String, dynamic>>()
              .map((p) => p['userId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList()
        : <String>[];
    final arrivedCount = rawParticipants is List
        ? rawParticipants
              .whereType<Map<String, dynamic>>()
              .where((p) => p['hasArrived'] == true)
              .length
        : 0;

    return LegendaryRally(
      id: json['id'] as String,
      name: json['name'] as String,
      organizerId: orgId,
      organizerName: orgName.isNotEmpty ? orgName : 'Host',
      locationName:
          json['locationName'] as String? ?? json['placeName'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 500,
      communityId: json['communityId'] as String?,
      windowStartTime: start,
      windowEndTime: end,
      status: rStatus,
      participantCount: pCount,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      participantIds: participantIds,
      arrivedCount: arrivedCount,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? 3,
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
    'communityId': communityId,
    'windowStartTime': windowStartTime.toIso8601String(),
    'windowEndTime': windowEndTime.toIso8601String(),
    'status': status.name,
    'participantCount': participantCount,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// One row of `GET /rallies/:id`'s participant roster (the API nests the user).
class RallyRosterEntry {
  final String participantId;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final bool hasArrived;
  final DateTime? arrivedAt;

  const RallyRosterEntry({
    required this.participantId,
    required this.userId,
    required this.displayName,
    this.avatarUrl = '',
    this.hasArrived = false,
    this.arrivedAt,
  });

  factory RallyRosterEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map : null;
    return RallyRosterEntry(
      participantId: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? user?['id'] as String? ?? '',
      displayName: user?['displayName'] as String? ?? 'Traveler',
      avatarUrl:
          AppConfig.resolveMediaUrl(user?['avatarUrl'] as String? ?? ''),
      hasArrived: json['hasArrived'] as bool? ?? false,
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.tryParse(json['arrivedAt'] as String)
          : null,
    );
  }
}

/// `GET /rallies/:id`: the rally plus its real roster and arrival state.
class RallyDetail {
  final LegendaryRally rally;
  final List<RallyRosterEntry> roster;
  final double? distanceKm;

  const RallyDetail({
    required this.rally,
    required this.roster,
    this.distanceKm,
  });

  int get arrivedCount => roster.where((entry) => entry.hasArrived).length;

  factory RallyDetail.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    return RallyDetail(
      rally: LegendaryRally.fromJson(json),
      roster: rawParticipants is List
          ? rawParticipants
                .whereType<Map<String, dynamic>>()
                .map(RallyRosterEntry.fromJson)
                .toList()
          : const [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

/// `POST /rallies/:id/arrive` answer: the server's 500 m check, not a local one.
class RallyArrivalResult {
  final bool arrived;
  final int distanceM;
  final String message;

  const RallyArrivalResult({
    required this.arrived,
    required this.distanceM,
    required this.message,
  });

  factory RallyArrivalResult.fromJson(Map<String, dynamic> json) {
    return RallyArrivalResult(
      arrived: json['arrived'] as bool? ?? false,
      distanceM: (json['distanceM'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
