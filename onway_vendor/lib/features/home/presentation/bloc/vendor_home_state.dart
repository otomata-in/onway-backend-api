import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final bool inStock;
  final String stockLevel; // Good, Medium, Low
  final String imagePath;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    this.inStock = true,
    this.stockLevel = 'Good',
    required this.imagePath,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? inStock,
    String? stockLevel,
    String? imagePath,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      inStock: inStock ?? this.inStock,
      stockLevel: stockLevel ?? this.stockLevel,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  List<Object?> get props => [id, name, category, inStock, stockLevel, imagePath];
}

class BuyerEnquiry extends Equatable {
  final String enquiryId;
  final String buyerName;
  final String buyerPhone;
  final String itemsSummary;
  final int distanceMeters;
  final String timeAgo;
  final String status; // Pending, Completed, Incomplete, Missed
  final String waypointName;
  final double priceAmount;
  final DateTime? timestamp;
  final LatLng location;

  const BuyerEnquiry({
    required this.enquiryId,
    required this.buyerName,
    required this.buyerPhone,
    required this.itemsSummary,
    required this.distanceMeters,
    required this.timeAgo,
    this.status = 'Pending',
    this.waypointName = 'Ernakulam South Station',
    this.priceAmount = 450.0,
    this.timestamp,
    this.location = const LatLng(9.9700, 76.2850),
  });

  BuyerEnquiry copyWith({
    String? enquiryId,
    String? buyerName,
    String? buyerPhone,
    String? itemsSummary,
    int? distanceMeters,
    String? timeAgo,
    String? status,
    String? waypointName,
    double? priceAmount,
    DateTime? timestamp,
    LatLng? location,
  }) {
    return BuyerEnquiry(
      enquiryId: enquiryId ?? this.enquiryId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      timeAgo: timeAgo ?? this.timeAgo,
      status: status ?? this.status,
      waypointName: waypointName ?? this.waypointName,
      priceAmount: priceAmount ?? this.priceAmount,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        enquiryId,
        buyerName,
        buyerPhone,
        itemsSummary,
        distanceMeters,
        timeAgo,
        status,
        waypointName,
        priceAmount,
        timestamp,
        location,
      ];
}

class RouteWaypoint extends Equatable {
  final String id;
  final String name;
  final LatLng point;
  final bool isStart;
  final bool isEnd;

  const RouteWaypoint({
    required this.id,
    required this.name,
    required this.point,
    this.isStart = false,
    this.isEnd = false,
  });

  @override
  List<Object?> get props => [id, name, point.latitude, point.longitude, isStart, isEnd];
}

class VendorRoute extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<RouteWaypoint> waypoints;
  final List<LatLng>? customRoadPolyline;
  final bool isActive;

  const VendorRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
    this.customRoadPolyline,
    this.isActive = false,
  });

  List<LatLng> get polylinePoints => customRoadPolyline != null && customRoadPolyline!.isNotEmpty
      ? customRoadPolyline!
      : waypoints.map((w) => w.point).toList();

  String get startPointName => waypoints.firstWhere((w) => w.isStart, orElse: () => waypoints.first).name;
  String get endPointName => waypoints.firstWhere((w) => w.isEnd, orElse: () => waypoints.last).name;

  VendorRoute copyWith({
    String? id,
    String? name,
    String? description,
    List<RouteWaypoint>? waypoints,
    List<LatLng>? customRoadPolyline,
    bool? isActive,
  }) {
    return VendorRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      waypoints: waypoints ?? this.waypoints,
      customRoadPolyline: customRoadPolyline ?? this.customRoadPolyline,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, description, waypoints, customRoadPolyline, isActive];
}

class VendorHomeState extends Equatable {
  final bool isLiveRouteActive;
  final bool isDeliveryModeActive;
  final int navIndex;
  final String vendorName;
  final String vehicleNumber;
  final String vehicleImagePath;
  final String category;
  final String operatingHours;
  final int totalEnquiries;
  final int todaysEnquiriesCount;
  final LatLng currentVehicleLocation;
  final List<InventoryItem> inventory;
  final List<BuyerEnquiry> enquiries;
  final List<VendorRoute> savedRoutes;

