import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TeritoryApiService {
  static final TeritoryApiService _instance = TeritoryApiService._internal();
  static TeritoryApiService get instance => _instance;

  TeritoryApiService._internal();

  String? _token;
  String? _refreshToken;

  /// Single-flight guard: the backend revokes the old refresh token on every
  /// refresh, so parallel 401s must share one refresh call.
  Future<bool>? _refreshInFlight;

  String? get token => _token;
  String? get accessToken => _token;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static const String _tokenKey = 'teritory_access_token';
  static const String _refreshTokenKey = 'teritory_refresh_token';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      if (kDebugMode) {
        print('🌐 TeritoryApiService initialized. Token present: $isAuthenticated');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to load stored token: $e');
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _token = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> saveToken(String token) => saveTokens(accessToken: token);

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<void> clearToken() => clearTokens();

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '${AppConfig.baseUrl}$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  dynamic _handleResponse(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = res.body;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } else {
      String msg = 'Network request failed (${res.statusCode})';
      if (body is Map<String, dynamic> && body['message'] != null) {
        msg = body['message'].toString();
      }
      throw ApiException(msg, statusCode: res.statusCode, details: body);
    }
  }

  Future<http.Response> _dispatch(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) {
    final uri = _buildUri(endpoint, queryParams);
    final headers = _buildHeaders();
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers).timeout(AppConfig.requestTimeout);
      case 'POST':
        return http
            .post(uri, headers: headers, body: encoded)
            .timeout(AppConfig.requestTimeout);
      case 'PATCH':
        return http
            .patch(uri, headers: headers, body: encoded)
            .timeout(AppConfig.requestTimeout);
      case 'DELETE':
        return http
            .delete(uri, headers: headers)
            .timeout(AppConfig.requestTimeout);
    }
    throw ArgumentError('Unsupported HTTP method: $method');
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    var res = await _dispatch(
      method,
      endpoint,
      body: body,
      queryParams: queryParams,
    );

    // Expired access token: refresh once, then replay the request. Auth
    // endpoints are excluded so a bad refresh token cannot loop.
    if (res.statusCode == 401 &&
        !endpoint.startsWith('/auth/') &&
        _refreshToken != null) {
      if (await _refreshAccessToken()) {
        res = await _dispatch(
          method,
          endpoint,
          body: body,
          queryParams: queryParams,
        );
      }
    }

    return _handleResponse(res);
  }

  Future<bool> _refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    final rawRefreshToken = _refreshToken;
    if (rawRefreshToken == null || rawRefreshToken.isEmpty) return false;

    try {
      final res = await http
          .post(
            _buildUri('/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': rawRefreshToken}),
          )
          .timeout(AppConfig.requestTimeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        await clearTokens();
        return false;
      }

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final payload = decoded is Map<String, dynamic>
          ? (decoded['data'] as Map<String, dynamic>?) ?? decoded
          : null;
      final accessToken = payload?['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        await clearTokens();
        return false;
      }

      await saveTokens(
        accessToken: accessToken,
        refreshToken: payload?['refreshToken'] as String?,
      );
      if (kDebugMode) print('🔐 Access token refreshed');
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ Token refresh failed: $e');
      return false;
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) {
    return _send('GET', endpoint, queryParams: queryParams);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) {
    return _send('POST', endpoint, body: body);
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) {
    return _send('PATCH', endpoint, body: body);
  }

  Future<dynamic> delete(String endpoint) {
    return _send('DELETE', endpoint);
  }
}
