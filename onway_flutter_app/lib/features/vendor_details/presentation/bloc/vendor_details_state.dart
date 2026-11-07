import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/product.dart';

enum VendorDetailsStatus { initial, loading, loaded, error }

class VendorDetailsState extends Equatable {
  final VendorDetailsStatus status;
  final List<Product> products;
  final bool isFavorite;
  final bool isDailyTracked;
  final Map<String, int> cartQuantity;
  final double vendorLat;
  final double vendorLng;
  final List<LatLng> routePoints;
  final List<Map<String, dynamic>> rawWaypoints;
  final String? errorMessage;

  const VendorDetailsState({
    this.status = VendorDetailsStatus.initial,
    this.products = const [],
    this.isFavorite = false,
    this.isDailyTracked = false,
    this.cartQuantity = const {},
    this.vendorLat = 9.9792,
    this.vendorLng = 76.2765,
    this.routePoints = const [],
    this.rawWaypoints = const [],
    this.errorMessage,
  });

  VendorDetailsState copyWith({
    VendorDetailsStatus? status,
    List<Product>? products,
    bool? isFavorite,
    bool? isDailyTracked,
    Map<String, int>? cartQuantity,
    double? vendorLat,
    double? vendorLng,
    List<LatLng>? routePoints,
    List<Map<String, dynamic>>? rawWaypoints,
    String? errorMessage,
  }) {
    return VendorDetailsState(
      status: status ?? this.status,
      products: products ?? this.products,
      isFavorite: isFavorite ?? this.isFavorite,
      isDailyTracked: isDailyTracked ?? this.isDailyTracked,
      cartQuantity: cartQuantity ?? this.cartQuantity,
      vendorLat: vendorLat ?? this.vendorLat,
      vendorLng: vendorLng ?? this.vendorLng,
      routePoints: routePoints ?? this.routePoints,
      rawWaypoints: rawWaypoints ?? this.rawWaypoints,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, isFavorite, isDailyTracked, cartQuantity, vendorLat, vendorLng, routePoints, rawWaypoints, errorMessage];
}
