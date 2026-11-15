class User {
  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String handle;
  final String avatarUrl;
  final String bio;
  final DateTime createdAt;
  final String authProvider;

  const User({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    this.bio = '',
    required this.createdAt,
    this.authProvider = 'email',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      displayName: json['displayName'] as String,
      handle: json['handle'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      authProvider: json['authProvider'] as String? ?? 'email',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'handle': handle,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'createdAt': createdAt.toIso8601String(),
        'authProvider': authProvider,
      };
}

enum FriendStatus { pending, accepted, declined }

enum FriendCategory { favorites, travelBuddies, family }

class FriendRelationship {
  final String id;
  final String userId;
  final String friendId;
  final FriendStatus status;
  final DateTime since;
  final FriendCategory? category;

  const FriendRelationship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.since,
    this.category,
  });

  factory FriendRelationship.fromJson(Map<String, dynamic> json) {
    return FriendRelationship(
      id: json['id'] as String,
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      status: FriendStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => FriendStatus.pending,
      ),
      since: DateTime.parse(json['since'] as String),
      category: json['category'] != null
          ? FriendCategory.values.firstWhere(
              (e) => e.name == json['category'] as String,
              orElse: () => FriendCategory.travelBuddies,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'friendId': friendId,
        'status': status.name,
        'since': since.toIso8601String(),
        'category': category?.name,
      };
}
