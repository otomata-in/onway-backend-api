import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final _api = BuyerApiService();

  HomeBloc() : super(const HomeState()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeCategoryChanged>(_onCategoryChanged);
    on<HomeNavIndexChanged>(_onNavIndexChanged);
    on<HomeVendorToggleFavorite>(_onVendorToggleFavorite);
    on<HomeSearchQueryChanged>(_onSearchQueryChanged);
    on<HomeLocationSelected>(_onLocationSelected);
    on<HomeBookingCancelRequested>(_onBookingCancelRequested);
    on<HomeBookingCreated>(_onBookingCreated);
  }

  /// Emoji mapping for vendor categories
  String _emojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fish':
      case 'seafood':
        return '🐟';
      case 'vegetables':
      case 'organic vegetables':
        return '🥬';
      case 'fruits':
        return '🍎';
      case 'meat':
      case 'poultry':
        return '🥩';
      case 'bakery':
        return '🍞';
      case 'dairy':
        return '🥛';
      default:
        return '🛍️';
    }
  }

  Future<void> _onLoadRequested(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // ─── Load Categories ──────────────────────────────────────
      List<CategoryInfo> categories;
      try {
        final catResponse = await _api.getCategories();
        if (catResponse['success'] == true && catResponse['data'] != null) {
          final catList = catResponse['data'] as List;
          categories = [
            const CategoryInfo(name: 'All', emoji: '🛍️'),
            ...catList.map((c) {
              final name = c is String ? c : (c['name'] ?? 'Other');
              return CategoryInfo(name: name, emoji: _emojiForCategory(name));
            }),
          ];
        } else {
          categories = _fallbackCategories;
        }
      } catch (_) {
        categories = _fallbackCategories;
      }

      // ─── Load Saved Default Address from DB ────────────────────
      double lat = state.userLatitude;
      double lng = state.userLongitude;
      bool isLocSelected = state.isLocationSelected;
      String selTitle = state.selectedAddressTitle;
      String selLine = state.selectedAddressLine;

      try {
        final addrResponse = await _api.getAddresses();
        if (addrResponse['success'] == true && addrResponse['data'] != null) {
          final addrList = addrResponse['data'] as List;
          if (addrList.isNotEmpty) {
            final defaultAddr = addrList.firstWhere(
              (a) => a['isDefault'] == true,
              orElse: () => addrList.first,
            );
            lat = (defaultAddr['latitude'] as num?)?.toDouble() ?? 10.59337;
            lng = (defaultAddr['longitude'] as num?)?.toDouble() ?? 76.080334;
            isLocSelected = true;
            selTitle = defaultAddr['title'] ?? 'Home';
            selLine = defaultAddr['addressLine'] ?? '';
          }
        }
      } catch (_) {}

      // ─── Load Nearby Vendors for position ─────────────────────
      List<VendorInfo> vendors = await _fetchVendorsForLocation(lat, lng);

      // ─── Load Active Bookings ────────────────────────────────
      List<ActiveOrderInfo> activeOrders = [];
      try {
        final bookingResponse = await _api.getActiveBookings();
        if (bookingResponse['success'] == true && bookingResponse['data'] != null) {
          final bookingList = bookingResponse['data'] as List;
          for (final b in bookingList) {
            final v = b['vendor'] ?? {};
            final vCategory = v['category'] ?? 'Organic Vegetables';
            final vName = v['businessName'] ?? v['name'] ?? b['vendorName'] ?? 'Vendor';
            final bId = b['id']?.toString() ?? b['bookingNumber']?.toString() ?? '';
            activeOrders.add(ActiveOrderInfo(
              bookingId: bId,
              vendorId: v['id'] ?? b['vendorId'] ?? '',
              vendorName: vName,
              category: vCategory,
              emoji: _emojiForCategory(vCategory),
              eta: '${b['eta'] ?? 10} mins',
              distance: '${b['distance'] ?? 1.2} km',
              progress: (b['progress'] as num?)?.toDouble() ?? 0.70,
              vendorLat: (v['currentLatitude'] as num?)?.toDouble() ?? 10.5935,
              vendorLng: (v['currentLongitude'] as num?)?.toDouble() ?? 76.0808,
              buyerLat: lat,
              buyerLng: lng,
            ));
          }
        }
      } catch (_) {}

      emit(state.copyWith(
        status: HomeStatus.loaded,
        categories: categories,
        vendors: vendors,
        activeOrders: activeOrders,
        userLatitude: lat,
        userLongitude: lng,
        isLocationSelected: isLocSelected,
        selectedAddressTitle: selTitle,
        selectedAddressLine: selLine,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to load data',
      ));
    }
  }

  Future<List<VendorInfo>> _fetchVendorsForLocation(double lat, double lng) async {
    try {
      final vendorResponse = await _api.getNearbyVendors(
        lat: lat,
        lng: lng,
        radius: 50000,
      );
      if (vendorResponse['success'] == true && vendorResponse['data'] != null) {
        final vendorList = vendorResponse['data'] as List;
        return vendorList.map<VendorInfo>((v) {
          final distMeters = (v['distance'] as num?)?.toDouble() ?? 100.0;
          final distKm = distMeters / 1000.0;
          final distStr = distMeters < 1000 ? '${distMeters.round()}m' : '${distKm.toStringAsFixed(1)} km';
          final etaMins = (distKm / 0.5).ceil().clamp(1, 60);

          return VendorInfo(
            id: v['id'] ?? '',
            name: v['businessName'] ?? 'Vendor',
            subtitle: v['category'] ?? 'Fresh Products',
            emoji: _emojiForCategory(v['category'] ?? ''),
            imagePath: v['vehicleImagePath'] ?? 'assets/images/vendor_green_valley.png',
            rating: (v['rating'] as num?)?.toDouble() ?? 4.8,
            eta: '$etaMins mins',
            distance: distStr,
            distanceMeters: distMeters,
            isLive: v['isLiveBroadcasting'] ?? false,
            category: v['category'] ?? 'Other',
            isFavorite: v['isFavorite'] ?? false,
            latitude: (v['currentLatitude'] as num?)?.toDouble() ?? 9.9792,
            longitude: (v['currentLongitude'] as num?)?.toDouble() ?? 76.2765,
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackVendors;
  }

  Future<void> _onLocationSelected(HomeLocationSelected event, Emitter<HomeState> emit) async {
    emit(state.copyWith(
      isLocationSelected: true,
      userLatitude: event.latitude,
      userLongitude: event.longitude,
      selectedAddressTitle: event.title,
      selectedAddressLine: event.addressLine,
    ));

    final vendors = await _fetchVendorsForLocation(event.latitude, event.longitude);
    emit(state.copyWith(vendors: vendors));
  }

  void _onCategoryChanged(HomeCategoryChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onNavIndexChanged(HomeNavIndexChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(navIndex: event.index));
  }

  void _onVendorToggleFavorite(HomeVendorToggleFavorite event, Emitter<HomeState> emit) {
    bool found = false;
    final updatedVendors = state.vendors.map((v) {
      if (v.name == event.vendor.name) {
        found = true;
        return v.copyWith(isFavorite: event.vendor.isFavorite);
      }
      return v;
    }).toList();

    if (!found) {
      updatedVendors.add(event.vendor.copyWith(isFavorite: true));
    }

    emit(state.copyWith(vendors: updatedVendors));

    if (event.vendor.id.isNotEmpty) {
      _api.toggleFavorite(event.vendor.id);
    }
  }

  void _onSearchQueryChanged(HomeSearchQueryChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onBookingCancelRequested(HomeBookingCancelRequested event, Emitter<HomeState> emit) async {
    final updated = state.activeOrders.where((o) => o.bookingId != event.bookingId).toList();
    emit(state.copyWith(activeOrders: updated));

    if (!event.bookingId.startsWith('demo_') && event.bookingId.isNotEmpty) {
      try {
        await _api.cancelBooking(event.bookingId);
      } catch (_) {}
    }
  }

  void _onBookingCreated(HomeBookingCreated event, Emitter<HomeState> emit) {
    final updated = List<ActiveOrderInfo>.from(state.activeOrders);
    updated.removeWhere((o) => o.bookingId == event.order.bookingId);
    updated.insert(0, event.order);
    emit(state.copyWith(activeOrders: updated));
  }

  static const _fallbackCategories = [
    CategoryInfo(name: 'All', emoji: '🛍️'),
    CategoryInfo(name: 'Fish', emoji: '🐟'),
    CategoryInfo(name: 'Vegetables', emoji: '🥬'),
    CategoryInfo(name: 'Fruits', emoji: '🍎'),
    CategoryInfo(name: 'Meat', emoji: '🥩'),
    CategoryInfo(name: 'Bakery', emoji: '🍞'),
    CategoryInfo(name: 'Dairy', emoji: '🥛'),
  ];

  static const _fallbackVendors = [
    VendorInfo(
      id: 'fallback_1',
      name: 'Perumbilavu Fresh Organic Veggies',
      subtitle: 'Organic Vegetables & Farm Produce',
      emoji: '🥬',
      imagePath: 'assets/images/vendor_green_valley.png',
      rating: 4.9,
      eta: '2 mins',
      distance: '68m',
      distanceMeters: 68.0,
      isLive: true,
      category: 'Organic Vegetables',
      isFavorite: true,
      latitude: 10.6990,
      longitude: 76.0925,
    ),
    VendorInfo(
      id: 'fallback_2',
      name: 'Perumbilavu Bakes & Snacks',
      subtitle: 'Warm Puffs, Breads & Cookies',
      emoji: '🍞',
      imagePath: 'assets/images/stitch_saved_vendor_1.png',
      rating: 4.8,
      eta: '3 mins',
      distance: '134m',
      distanceMeters: 134.0,
      isLive: true,
      category: 'Bakery',
      isFavorite: false,
      latitude: 10.6995,
      longitude: 76.0910,
    ),
    VendorInfo(
      id: 'fallback_3',
      name: 'Perumbilavu Malabar Dairy & Fresh Milk',
      subtitle: 'Pure Cow Milk, Curd & Fresh Butter',
      emoji: '🥛',
      imagePath: 'assets/images/stitch_saved_vendor_1.png',
      rating: 4.8,
      eta: '4 mins',
      distance: '208m',
      distanceMeters: 208.0,
      isLive: true,
      category: 'Dairy & Farm Produce',
      isFavorite: true,
      latitude: 10.6975,
      longitude: 76.0905,
    ),
    VendorInfo(
      id: 'fallback_4',
      name: 'Thrissur Highway Fruit Mart',
      subtitle: 'Crisp Apples, Oranges & Sweet Bananas',
      emoji: '🍎',
      imagePath: 'assets/images/vendor_green_valley.png',
      rating: 4.7,
      eta: '5 mins',
      distance: '260m',
      distanceMeters: 260.0,
      isLive: true,
      category: 'Fresh Fruits',
      isFavorite: false,
      latitude: 10.7005,
      longitude: 76.0935,
    ),
    VendorInfo(
      id: 'fallback_5',
      name: 'Perumbilavu Coast Fish & Seafood',
      subtitle: 'Fresh Coastal Sardines, Mackerels & Prawns',
      emoji: '🐟',
      imagePath: 'assets/images/stitch_saved_vendor_1.png',
      rating: 4.9,
      eta: '7 mins',
      distance: '406m',
      distanceMeters: 406.0,
      isLive: true,
      category: 'Fresh Fish & Seafood',
      isFavorite: true,
      latitude: 10.6965,
      longitude: 76.0890,
    ),
  ];
}
