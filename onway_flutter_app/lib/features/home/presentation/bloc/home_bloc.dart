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

      if (activeOrders.isEmpty && vendors.isNotEmpty) {
        int idx = 1;
        for (final v in vendors.take(2)) {
          activeOrders.add(ActiveOrderInfo(
            bookingId: 'demo_$idx',
            vendorId: v.id,
            vendorName: v.name,
            category: v.category,
            emoji: v.emoji,
            eta: v.eta,
            distance: v.distance,
            progress: 0.75,
            vendorLat: v.latitude,
            vendorLng: v.longitude,
            buyerLat: lat,
            buyerLng: lng,
          ));
          idx++;
        }
      }

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
          final distMeters = v['distance'] ?? 1000;
          final distKm = (distMeters is num ? distMeters.toDouble() : 1000.0) / 1000.0;
          final etaMins = (distKm / 0.5).ceil();

          return VendorInfo(
            id: v['id'] ?? '',
            name: v['businessName'] ?? 'Vendor',
            subtitle: v['category'] ?? 'Fresh Products',
            emoji: _emojiForCategory(v['category'] ?? ''),
            imagePath: v['vehicleImagePath'] ?? 'assets/images/vendor_green_valley.png',
            rating: (v['rating'] as num?)?.toDouble() ?? 4.8,
            eta: '$etaMins mins',
            distance: '${distKm.toStringAsFixed(1)} km',
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
      name: 'Malabar Organic Produce',
      subtitle: 'Organic Vegetables & Produce',
      emoji: '🥦',
      imagePath: 'assets/images/vendor_green_valley.png',
      rating: 4.9,
      eta: '5 mins',
      distance: '0.4 km',
      isLive: true,
      category: 'Vegetables',
      isFavorite: true,
      latitude: 9.9792,
      longitude: 76.2765,
    ),
    VendorInfo(
      id: 'fallback_2',
      name: 'Technopark Fresh Express',
      subtitle: 'Fresh Fruits & Farm Products',
      emoji: '🍎',
      imagePath: 'assets/images/stitch_saved_vendor_1.png',
      rating: 4.8,
      eta: '8 mins',
      distance: '1.2 km',
      isLive: true,
      category: 'Fruits',
      isFavorite: false,
      latitude: 8.5585,
      longitude: 76.8820,
    ),
  ];
}
