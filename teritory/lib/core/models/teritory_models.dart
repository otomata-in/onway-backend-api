import 'package:latlong2/latlong.dart';

import 'flag_style.dart';

/// Presentation model for a flag pin rendered by the Explore map.
///
/// The data always originates from [ApiFlag]; this shape is what the pin
/// widgets draw. There is no JSON asset behind it any more.
class FlagItem {
  final String id;
  final String placeName;
  final String city;
  final String country;
  final String countryCode;
  final String continent;
  final double latitude;
  final double longitude;
  final bool isMajorFlag;
  final String category;
  final String flaggedDate;
  final String notes;
  final String photoUrl;
  final int kudos;

  /// Snapshot of the owner's flag look at the moment this flag was staked.
  final FlagStyle style;

  const FlagItem({
    required this.id,
    required this.placeName,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.isMajorFlag,
    required this.category,
    required this.flaggedDate,
    required this.notes,
    required this.photoUrl,
    this.kudos = 0,
    this.style = FlagStyle.fallback,
  });

  LatLng get coordinates => LatLng(latitude, longitude);
}

/// Presentation model for another traveler's flag pin.
class FriendFlag {
  final String id;
  final String friendName;
  final String friendAvatar;
  final String placeName;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final bool isMajorFlag;

  /// The owner's flag look, so a friend's pin carries their identity rather
  /// than a hardcoded colour.
  final FlagStyle style;
  final String flaggedTimeAgo;
  final String caption;
  final String photoUrl;
  final int kudosCount;

  const FriendFlag({
    required this.id,
    required this.friendName,
    required this.friendAvatar,
    required this.placeName,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isMajorFlag,
    this.style = FlagStyle.fallback,
    required this.flaggedTimeAgo,
    required this.caption,
    required this.photoUrl,
    this.kudosCount = 0,
  });

  LatLng get coordinates => LatLng(latitude, longitude);
}