  const VendorHomeState({
    this.isLiveRouteActive = true,
    this.isDeliveryModeActive = false,
    this.navIndex = 0,
    this.vendorName = 'Malabar Organic Produce',
    this.vehicleNumber = 'KL-07-CD-9821',
    this.vehicleImagePath = 'assets/images/vendor_green_valley.png',
    this.category = 'Organic Vegetables',
    this.operatingHours = '7:00 AM - 7:00 PM Daily',
    this.totalEnquiries = 42,
    this.todaysEnquiriesCount = 12,
    this.currentVehicleLocation = const LatLng(9.9790, 76.2760),
    this.inventory = const [
      InventoryItem(
        id: '1',
        name: 'Fresh Organic Spinach (Cheera)',
        category: 'Vegetables',
        inStock: true,
        stockLevel: 'Good',
        imagePath: 'assets/images/vendor_green_valley.png',
      ),
      InventoryItem(
        id: '2',
        name: 'Farm Fresh Tomatoes',
        category: 'Vegetables',
        inStock: true,
        stockLevel: 'Medium',
        imagePath: 'assets/images/stitch_saved_vendor_1.png',
      ),
      InventoryItem(
        id: '3',
        name: 'Red Bell Peppers',
        category: 'Vegetables',
        inStock: true,
        stockLevel: 'Low',
        imagePath: 'assets/images/stitch_saved_vendor_2.png',
      ),
      InventoryItem(
        id: '4',
        name: 'Organic Broccoli',
        category: 'Vegetables',
        inStock: false,
        stockLevel: 'Low',
        imagePath: 'assets/images/vendor_ocean_catch.png',
      ),
    ],
    this.enquiries = const [
      BuyerEnquiry(
        enquiryId: 'ENQ-101',
        buyerName: 'Akhil V A',
        buyerPhone: '+91 98765 43210',
        itemsSummary: '2x Organic Spinach, 1kg Tomatoes',
        distanceMeters: 80,
        timeAgo: '3 mins ago',
        status: 'Pending',
        waypointName: 'Ernakulam South Station',
        priceAmount: 480.0,
        location: LatLng(9.9695, 76.2890),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-102',
        buyerName: 'Rahul Sharma',
        buyerPhone: '+91 91234 56789',
        itemsSummary: '1kg Red Bell Peppers',
        distanceMeters: 180,
        timeAgo: '12 mins ago',
        status: 'Pending',
        waypointName: 'Marine Drive Kochi',
        priceAmount: 320.0,
        location: LatLng(9.9780, 76.2770),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-103',
        buyerName: 'Priya Nair',
        buyerPhone: '+91 99887 76655',
        itemsSummary: '3x Organic Spinach',
        distanceMeters: 320,
        timeAgo: '25 mins ago',
        status: 'Completed',
        waypointName: 'Lulu Mall Edappally',
        priceAmount: 650.0,
        location: LatLng(10.0270, 76.3080),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-104',
        buyerName: 'Suresh Kumar',
        buyerPhone: '+91 94455 66778',
        itemsSummary: '2kg Fresh Farm Tomatoes',
        distanceMeters: 650,
        timeAgo: '40 mins ago',
        status: 'Pending',
        waypointName: 'Aluva Railway Station',
        priceAmount: 890.0,
        location: LatLng(10.1080, 76.3490),
      ),
      BuyerEnquiry(
        enquiryId: 'ENQ-105',
        buyerName: 'Anil Kumar',
        buyerPhone: '+91 97441 22334',
        itemsSummary: '1kg Carrots, 500g Ginger',
        distanceMeters: 920,
        timeAgo: '1 hour ago',
        status: 'Missed',
        waypointName: 'Kalamassery Market',
        priceAmount: 210.0,
        location: LatLng(10.0500, 76.3200),
      ),
    ],
    this.savedRoutes = const [
      VendorRoute(
        id: 'r1',
        name: 'Kochi - Aluva Metro Selling Route',
        description: '4 Waypoints • 14.8 km • Active Route',
        isActive: true,
        waypoints: [
          RouteWaypoint(id: 'w1', name: 'Ernakulam South Station', point: LatLng(9.9687, 76.2897), isStart: true),
          RouteWaypoint(id: 'w2', name: 'Marine Drive Kochi', point: LatLng(9.9790, 76.2760)),
          RouteWaypoint(id: 'w3', name: 'Lulu Mall Edappally', point: LatLng(10.0270, 76.3080)),
          RouteWaypoint(id: 'w4', name: 'Aluva Railway Station', point: LatLng(10.1090, 76.3500), isEnd: true),
        ],
      ),
      VendorRoute(
        id: 'r2',
        name: 'Trivandrum Central - Technopark Route',
        description: '4 Waypoints • 16.5 km',
        isActive: false,
        waypoints: [
          RouteWaypoint(id: 'w1', name: 'East Fort Stand', point: LatLng(8.4830, 76.9480), isStart: true),
          RouteWaypoint(id: 'w2', name: 'Trivandrum Central Station', point: LatLng(8.4870, 76.9530)),
          RouteWaypoint(id: 'w3', name: 'Kazhakkoottam Junction', point: LatLng(8.5670, 76.8770)),
          RouteWaypoint(id: 'w4', name: 'Technopark Phase 1', point: LatLng(8.5580, 76.8820), isEnd: true),
        ],
      ),
      VendorRoute(
        id: 'r3',
        name: 'Manjeri - Malappuram Town Route',
        description: '4 Waypoints • 22.0 km',
        isActive: false,
        waypoints: [
          RouteWaypoint(id: 'w1', name: 'Tirur Railway Station', point: LatLng(10.9160, 75.9230), isStart: true),
          RouteWaypoint(id: 'w2', name: 'Kottakkal Arya Vaidya Sala', point: LatLng(11.0010, 75.9980)),
          RouteWaypoint(id: 'w3', name: 'Malappuram KSRTC Stand', point: LatLng(11.0730, 76.0740)),
          RouteWaypoint(id: 'w4', name: 'Manjeri Town Center', point: LatLng(11.1210, 76.1210), isEnd: true),
        ],
      ),
      VendorRoute(
        id: 'r4',
        name: 'Kozhikode Beach - Mavoor Road Route',
        description: '3 Waypoints • 9.2 km',
        isActive: false,
        waypoints: [
          RouteWaypoint(id: 'w1', name: 'Kozhikode Beach Promenade', point: LatLng(11.2610, 75.7700), isStart: true),
          RouteWaypoint(id: 'w2', name: 'Mananchira Square', point: LatLng(11.2520, 75.7800)),
          RouteWaypoint(id: 'w3', name: 'Mavoor Road Bus Stand', point: LatLng(11.2580, 75.7900), isEnd: true),
        ],
      ),
      VendorRoute(
        id: 'r5',
        name: 'Thrissur Round - Guruvayur Route',
        description: '3 Waypoints • 26.0 km',
        isActive: false,
        waypoints: [
          RouteWaypoint(id: 'w1', name: 'Thrissur Swaraj Round', point: LatLng(10.5270, 76.2140), isStart: true),
          RouteWaypoint(id: 'w2', name: 'Kunnamkulam Market', point: LatLng(10.6500, 76.0700)),
          RouteWaypoint(id: 'w3', name: 'Guruvayur Temple Gate', point: LatLng(10.5940, 76.0390), isEnd: true),
        ],
      ),
    ],
  });

