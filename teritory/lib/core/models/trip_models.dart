enum TripPlanStatus { draft, proposed, voted, active, completed }

enum TripStatus { active, completed, expired }

enum ParticipantStatus { joined, inProgress, completed, dropped }

enum TripBadge { full, partial, none }

class TripWaypoint {
  final String id;
  final String tripPlanId;
  final int orderIndex;
  final String placeName;
  final double latitude;
  final double longitude;
  final String category;
  final int flagCount;
  final DateTime? estimatedArrivalTime;
  final DateTime? estimatedDepartureTime;
  final bool isValidated;
  final double distanceFromPrevKm;

  const TripWaypoint({
    required this.id,
    required this.tripPlanId,
    required this.orderIndex,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.category = 'general',
    this.flagCount = 0,
    this.estimatedArrivalTime,
    this.estimatedDepartureTime,
    this.isValidated = false,
    this.distanceFromPrevKm = 0.0,
  });

  factory TripWaypoint.fromJson(Map<String, dynamic> json) {
    return TripWaypoint(
      id: json['id'] as String,
      tripPlanId: json['tripPlanId'] as String,
      orderIndex: json['orderIndex'] as int,
      placeName: json['placeName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String? ?? 'general',
      flagCount: json['flagCount'] as int? ?? 0,
      estimatedArrivalTime: json['estimatedArrivalTime'] != null
          ? DateTime.parse(json['estimatedArrivalTime'] as String)
          : null,
      estimatedDepartureTime: json['estimatedDepartureTime'] != null
          ? DateTime.parse(json['estimatedDepartureTime'] as String)
          : null,
      isValidated: json['isValidated'] as bool? ?? false,
      distanceFromPrevKm:
          (json['distanceFromPrevKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripPlanId': tripPlanId,
    'orderIndex': orderIndex,
    'placeName': placeName,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'flagCount': flagCount,
    'estimatedArrivalTime': estimatedArrivalTime?.toIso8601String(),
    'estimatedDepartureTime': estimatedDepartureTime?.toIso8601String(),
    'isValidated': isValidated,
    'distanceFromPrevKm': distanceFromPrevKm,
  };
}

class TripPlan {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String createdByName;
  final String? communityId;
  final String? communityName;
  final String originName;
  final double originLat;
  final double originLng;
  final String destinationName;
  final double destLat;
  final double destLng;
  final double estimatedDurationHours;
  final double estimatedDistanceKm;
  final TripPlanStatus status;
  final int voteScore;
  final List<TripWaypoint> waypoints;
  final List<String> gearSuggestions;
  final DateTime createdAt;

  const TripPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    this.communityId,
    this.communityName,
    required this.originName,
    required this.originLat,
    required this.originLng,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
    required this.estimatedDurationHours,
    required this.estimatedDistanceKm,
    this.status = TripPlanStatus.draft,
    this.voteScore = 0,
    this.waypoints = const [],
    this.gearSuggestions = const [],
    required this.createdAt,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    final waypointsList =
        (json['waypoints'] as List<dynamic>?)
            ?.map((e) => TripWaypoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final oLat =
        (json['originLat'] as num?)?.toDouble() ??
        (waypointsList.isNotEmpty ? waypointsList.first.latitude : 0.0);
    final oLng =
        (json['originLng'] as num?)?.toDouble() ??
        (waypointsList.isNotEmpty ? waypointsList.first.longitude : 0.0);
    final dLat =
        (json['destLat'] as num?)?.toDouble() ??
        (waypointsList.isNotEmpty ? waypointsList.last.latitude : 0.0);
    final dLng =
        (json['destLng'] as num?)?.toDouble() ??
        (waypointsList.isNotEmpty ? waypointsList.last.longitude : 0.0);

    final cBy = json['createdBy'] is String
        ? json['createdBy'] as String
        : (json['createdById'] as String? ??
              (json['createdBy'] is Map
                  ? json['createdBy']['id'] as String? ?? ''
                  : ''));
    final cByName =
        json['createdByName'] as String? ??
        (json['createdBy'] is Map
            ? json['createdBy']['displayName'] as String? ?? ''
            : '');

    final statusStr = (json['status'] as String? ?? 'draft').toLowerCase();
    final durationHours =
        (json['estimatedDurationHours'] as num?)?.toDouble() ??
        ((json['estimatedDays'] as num?)?.toDouble() != null
            ? (json['estimatedDays'] as num).toDouble() * 8.0
            : 8.0);
    final distanceKm =
        (json['estimatedDistanceKm'] as num?)?.toDouble() ??
        (json['totalDistanceKm'] as num?)?.toDouble() ??
        0.0;
    final voteScore =
        json['voteScore'] as int? ?? json['voteCount'] as int? ?? 0;

    return TripPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdBy: cBy,
      createdByName: cByName,
      communityId: json['communityId'] as String?,
      communityName:
          json['communityName'] as String? ??
          (json['community'] is Map
              ? json['community']['name'] as String?
              : null),
      originName:
          json['originName'] as String? ??
          (waypointsList.isNotEmpty ? waypointsList.first.placeName : ''),
      originLat: oLat,
      originLng: oLng,
      destinationName:
          json['destinationName'] as String? ??
          (waypointsList.isNotEmpty ? waypointsList.last.placeName : ''),
      destLat: dLat,
      destLng: dLng,
      estimatedDurationHours: durationHours,
      estimatedDistanceKm: distanceKm,
      status: TripPlanStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => TripPlanStatus.draft,
      ),
      voteScore: voteScore,
      waypoints: waypointsList,
      gearSuggestions:
          (json['gearSuggestions'] as List<dynamic>?)
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
    'createdBy': createdBy,
    'createdByName': createdByName,
    'communityId': communityId,
    'communityName': communityName,
    'originName': originName,
    'originLat': originLat,
    'originLng': originLng,
    'destinationName': destinationName,
    'destLat': destLat,
    'destLng': destLng,
    'estimatedDurationHours': estimatedDurationHours,
    'estimatedDistanceKm': estimatedDistanceKm,
    'status': status.name,
    'voteScore': voteScore,
    'waypoints': waypoints.map((e) => e.toJson()).toList(),
    'gearSuggestions': gearSuggestions,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TripParticipant {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final String userAvatar;
  final ParticipantStatus status;
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastUpdated;

  const TripParticipant({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.status = ParticipantStatus.joined,
    this.currentLat,
    this.currentLng,
    this.lastUpdated,
  });

  factory TripParticipant.fromJson(Map<String, dynamic> json) {
    String uName = json['userName'] as String? ?? '';
    String uAvatar = json['userAvatar'] as String? ?? '';
    if (json['user'] is Map) {
      if (uName.isEmpty) uName = json['user']['displayName'] as String? ?? '';
      if (uAvatar.isEmpty) uAvatar = json['user']['avatarUrl'] as String? ?? '';
    }

    final statusStr = (json['status'] as String? ?? 'joined').toLowerCase();

    return TripParticipant(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? '',
      userId: json['userId'] as String,
      userName: uName,
      userAvatar: uAvatar,
      status: ParticipantStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == statusStr ||
            e.name.toLowerCase() == statusStr.replaceAll('_', ''),
        orElse: () => ParticipantStatus.joined,
      ),
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'status': status.name,
    'currentLat': currentLat,
    'currentLng': currentLng,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}

class Trip {
  final String id;
  final String tripPlanId;
  final String tripName;
  final String organizerId;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<TripParticipant> participants;

  // Flattened from the nested `tripPlan` so cards do not need a second lookup.
  final String originName;
  final String destinationName;
  final int plannedWaypoints;
  final double estimatedDurationHours;

  const Trip({
    required this.id,
    required this.tripPlanId,
    required this.tripName,
    required this.organizerId,
    this.status = TripStatus.active,
    required this.startedAt,
    this.completedAt,
    this.participants = const [],
    this.originName = '',
    this.destinationName = '',
    this.plannedWaypoints = 0,
    this.estimatedDurationHours = 48,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    String tName = json['tripName'] as String? ?? '';
    if (tName.isEmpty && json['tripPlan'] is Map) {
      tName = json['tripPlan']['name'] as String? ?? '';
    }

    final orgId =
        json['organizerId'] as String? ?? json['createdById'] as String? ?? '';
    final statusStr = (json['status'] as String? ?? 'active').toLowerCase();

    final plan = json['tripPlan'] is Map
        ? json['tripPlan'] as Map<String, dynamic>
        : null;
    final waypoints = plan?['waypoints'] as List<dynamic>? ?? const [];
    final duration =
        (plan?['estimatedDurationHours'] as num?)?.toDouble() ??
        ((plan?['estimatedDays'] as num?)?.toDouble() != null
            ? (plan!['estimatedDays'] as num).toDouble() * 8
            : 48.0);

    return Trip(
      id: json['id'] as String,
      tripPlanId:
          json['tripPlanId'] as String? ??
          (json['tripPlan'] is Map
              ? json['tripPlan']['id'] as String? ?? ''
              : ''),
      tripName: tName.isNotEmpty ? tName : 'Expedition',
      organizerId: orgId,
      status: TripStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => TripStatus.active,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((e) => TripParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      originName:
          plan?['originName'] as String? ??
          (waypoints.isNotEmpty
              ? (waypoints.first as Map<String, dynamic>)['placeName']
                        as String? ??
                    ''
              : ''),
      destinationName:
          plan?['destinationName'] as String? ??
          (waypoints.isNotEmpty
              ? (waypoints.last as Map<String, dynamic>)['placeName']
                        as String? ??
                    ''
              : ''),
      plannedWaypoints: waypoints.length,
      estimatedDurationHours: duration,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripPlanId': tripPlanId,
    'tripName': tripName,
    'organizerId': organizerId,
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'participants': participants.map((e) => e.toJson()).toList(),
    'originName': originName,
    'destinationName': destinationName,
    'plannedWaypoints': plannedWaypoints,
    'estimatedDurationHours': estimatedDurationHours,
  };
}

class TripCompletion {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final DateTime completedAt;
  final double totalDistanceKm;
  final double totalDurationHours;
  final int waypointsValidated;
  final int totalWaypoints;
  final TripBadge badge;
  final String? routeThumbnailUrl;

  const TripCompletion({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.completedAt,
    required this.totalDistanceKm,
    required this.totalDurationHours,
    required this.waypointsValidated,
    required this.totalWaypoints,
    this.badge = TripBadge.none,
    this.routeThumbnailUrl,
  });

  factory TripCompletion.fromJson(Map<String, dynamic> json) {
    return TripCompletion(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalDurationHours: (json['totalDurationHours'] as num).toDouble(),
      waypointsValidated: json['waypointsValidated'] as int,
      totalWaypoints: json['totalWaypoints'] as int,
      badge: TripBadge.values.firstWhere(
        (e) => e.name == json['badge'] as String,
        orElse: () => TripBadge.none,
      ),
      routeThumbnailUrl: json['routeThumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'userId': userId,
    'userName': userName,
    'completedAt': completedAt.toIso8601String(),
    'totalDistanceKm': totalDistanceKm,
    'totalDurationHours': totalDurationHours,
    'waypointsValidated': waypointsValidated,
    'totalWaypoints': totalWaypoints,
    'badge': badge.name,
    'routeThumbnailUrl': routeThumbnailUrl,
  };
}
