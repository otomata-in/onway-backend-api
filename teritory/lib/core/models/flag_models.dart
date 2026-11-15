class FlagComment {
  final String id;
  final String flagId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime createdAt;

  const FlagComment({
    required this.id,
    required this.flagId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory FlagComment.fromJson(Map<String, dynamic> json) {
    return FlagComment(
      id: json['id'] as String,
      flagId: json['flagId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'flagId': flagId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum ReactionType { epic, hiddenGem, greatShot }

class FlagReaction {
  final String id;
  final String flagId;
  final String userId;
  final ReactionType reactionType;

  const FlagReaction({
    required this.id,
    required this.flagId,
    required this.userId,
    required this.reactionType,
  });

  factory FlagReaction.fromJson(Map<String, dynamic> json) {
    return FlagReaction(
      id: json['id'] as String,
      flagId: json['flagId'] as String,
      userId: json['userId'] as String,
      reactionType: ReactionType.values.firstWhere(
        (e) => e.name == json['reactionType'] as String,
        orElse: () => ReactionType.epic,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'flagId': flagId,
        'userId': userId,
        'reactionType': reactionType.name,
      };
}
