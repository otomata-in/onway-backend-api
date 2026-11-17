class ServiceProvider {
  final String id;
  final String name;
  final String description;
  final String category;
  final double rating;
  final double latitude;
  final double longitude;
  final String? contactPhone;
  final String? contactEmail;
  final String? websiteUrl;
  final String? imageUrl;
  final bool isVerified;

  /// Only present when the request carried a centre point.
  final double? distanceKm;
  final List<ServiceListing> listings;

  const ServiceProvider({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.rating = 0.0,
    required this.latitude,
    required this.longitude,
    this.contactPhone,
    this.contactEmail,
    this.websiteUrl,
    this.imageUrl,
    this.isVerified = false,
    this.distanceKm,
    this.listings = const [],
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final id = json['id'] as String;
    final name = json['name'] as String? ?? '';
    final providerRating = (json['rating'] as num?)?.toDouble() ?? 0.0;
    final providerDistance = (json['distanceKm'] as num?)?.toDouble();

    return ServiceProvider(
      id: id,
      name: name,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      rating: providerRating,
      latitude: lat,
      longitude: lng,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      distanceKm: providerDistance,
      listings: (json['listings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((listing) => ServiceListing.fromJson({
                ...listing,
                'providerId': id,
                'providerName': name,
                'latitude': lat,
                'longitude': lng,
                'rating': providerRating,
                'distanceKm': providerDistance,
              }))
          .toList(),
    );
  }
}

class ServiceListing {
  final String id;
  final String providerId;
  final String providerName;
  final String serviceType;
  final String terrainType;
  final String title;
  final String description;
  final String priceRange;
  final double rating;
  final int ratingCount;
  final double latitude;
  final double longitude;
  final double distanceFromTerritoryKm;
  final List<String> imageUrls;
  final String bookingDeepLink;

  const ServiceListing({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    required this.terrainType,
    required this.title,
    required this.description,
    required this.priceRange,
    required this.rating,
    required this.ratingCount,
    required this.latitude,
    required this.longitude,
    this.distanceFromTerritoryKm = 0.0,
    this.imageUrls = const [],
    this.bookingDeepLink = '',
  });

  factory ServiceListing.fromJson(Map<String, dynamic> json) {
    return ServiceListing(
      id: json['id'] as String,
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? json['category'] as String? ?? 'General',
      terrainType: json['terrainType'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Service',
      description: json['description'] as String? ?? '',
      priceRange: json['priceRange'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceFromTerritoryKm:
          (json['distanceFromTerritoryKm'] as num?)?.toDouble() ?? (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['imageUrl'] != null ? [json['imageUrl'] as String] : []),
      bookingDeepLink: json['bookingDeepLink'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerId': providerId,
        'providerName': providerName,
        'serviceType': serviceType,
        'terrainType': terrainType,
        'title': title,
        'description': description,
        'priceRange': priceRange,
        'rating': rating,
        'ratingCount': ratingCount,
        'latitude': latitude,
        'longitude': longitude,
        'distanceFromTerritoryKm': distanceFromTerritoryKm,
        'imageUrls': imageUrls,
        'bookingDeepLink': bookingDeepLink,
      };
}
