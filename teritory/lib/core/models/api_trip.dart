import 'trip_models.dart';

/// One `GET /trips/hub` payload: the traveler's active trip plus plan lists.
class TripsHubSnapshot {
  final Trip? activeTrip;
  final List<TripPlan> proposedPlans;
  final List<TripPlan> savedPlans;

  const TripsHubSnapshot({
    this.activeTrip,
    this.proposedPlans = const [],
    this.savedPlans = const [],
  });

  bool get isEmpty =>
      activeTrip == null && proposedPlans.isEmpty && savedPlans.isEmpty;
}

/// `GET /trips/plans/:id`: the plan plus this traveler's vote flag.
class TripPlanDetail {
  final TripPlan plan;
  final bool hasVoted;

  const TripPlanDetail({required this.plan, required this.hasVoted});

  factory TripPlanDetail.fromJson(Map<String, dynamic> json) {
    return TripPlanDetail(
      plan: TripPlan.fromJson(json),
      hasVoted: json['hasVoted'] as bool? ?? false,
    );
  }
}

/// `GET /trips/:tripId`: the trip, its plan's waypoints and **this user's**
/// validations, which is what the tracker needs instead of hard-coded progress.
class ActiveTripDetail {
  final Trip trip;
  final List<TripWaypoint> waypoints;
  final Set<String> validatedWaypointIds;
  final double? currentLat;
  final double? currentLng;

  const ActiveTripDetail({
    required this.trip,
    required this.waypoints,
    required this.validatedWaypointIds,
    this.currentLat,
    this.currentLng,
  });

  bool get hasPosition => currentLat != null && currentLng != null;

  TripWaypoint? get nextWaypoint {
    for (final waypoint in waypoints) {
      if (!validatedWaypointIds.contains(waypoint.id)) return waypoint;
    }
    return null;
  }

  factory ActiveTripDetail.fromJson(
    Map<String, dynamic> json, {
    String? userId,
  }) {
    final trip = Trip.fromJson(json);
    final plan = json['tripPlan'] is Map
        ? json['tripPlan'] as Map<String, dynamic>
        : null;
    final waypoints = (plan?['waypoints'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TripWaypoint.fromJson)
        .toList();

    final validated = (json['validations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((validation) => validation['isValid'] == true)
        .map((validation) => validation['waypointId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // Prefer this traveler's last reported point, then anyone else's.
    double? lat;
    double? lng;
    for (final participant in trip.participants) {
      if (participant.userId == userId &&
          participant.currentLat != null &&
          participant.currentLng != null) {
        lat = participant.currentLat;
        lng = participant.currentLng;
        break;
      }
    }
    if (lat == null || lng == null) {
      for (final participant in trip.participants) {
        if (participant.currentLat != null && participant.currentLng != null) {
          lat = participant.currentLat;
          lng = participant.currentLng;
          break;
        }
      }
    }

    return ActiveTripDetail(
      trip: trip,
      waypoints: waypoints,
      validatedWaypointIds: validated,
      currentLat: lat,
      currentLng: lng,
    );
  }
}

/// Result of `POST /trips/:tripId/validate-waypoint`.
class WaypointValidationResult {
  final bool isValid;
  final double distanceM;
  final double maxAllowedMeters;
  final String message;

  const WaypointValidationResult({
    required this.isValid,
    required this.distanceM,
    required this.maxAllowedMeters,
    required this.message,
  });

  factory WaypointValidationResult.fromJson(Map<String, dynamic> json) {
    return WaypointValidationResult(
      isValid: json['isValid'] as bool? ?? false,
      distanceM: (json['distanceM'] as num?)?.toDouble() ?? 0,
      maxAllowedMeters:
          (json['maxAllowedMeters'] as num?)?.toDouble() ?? 15000,
      message: json['message'] as String? ?? '',
    );
  }
}

/// `GET /trips/history` returns trip rows with `myBadge`, not completion rows,
/// so it needs its own mapping (`TripCompletion` is the asset-era shape).
class TripHistoryEntry {
  final String id;
  final String tripName;
  final DateTime? completedAt;
  final TripBadge badge;
  final int totalWaypoints;
  final double distanceKm;

  const TripHistoryEntry({
    required this.id,
    required this.tripName,
    required this.completedAt,
    required this.badge,
    required this.totalWaypoints,
    required this.distanceKm,
  });

  bool get isCompleted => badge != TripBadge.none;

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    final trip = Trip.fromJson(json);
    final plan =
        json['tripPlan'] is Map ? json['tripPlan'] as Map<String, dynamic> : null;
    final waypoints = plan?['waypoints'] as List<dynamic>? ?? const [];

    final distance = (plan?['totalDistanceKm'] as num?)?.toDouble() ??
        (plan?['estimatedDistanceKm'] as num?)?.toDouble() ??
        0.0;

    final badgeName = (json['myBadge'] as String? ?? 'none').toLowerCase();

    return TripHistoryEntry(
      id: trip.id,
      tripName: trip.tripName,
      completedAt: trip.completedAt,
      badge: TripBadge.values.firstWhere(
        (badge) => badge.name == badgeName,
        orElse: () => TripBadge.none,
      ),
      totalWaypoints: waypoints.length,
      distanceKm: distance,
    );
  }
}
