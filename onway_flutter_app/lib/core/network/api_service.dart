import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API Service for OnWay Buyer Application
class BuyerApiService {
  static final BuyerApiService _instance = BuyerApiService._internal();
  factory BuyerApiService() => _instance;
  BuyerApiService._internal();

  /// Live Cloud Backend URL on Render
  String baseUrl = 'https://onway-backend-api.onrender.com/api/v1';

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
          'role': 'BUYER',
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
    String? fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone.startsWith('+') ? phone : '+91$phone',
          'otpCode': otpCode,
          'role': 'BUYER',
          if (fullName != null) 'fullName': fullName,
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

  // ─── VENDOR DISCOVERY ─────────────────────────────────────────

  Future<Map<String, dynamic>> getNearbyVendors({
    required double lat,
    required double lng,
    double radius = 5000,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
      };
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      final uri = Uri.parse('$baseUrl/buyer/nearby')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLiveMapVendors({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/buyer/live-map').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> scanQr(String qrData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/buyer/scan-qr'),
        headers: _headers,
        body: jsonEncode({'qrData': qrData}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buyer/categories'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorDetails(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buyer/$vendorId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorProducts(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buyer/$vendorId/products'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorRoute(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buyer/$vendorId/route'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorETA(
    String vendorId, {
    required double buyerLat,
    required double buyerLng,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/buyer/$vendorId/eta').replace(
        queryParameters: {
          'buyerLat': buyerLat.toString(),
          'buyerLng': buyerLng.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER PROFILE ────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: _headers,
        body: jsonEncode({
          'fullName': fullName,
          if (email != null) 'email': email,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(String avatarUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/avatar'),
        headers: _headers,
        body: jsonEncode({'avatarUrl': avatarUrl}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/preferences'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePreferences({
    bool? pushNotifications,
    bool? darkMode,
    String? language,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (pushNotifications != null) body['pushNotifications'] = pushNotifications;
      if (darkMode != null) body['darkMode'] = darkMode;
      if (language != null) body['language'] = language;

      final response = await http.put(
        Uri.parse('$baseUrl/user/preferences'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER ADDRESSES ──────────────────────────────────────────

  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/addresses'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addAddress({
    required String title,
    required String addressLine,
    String? deliveryInstructions,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/addresses'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'addressLine': addressLine,
          if (deliveryInstructions != null) 'deliveryInstructions': deliveryInstructions,
          'latitude': latitude,
          'longitude': longitude,
          'isDefault': isDefault,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAddress(
    String addressId, {
    String? title,
    String? addressLine,
    String? deliveryInstructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (addressLine != null) body['addressLine'] = addressLine;
      if (deliveryInstructions != null) body['deliveryInstructions'] = deliveryInstructions;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (isDefault != null) body['isDefault'] = isDefault;

      final response = await http.put(
        Uri.parse('$baseUrl/user/addresses/$addressId'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/addresses/$addressId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER FAVORITES ──────────────────────────────────────────

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/favorites'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String vendorId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/favorites/$vendorId/toggle'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER DAILY TRACKINGS ────────────────────────────────────

  Future<Map<String, dynamic>> getDailyTrackings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/daily-trackings'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTrackingPreferences(
    String vendorId, {
    bool? notifyOnReach,
    bool? ringOnReach,
    bool? dailyTracking,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (notifyOnReach != null) body['notifyOnReach'] = notifyOnReach;
      if (ringOnReach != null) body['ringOnReach'] = ringOnReach;
      if (dailyTracking != null) body['dailyTracking'] = dailyTracking;

      final response = await http.put(
        Uri.parse('$baseUrl/user/daily-trackings/$vendorId'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeTracking(String vendorId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/daily-trackings/$vendorId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER NOTIFICATIONS ──────────────────────────────────────

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/notifications'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationsAsRead({
    List<String>? notificationIds,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/notifications/mark-read'),
        headers: _headers,
        body: jsonEncode({
          if (notificationIds != null) 'notificationIds': notificationIds,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── BUYER BOOKINGS ───────────────────────────────────────────

  Future<Map<String, dynamic>> createBooking({
    required String vendorId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    bool notifyOnReach = true,
    bool ringOnReach = true,
    bool dailyTracking = false,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: _headers,
        body: jsonEncode({
          'vendorId': vendorId,
          'items': items,
          'totalAmount': totalAmount,
          'notifyOnReach': notifyOnReach,
          'ringOnReach': ringOnReach,
          'dailyTracking': dailyTracking,
          if (notes != null) 'notes': notes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getActiveBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/active'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/history'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingTracking(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId/tracking'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> reorderBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/reorder'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
