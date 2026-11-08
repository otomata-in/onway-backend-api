import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, loaded, error }

class VendorInfo extends Equatable {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final String imagePath;
  final double rating;
  final String eta;
  final String distance;
  final bool isLive;
  final String category;
  final bool isFavorite;
  final double latitude;
  final double longitude;

  const VendorInfo({
    this.id = '',
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.imagePath,
    required this.rating,
    required this.eta,
    required this.distance,
    required this.isLive,
    required this.category,
    this.isFavorite = false,
    this.latitude = 9.9792,
    this.longitude = 76.2765,
  });

  VendorInfo copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? emoji,
    String? imagePath,
    double? rating,
    String? eta,
    String? distance,
    bool? isLive,
    String? category,
    bool? isFavorite,
    double? latitude,
    double? longitude,
  }) {
    return VendorInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      eta: eta ?? this.eta,
      distance: distance ?? this.distance,
      isLive: isLive ?? this.isLive,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [id, name, subtitle, emoji, imagePath, rating, eta, distance, isLive, category, isFavorite, latitude, longitude];
}

class CategoryInfo extends Equatable {
  final String name;
  final String emoji;

  const CategoryInfo({required this.name, required this.emoji});

  @override
  List<Object?> get props => [name, emoji];
}

class ActiveOrderInfo extends Equatable {
  final String vendorId;
  final String vendorName;
  final String category;
  final String emoji;
  final String eta;
  final String distance;
  final double progress;
  final double vendorLat;
  final double vendorLng;
  final double buyerLat;
  final double buyerLng;

  const ActiveOrderInfo({
    this.vendorId = '',
    required this.vendorName,
    this.category = 'Organic Vegetables',
    this.emoji = '🥦',
    required this.eta,
    required this.distance,
    required this.progress,
    this.vendorLat = 10.5935,
    this.vendorLng = 76.0808,
    this.buyerLat = 10.59337,
    this.buyerLng = 76.080334,
  });

  @override
  List<Object?> get props => [
        vendorId,
        vendorName,
        category,
        emoji,
        eta,
        distance,
        progress,
        vendorLat,
        vendorLng,
        buyerLat,
        buyerLng,
      ];
}

class HomeState extends Equatable {
  final HomeStatus status;
  final String selectedCategory;
  final String searchQuery;
  final int navIndex;
  final List<CategoryInfo> categories;
  final List<VendorInfo> vendors;
  final List<ActiveOrderInfo> activeOrders;
  ActiveOrderInfo? get activeOrder => activeOrders.isNotEmpty ? activeOrders.first : null;
  final bool isLocationSelected;
  final double userLatitude;
  final double userLongitude;
  final String selectedAddressTitle;
  final String selectedAddressLine;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.navIndex = 0,
    this.categories = const [],
    this.vendors = const [],
    this.activeOrders = const [],
    ActiveOrderInfo? activeOrder,
    this.isLocationSelected = true,
    this.userLatitude = 10.698731,
    this.userLongitude = 76.091942,
    this.selectedAddressTitle = 'Perumbilavu Office / Home',
    this.selectedAddressLine = 'Perumbilavu Junction, Highway Road, Perumbilavu, Thrissur',
    this.errorMessage,
  });

  List<VendorInfo> get filteredVendors {
    final query = searchQuery.trim().toLowerCase();
    return vendors.where((v) {
      final matchesCategory = selectedCategory == 'All' || v.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesQuery = query.isEmpty ||
          v.name.toLowerCase().contains(query) ||
          v.subtitle.toLowerCase().contains(query) ||
          v.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  HomeState copyWith({
    HomeStatus? status,
    String? selectedCategory,
    String? searchQuery,
    int? navIndex,
    List<CategoryInfo>? categories,
    List<VendorInfo>? vendors,
    List<ActiveOrderInfo>? activeOrders,
    ActiveOrderInfo? activeOrder,
    bool? isLocationSelected,
    double? userLatitude,
    double? userLongitude,
    String? selectedAddressTitle,
    String? selectedAddressLine,
    String? errorMessage,
  }) {
    List<ActiveOrderInfo> resolvedOrders = activeOrders ?? this.activeOrders;
    if (activeOrders == null && activeOrder != null) {
      resolvedOrders = [activeOrder];
    }

    return HomeState(
      status: status ?? this.status,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      navIndex: navIndex ?? this.navIndex,
      categories: categories ?? this.categories,
      vendors: vendors ?? this.vendors,
      activeOrders: resolvedOrders,
      isLocationSelected: isLocationSelected ?? this.isLocationSelected,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      selectedAddressTitle: selectedAddressTitle ?? this.selectedAddressTitle,
      selectedAddressLine: selectedAddressLine ?? this.selectedAddressLine,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedCategory,
        searchQuery,
        navIndex,
        categories,
        vendors,
        activeOrders,
        isLocationSelected,
        userLatitude,
        userLongitude,
        selectedAddressTitle,
        selectedAddressLine,
        errorMessage,
      ];
}
