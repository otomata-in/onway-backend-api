enum NotificationType {
  friendRequest,
  tripInvite,
  rallyAlert,
  kudos,
  clanInvite,
  communityInvite,
  leaderboardChange,
  tripVoteResult,
  flagNearby,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.targetType,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => NotificationType.kudos,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'targetId': targetId,
        'targetType': targetType,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}
