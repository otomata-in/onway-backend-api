import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_service.dart';
import 'vendor_home_event.dart';
import 'vendor_home_state.dart';

class VendorHomeBloc extends Bloc<VendorHomeEvent, VendorHomeState> {
  final VendorApiService _api = VendorApiService();

  VendorHomeBloc() : super(const VendorHomeState()) {
    on<VendorLoadRequested>(_onLoadRequested);
    on<VendorToggleLiveRoute>(_onToggleLiveRoute);
    on<VendorToggleDeliveryMode>(_onToggleDeliveryMode);
    on<VendorNavIndexChanged>(_onNavIndexChanged);
    on<VendorToggleItemStock>(_onToggleItemStock);
    on<VendorUpdateStockLevel>(_onUpdateStockLevel);
    on<VendorAddItem>(_onAddItem);
    on<VendorUpdateVehiclePhoto>(_onUpdateVehiclePhoto);
    on<VendorUpdateOperatingHours>(_onUpdateOperatingHours);
    on<VendorUpdateEnquiryStatus>(_onUpdateEnquiryStatus);
    on<VendorRingBuyer>(_onRingBuyer);
    on<VendorSelectRoute>(_onSelectRoute);
    on<VendorSaveNewRoute>(_onSaveNewRoute);
    on<VendorUpdateRoute>(_onUpdateRoute);
    on<VendorDeleteRoute>(_onDeleteRoute);
    on<VendorUpdateProfile>(_onUpdateProfile);

    // Initial fetch on creation
    add(const VendorLoadRequested());
  }

  Future<void> _onLoadRequested(VendorLoadRequested event, Emitter<VendorHomeState> emit) async {
    if (_api.jwtToken == null) {
      return;
    }
    try {
      // 1. Fetch Profile
      final profileRes = await _api.getVendorProfile();
      String vendorName = state.vendorName;
      String vehicleNumber = state.vehicleNumber;
      String category = state.category;
      String operatingHours = state.operatingHours;
      bool isLiveRouteActive = state.isLiveRouteActive;
      bool isDeliveryModeActive = state.isDeliveryModeActive;

      if (profileRes['success'] == true && profileRes['data'] != null) {
        final p = profileRes['data'];
        vendorName = p['businessName'] ?? vendorName;
        vehicleNumber = p['vehicleNumber'] ?? vehicleNumber;
        category = p['category'] ?? category;
        operatingHours = p['operatingHours'] ?? operatingHours;
        isLiveRouteActive = p['isLiveBroadcasting'] ?? isLiveRouteActive;
        isDeliveryModeActive = p['isDeliveryMode'] ?? isDeliveryModeActive;
      }

      // 2. Fetch Inventory
      List<InventoryItem> inventory = state.inventory;
      final invRes = await _api.getInventory();
      if (invRes['success'] == true && invRes['data'] != null) {
        final list = invRes['data'] as List;
        if (list.isNotEmpty) {
          inventory = list.map<InventoryItem>((item) {
            return InventoryItem(
              id: item['id'] ?? '',
              name: item['name'] ?? 'Product',
              category: item['category'] ?? 'General',
              inStock: item['inStock'] ?? true,
              stockLevel: item['stockLevel'] ?? 'GOOD',
              imagePath: item['imagePath'] ?? 'assets/images/vegetables.png',
            );
          }).toList();
        }
      }

      // 3. Fetch Routes
      List<VendorRoute> savedRoutes = state.savedRoutes;
      final routesRes = await _api.getRoutes();
      if (routesRes['success'] == true && routesRes['data'] != null) {
        final list = routesRes['data'] as List;
        if (list.isNotEmpty) {
          savedRoutes = list.map<VendorRoute>((r) {
            final waypointsList = (r['waypoints'] as List? ?? []).map<RouteWaypoint>((w) {
              return RouteWaypoint(
                id: w['id'] ?? '',
                name: w['name'] ?? 'Waypoint',
                point: LatLng((w['latitude'] as num?)?.toDouble() ?? 9.9790, (w['longitude'] as num?)?.toDouble() ?? 76.2760),
                isStart: w['isStart'] ?? false,
                isEnd: w['isEnd'] ?? false,
              );
            }).toList();

            return VendorRoute(
              id: r['id'] ?? '',
              name: r['name'] ?? 'Route',
              description: r['description'] ?? 'Waypoint Route',
              waypoints: waypointsList,
              isActive: r['isActive'] ?? false,
            );
          }).toList();
        }
      }

      emit(state.copyWith(
        vendorName: vendorName,
        vehicleNumber: vehicleNumber,
        category: category,
        operatingHours: operatingHours,
        isLiveRouteActive: isLiveRouteActive,
        isDeliveryModeActive: isDeliveryModeActive,
        inventory: inventory,
        savedRoutes: savedRoutes,
      ));
    } catch (_) {}
  }

