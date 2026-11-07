import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API Service for OnWay Vendor Application
class VendorApiService {
  static final VendorApiService _instance = VendorApiService._internal();
  factory VendorApiService() => _instance;
  VendorApiService._internal();

  /// Change this IP to match your development machine IP address when testing on a physical device.
  /// Standard local machine fallback: 192.168.0.194, 10.0.2.2 (Android Emulator), or localhost
  String baseUrl = 'http://192.168.0.194:3001/api/v1';

  String? _jwtToken;
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences and load stored JWT auth token
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _jwtToken = _prefs?.getString('jwt_token');
  }

  Future<void> setAuthToken(String token) async {
    _jwtToken = token;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('jwt_token', token);
  }

  Future<void> clearAuthToken() async {
    _jwtToken = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('jwt_token');
  }

  String? get jwtToken => _jwtToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
      };

  // ─── AUTHENTICATION ───────────────────────────────────────────

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone.startsWith('+') ? phone : '+91$phone',
          'role': 'VENDOR',
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    String? businessName,
    String? vehicleNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone.startsWith('+') ? phone : '+91$phone',
          'otpCode': otpCode,
          'role': 'VENDOR',
          'businessName': ?businessName,
          'vehicleNumber': ?vehicleNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await setAuthToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSession() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/session'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );
      await clearAuthToken();
      return jsonDecode(response.body);
    } catch (e) {
      await clearAuthToken();
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── VENDOR PROFILE & HUD ─────────────────────────────────────

  Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/profile'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String businessName,
    required String category,
    required String vehicleNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vendor/profile'),
        headers: _headers,
        body: jsonEncode({
          'businessName': businessName,
          'category': category,
          'vehicleNumber': vehicleNumber,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOperatingHours(String operatingHours) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vendor/profile/operating-hours'),
        headers: _headers,
        body: jsonEncode({'operatingHours': operatingHours}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateVehicleImage(String vehicleImagePath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor/profile/vehicle-image'),
        headers: _headers,
        body: jsonEncode({'vehicleImagePath': vehicleImagePath}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/dashboard-stats'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleBroadcast(bool isLiveBroadcasting) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vendor/toggle-broadcast'),
        headers: _headers,
        body: jsonEncode({'isLiveBroadcasting': isLiveBroadcasting}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleDeliveryMode(bool isDeliveryMode) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vendor/toggle-delivery-mode'),
        headers: _headers,
        body: jsonEncode({'isDeliveryMode': isDeliveryMode}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor/update-location'),
        headers: _headers,
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── ORDERS & ENQUIRIES ───────────────────────────────────────

  Future<Map<String, dynamic>> getTodaysEnquiries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/todays'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrderHistory({
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;

      final uri = Uri.parse('$baseUrl/orders/history').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String enquiryId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$enquiryId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> ringBuyer(String enquiryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$enquiryId/ring-buyer'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── PRODUCT INVENTORY ────────────────────────────────────────

  Future<Map<String, dynamic>> getInventory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/inventory'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String category,
    required double price,
    String unit = 'kg',
    bool inStock = true,
    String stockLevel = 'GOOD',
    required String imagePath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor/inventory'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'category': category,
          'price': price,
          'unit': unit,
          'inStock': inStock,
          'stockLevel': stockLevel,
          'imagePath': imagePath,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    String productId, {
    bool? inStock,
    String? stockLevel,
    String? name,
    double? price,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (inStock != null) body['inStock'] = inStock;
      if (stockLevel != null) body['stockLevel'] = stockLevel;
      if (name != null) body['name'] = name;
      if (price != null) body['price'] = price;

      final response = await http.patch(
        Uri.parse('$baseUrl/vendor/inventory/$productId'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vendor/inventory/$productId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── SELLING ROUTES ───────────────────────────────────────────

  Future<Map<String, dynamic>> getRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/routes'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getActiveRoute() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/routes/active'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createRoute({
    required String name,
    String? description,
    double totalDistanceKm = 0.0,
    required List<Map<String, dynamic>> waypoints,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor/routes'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'totalDistanceKm': totalDistanceKm,
          'waypoints': waypoints,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> activateRoute(String routeId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vendor/routes/$routeId/activate'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteRoute(String routeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vendor/routes/$routeId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
