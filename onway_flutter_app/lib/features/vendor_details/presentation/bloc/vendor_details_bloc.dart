import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/models/product.dart';
import 'vendor_details_event.dart';
import 'vendor_details_state.dart';

class VendorDetailsBloc extends Bloc<VendorDetailsEvent, VendorDetailsState> {
  final _api = BuyerApiService();

  VendorDetailsBloc() : super(const VendorDetailsState()) {
    on<VendorDetailsLoadRequested>(_onLoadRequested);
    on<ToggleFavoriteRequested>(_onToggleFavorite);
    on<ToggleDailyTrackRequested>(_onToggleDailyTrack);
    on<AddToCartRequested>(_onAddToCart);
    on<RemoveFromCartRequested>(_onRemoveFromCart);
  }

  Future<List<LatLng>> _fetchOsrmRoadPolyline(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;
    try {
      final coords = waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
      final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geom = routes.first['geometry']['coordinates'] as List;
          return geom.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        }
      }
    } catch (_) {}

    // Fallback: smooth interpolation
    final List<LatLng> result = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      result.add(start);

      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;
      final latOffset = (end.longitude - start.longitude) * 0.15;
      final lngOffset = (start.latitude - end.latitude) * 0.15;

      result.add(LatLng(
        start.latitude * 0.7 + end.latitude * 0.3 + latOffset * 0.5,
        start.longitude * 0.7 + end.longitude * 0.3 + lngOffset * 0.5,
      ));
      result.add(LatLng(midLat + latOffset, midLng + lngOffset));
      result.add(LatLng(
        start.latitude * 0.3 + end.latitude * 0.7 + latOffset * 0.5,
        start.longitude * 0.3 + end.longitude * 0.7 + lngOffset * 0.5,
      ));
    }
    result.add(waypoints.last);
    return result;
  }

  void _onLoadRequested(VendorDetailsLoadRequested event, Emitter<VendorDetailsState> emit) async {
    emit(state.copyWith(status: VendorDetailsStatus.loading));

    List<Product> products = [];
    double vendorLat = 9.9792;
    double vendorLng = 76.2765;
    List<LatLng> waypointCoords = [];
    List<Map<String, dynamic>> rawWaypoints = [];

    if (event.vendorId.isNotEmpty) {
      try {
        // 1. Fetch Vendor Details (Coordinates)
        final vendorRes = await _api.getVendorDetails(event.vendorId);
        if (vendorRes['success'] == true && vendorRes['data'] != null) {
          final v = vendorRes['data'];
          vendorLat = (v['currentLatitude'] as num?)?.toDouble() ?? 9.9792;
          vendorLng = (v['currentLongitude'] as num?)?.toDouble() ?? 76.2765;
        }

        // 2. Fetch Vendor Products
        final response = await _api.getVendorProducts(event.vendorId);
        if (response['success'] == true && response['data'] != null) {
          final productList = response['data'] as List;
          products = productList.map<Product>((p) {
            return Product(
              id: p['id'] ?? '',
              name: p['name'] ?? 'Unknown Product',
              description: p['category'] ?? '',
              price: (p['price'] as num?)?.toDouble() ?? 0.0,
              unit: p['unit'] ?? 'kg',
              imagePath: p['imagePath'] ?? 'assets/images/vegetables.png',
            );
          }).toList();
        }

        // 3. Fetch Vendor Route for live map polyline
        final routeRes = await _api.getVendorRoute(event.vendorId);
        if (routeRes['success'] == true && routeRes['data'] != null) {
          final waypoints = routeRes['data']['waypoints'] as List? ?? [];
          rawWaypoints = waypoints.map<Map<String, dynamic>>((w) => {
            'id': w['id'] ?? '',
            'name': w['name'] ?? 'Stop',
            'latitude': (w['latitude'] as num?)?.toDouble() ?? 9.9790,
            'longitude': (w['longitude'] as num?)?.toDouble() ?? 76.2760,
            'isStart': w['isStart'] ?? false,
            'isEnd': w['isEnd'] ?? false,
          }).toList();

          waypointCoords = rawWaypoints.map<LatLng>((w) => LatLng(w['latitude'], w['longitude'])).toList();
        }
      } catch (_) {}
    }

    if (products.isEmpty) {
      products = _fallbackProducts;
    }

    if (waypointCoords.isEmpty) {
      waypointCoords = [
        LatLng(vendorLat, vendorLng),
        LatLng(vendorLat + 0.005, vendorLng + 0.005),
        LatLng(vendorLat + 0.010, vendorLng + 0.010),
      ];
      rawWaypoints = [
        {'name': 'Start Hub', 'latitude': vendorLat, 'longitude': vendorLng, 'isStart': true, 'isEnd': false},
        {'name': 'Destination Terminus', 'latitude': vendorLat + 0.010, 'longitude': vendorLng + 0.010, 'isStart': false, 'isEnd': true},
      ];
    }

    final roadPolyline = await _fetchOsrmRoadPolyline(waypointCoords);

    emit(state.copyWith(
      status: VendorDetailsStatus.loaded,
      products: products,
      vendorLat: vendorLat,
      vendorLng: vendorLng,
      routePoints: roadPolyline,
      rawWaypoints: rawWaypoints,
    ));
  }

  void _onToggleFavorite(ToggleFavoriteRequested event, Emitter<VendorDetailsState> emit) {
    emit(state.copyWith(isFavorite: !state.isFavorite));
  }

  void _onToggleDailyTrack(ToggleDailyTrackRequested event, Emitter<VendorDetailsState> emit) {
    emit(state.copyWith(isDailyTracked: !state.isDailyTracked));
  }

  void _onAddToCart(AddToCartRequested event, Emitter<VendorDetailsState> emit) {
    final currentQty = state.cartQuantity[event.product.id] ?? 0;
    final updatedCart = Map<String, int>.from(state.cartQuantity);
    updatedCart[event.product.id] = currentQty + 1;
    emit(state.copyWith(cartQuantity: updatedCart));
  }

  void _onRemoveFromCart(RemoveFromCartRequested event, Emitter<VendorDetailsState> emit) {
    final currentQty = state.cartQuantity[event.product.id] ?? 0;
    if (currentQty > 0) {
      final updatedCart = Map<String, int>.from(state.cartQuantity);
      updatedCart[event.product.id] = currentQty - 1;
      if (updatedCart[event.product.id] == 0) {
        updatedCart.remove(event.product.id);
      }
      emit(state.copyWith(cartQuantity: updatedCart));
    }
  }

  static const _fallbackProducts = [
    Product(
      id: 'p1',
      name: 'Organic Red Tomatoes',
      description: 'Farm Fresh Harvest',
      price: 0.0,
      unit: 'kg',
      imagePath: 'assets/images/vegetables.png',
    ),
    Product(
      id: 'p2',
      name: 'Farm Fresh Bananas',
      description: 'Sweet Organic Bananas',
      price: 0.0,
      unit: 'dozen',
      imagePath: 'assets/images/vegetables.png',
    ),
    Product(
      id: 'p3',
      name: 'Tender Coconut Water',
      description: 'Natural Energy Drink',
      price: 0.0,
      unit: 'piece',
      imagePath: 'assets/images/vegetables.png',
    ),
  ];
}
