import 'package:latlong2/latlong.dart';

import 'api_flag.dart';
import 'api_user.dart';
import 'clan_models.dart';

class SearchLocation {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final int flagCount;
  final bool isGeocoded;

  const SearchLocation({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.flagCount = 0,
    this.isGeocoded = false,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    final title = json['city'] as String? ?? json['title'] as String? ?? '';
    final subtitle =
        json['country'] as String? ?? json['subtitle'] as String? ?? '';
    return SearchLocation(
      title: title,
      subtitle: subtitle,
      latitude: (json['latitude'] as num?)?.toDouble() ??
          double.tryParse('${json['lat']}') ??
          0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ??
          double.tryParse('${json['lon']}') ??
          0.0,
      flagCount: (json['flagCount'] as num?)?.toInt() ?? 0,
      isGeocoded: json['isGeocoded'] == true,
    );
  }
}

class OmniSearchResult {
  final List<ApiFlag> flags;
  final List<ApiUser> users;
  final List<Clan> clans;
  final List<SearchLocation> locations;

  const OmniSearchResult({
    this.flags = const [],
    this.users = const [],
    this.clans = const [],
    this.locations = const [],
  });

  bool get isEmpty =>
      flags.isEmpty && users.isEmpty && clans.isEmpty && locations.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
