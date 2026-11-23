import '../config/app_config.dart';
import 'flag_style.dart';

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

  /// Signature flag carried by the profile response, so the home map can draw
  /// the traveller's own pin before any style-specific request settles.
  final FlagStyle flagStyle;

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
    this.flagStyle = FlagStyle.fallback,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Traveler',
      handle: json['handle'] as String? ?? 'traveler',
      avatarUrl: AppConfig.resolveMediaUrl(json['avatarUrl'] as String? ?? ''),
      bio: json['bio'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      authProvider: (json['authProvider'] as String? ?? 'phone').toLowerCase(),
      flagStyle: json['flagStyle'] == null
          ? FlagStyle.fallback
          : FlagStyle.fromJson(json['flagStyle']),
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
    'flagStyle': flagStyle.toJson(),
  };
}

/// Neutral stand-in for the signed-in traveler before the session gate has
/// resolved (and after sign-out).
///
/// Signed-out traffic never reaches a screen that reads it — the router holds
/// those on `/login` — so an empty id and generic name are enough, and no
/// screen is handed another traveler's identity while the app boots.
final User anonymousUser = User(
  id: '',
  email: '',
  phone: '',
  displayName: 'Traveler',
  handle: '',
  avatarUrl: '',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  authProvider: 'anonymous',
);
