class ServiceProvider {
  final String id;
  final String name;
  final String contactPhone;
  final String contactEmail;
  final String region;
  final String logoUrl;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.contactPhone,
    required this.contactEmail,
    required this.region,
    this.logoUrl = '',
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      region: json['region'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'region': region,
        'logoUrl': logoUrl,
      };
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
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      serviceType: json['serviceType'] as String,
      terrainType: json['terrainType'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priceRange: json['priceRange'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceFromTerritoryKm:
          (json['distanceFromTerritoryKm'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
