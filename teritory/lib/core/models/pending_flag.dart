import 'package:latlong2/latlong.dart';

import 'flag_style.dart';

/// A flag the traveller staked somewhere the request could not reach the
/// server.
///
/// It lives on the device rather than in memory only, because the point is to
/// survive a closed app in a valley with no signal. [lastError] is the honest
/// reason the newest sync attempt did not land, shown next to the pending pin —
/// the queue never pretends a flag is staked until the server says so.
class PendingFlag {
  final String localId;

  /// Who staked it. A queue entry belongs to that traveler: it is never replayed
  /// with the next person's token after a sign-out.
  final String userId;

  final String placeName;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String countryCode;
  final String continent;
  final bool isMajorFlag;
  final String category;
  final String notes;
  final String? photoUrl;

  /// The style chosen when the flag was staked offline. Kept so replaying the
  /// queue does not silently restyle the flag to whatever the signature is by
  /// the time signal returns.
  final FlagStyle? flagStyle;
  final DateTime createdAt;

  /// Why the last attempt failed, or null before the first attempt.
  final String? lastError;
  final int attempts;

  const PendingFlag({
    required this.localId,
    required this.userId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.country = 'India',
    this.countryCode = 'IN',
    this.continent = 'Asia',
    this.isMajorFlag = false,
    this.category = 'General',
    this.notes = '',
    this.photoUrl,
    this.flagStyle,
    required this.createdAt,
    this.lastError,
    this.attempts = 0,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  FlagStyle get style => flagStyle ?? FlagStyle.fallback;

  PendingFlag copyWith({String? lastError, int? attempts}) {
    return PendingFlag(
      localId: localId,
      userId: userId,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      countryCode: countryCode,
      continent: continent,
      isMajorFlag: isMajorFlag,
      category: category,
      notes: notes,
      photoUrl: photoUrl,
      flagStyle: flagStyle,
      createdAt: createdAt,
      lastError: lastError ?? this.lastError,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'userId': userId,
    'placeName': placeName,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'countryCode': countryCode,
    'continent': continent,
    'isMajorFlag': isMajorFlag,
    'category': category,
    'notes': notes,
    'photoUrl': photoUrl,
    'flagStyle': flagStyle?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'lastError': lastError,
    'attempts': attempts,
  };

  factory PendingFlag.fromJson(Map<String, dynamic> json) {
    return PendingFlag(
      localId: json['localId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      placeName: json['placeName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      countryCode: json['countryCode'] as String? ?? 'IN',
      continent: json['continent'] as String? ?? 'Asia',
      isMajorFlag: json['isMajorFlag'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      flagStyle: json['flagStyle'] is Map
          ? FlagStyle.fromJson(json['flagStyle'])
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastError: json['lastError'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}