  Future<void> _onToggleLiveRoute(VendorToggleLiveRoute event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(isLiveRouteActive: event.isActive));
    await _api.toggleBroadcast(event.isActive);
  }

  Future<void> _onToggleDeliveryMode(VendorToggleDeliveryMode event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(isDeliveryModeActive: event.isDeliveryModeActive));
    await _api.toggleDeliveryMode(event.isDeliveryModeActive);
  }

  void _onNavIndexChanged(VendorNavIndexChanged event, Emitter<VendorHomeState> emit) {
    emit(state.copyWith(navIndex: event.index));
  }

  Future<void> _onToggleItemStock(VendorToggleItemStock event, Emitter<VendorHomeState> emit) async {
    final updated = state.inventory.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(inStock: event.inStock);
      }
      return item;
    }).toList();
    emit(state.copyWith(inventory: updated));
    await _api.updateProduct(event.itemId, inStock: event.inStock);
  }

  Future<void> _onUpdateStockLevel(VendorUpdateStockLevel event, Emitter<VendorHomeState> emit) async {
    final updated = state.inventory.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(stockLevel: event.newStockLevel);
      }
      return item;
    }).toList();
    emit(state.copyWith(inventory: updated));
    await _api.updateProduct(event.itemId, stockLevel: event.newStockLevel);
  }

  Future<void> _onAddItem(VendorAddItem event, Emitter<VendorHomeState> emit) async {
    final updated = List<InventoryItem>.from(state.inventory)..add(event.item);
    emit(state.copyWith(inventory: updated));
    await _api.addProduct(
      name: event.item.name,
      category: event.item.category,
      price: 0.0,
      unit: 'kg',
      inStock: event.item.inStock,
      stockLevel: event.item.stockLevel,
      imagePath: event.item.imagePath,
    );
  }

  Future<void> _onUpdateVehiclePhoto(VendorUpdateVehiclePhoto event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(vehicleImagePath: event.imagePath));
    await _api.updateVehicleImage(event.imagePath);
  }

  Future<void> _onUpdateOperatingHours(VendorUpdateOperatingHours event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(operatingHours: event.operatingHours));
    await _api.updateOperatingHours(event.operatingHours);
  }

  Future<void> _onUpdateEnquiryStatus(VendorUpdateEnquiryStatus event, Emitter<VendorHomeState> emit) async {
    final updated = state.enquiries.map((enquiry) {
      if (enquiry.enquiryId == event.enquiryId) {
        return enquiry.copyWith(status: event.newStatus);
      }
      return enquiry;
    }).toList();
    emit(state.copyWith(enquiries: updated));
    await _api.updateOrderStatus(event.enquiryId, event.newStatus.toUpperCase());
  }

  Future<void> _onRingBuyer(VendorRingBuyer event, Emitter<VendorHomeState> emit) async {
    await _api.ringBuyer(event.enquiryId);
  }

  Future<void> _onSelectRoute(VendorSelectRoute event, Emitter<VendorHomeState> emit) async {
    final updated = state.savedRoutes.map((r) {
      return r.copyWith(isActive: r.id == event.routeId);
    }).toList();
    emit(state.copyWith(savedRoutes: updated));
    await _api.activateRoute(event.routeId);
  }

  Future<void> _onSaveNewRoute(VendorSaveNewRoute event, Emitter<VendorHomeState> emit) async {
    final deactiveList = state.savedRoutes.map((r) => r.copyWith(isActive: false)).toList();
    final newRoute = event.route.copyWith(isActive: true);
    emit(state.copyWith(savedRoutes: [...deactiveList, newRoute]));

    final waypointsList = event.route.waypoints.map((wp) => {
      'name': wp.name,
      'latitude': wp.point.latitude,
      'longitude': wp.point.longitude,
      'sequenceOrder': event.route.waypoints.indexOf(wp),
      'isStart': wp.isStart,
      'isEnd': wp.isEnd,
    }).toList();

    await _api.createRoute(
      name: event.route.name,
      description: event.route.description,
      waypoints: waypointsList,
    );
  }

  void _onUpdateRoute(VendorUpdateRoute event, Emitter<VendorHomeState> emit) {
    final updated = state.savedRoutes.map((r) {
      if (r.id == event.route.id) {
        return event.route;
      }
      return r;
    }).toList();
    emit(state.copyWith(savedRoutes: updated));
  }

  Future<void> _onDeleteRoute(VendorDeleteRoute event, Emitter<VendorHomeState> emit) async {
    final updated = state.savedRoutes.where((r) => r.id != event.routeId).toList();
    emit(state.copyWith(savedRoutes: updated));
    await _api.deleteRoute(event.routeId);
  }

  Future<void> _onUpdateProfile(VendorUpdateProfile event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(
      vendorName: event.vendorName,
      vehicleNumber: event.vehicleNumber,
      category: event.category,
    ));
    await _api.updateProfile(
      businessName: event.vendorName,
      category: event.category,
      vehicleNumber: event.vehicleNumber,
    );
  }
}
