enum NotificationType {
  friendRequest,
  friendAccepted,
  tripInvite,
  tripStarted,
  tripCompleted,
  rallyAlert,
  rallyStarted,
  waypointValidated,
  kudos,
  clanInvite,
  communityInvite,
  leaderboardChange,
  tripVoteResult,
  flagNearby,
  achievement,
  system,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? targetId;
  final String? targetType;

  /// Server-supplied route the app can open, e.g. `/clans/<id>`.
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.targetType,
    this.actionUrl,
    this.isRead = false,
    required this.createdAt,
  });

  /// The API speaks Prisma enum names (`TRIP_STARTED`) while the mock layer
  /// used Dart names. Unknown values surface as [NotificationType.system]
  /// instead of dropping the row.
  static const Map<String, NotificationType> _apiTypes = {
    'FRIEND_REQUEST': NotificationType.friendRequest,
    'FRIEND_ACCEPTED': NotificationType.friendAccepted,
    'TRIP_INVITE': NotificationType.tripInvite,
    'TRIP_STARTED': NotificationType.tripStarted,
    'TRIP_COMPLETED': NotificationType.tripCompleted,
    'RALLY_INVITE': NotificationType.rallyAlert,
    'RALLY_STARTED': NotificationType.rallyStarted,
    'WAYPOINT_VALIDATED': NotificationType.waypointValidated,
    'CLAN_INVITE': NotificationType.clanInvite,
    'COMMUNITY_INVITE': NotificationType.communityInvite,
    'ACHIEVEMENT': NotificationType.achievement,
    'SYSTEM': NotificationType.system,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? '';

    return NotificationItem(
      id: json['id'] as String,
      type: _typeFor(rawType),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      actionUrl: json['actionUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Prisma enum name first, then the older Dart-style name.
  static NotificationType _typeFor(String rawType) {
    final byApiName = _apiTypes[rawType.toUpperCase()];
    if (byApiName != null) return byApiName;
    final normalized = rawType.toLowerCase().replaceAll('_', '');
    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => NotificationType.system,
    );
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        targetId: targetId,
        targetType: targetType,
        actionUrl: actionUrl,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'targetId': targetId,
        'targetType': targetType,
        'actionUrl': actionUrl,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}