  VendorRoute get activeRoute =>
      savedRoutes.firstWhere((r) => r.isActive, orElse: () => savedRoutes.first);

  int get completedOrdersCount => enquiries.where((e) => e.status == 'Completed').length;
  int get incompletedOrdersCount => enquiries.where((e) => e.status == 'Pending' || e.status == 'Incomplete').length;
  int get missedOrdersCount => enquiries.where((e) => e.status == 'Missed').length;

  VendorHomeState copyWith({
    bool? isLiveRouteActive,
    bool? isDeliveryModeActive,
    int? navIndex,
    String? vendorName,
    String? vehicleNumber,
    String? vehicleImagePath,
    String? category,
    String? operatingHours,
    int? totalEnquiries,
    int? todaysEnquiriesCount,
    LatLng? currentVehicleLocation,
    List<InventoryItem>? inventory,
    List<BuyerEnquiry>? enquiries,
    List<VendorRoute>? savedRoutes,
  }) {
    return VendorHomeState(
      isLiveRouteActive: isLiveRouteActive ?? this.isLiveRouteActive,
      isDeliveryModeActive: isDeliveryModeActive ?? this.isDeliveryModeActive,
      navIndex: navIndex ?? this.navIndex,
      vendorName: vendorName ?? this.vendorName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleImagePath: vehicleImagePath ?? this.vehicleImagePath,
      category: category ?? this.category,
      operatingHours: operatingHours ?? this.operatingHours,
      totalEnquiries: totalEnquiries ?? this.totalEnquiries,
      todaysEnquiriesCount: todaysEnquiriesCount ?? this.todaysEnquiriesCount,
      currentVehicleLocation: currentVehicleLocation ?? this.currentVehicleLocation,
      inventory: inventory ?? this.inventory,
      enquiries: enquiries ?? this.enquiries,
      savedRoutes: savedRoutes ?? this.savedRoutes,
    );
  }

  @override
  List<Object?> get props => [
        isLiveRouteActive,
        isDeliveryModeActive,
        navIndex,
        vendorName,
        vehicleNumber,
        vehicleImagePath,
        category,
        operatingHours,
        totalEnquiries,
        todaysEnquiriesCount,
        currentVehicleLocation,
        inventory,
        enquiries,
        savedRoutes,
      ];
}
