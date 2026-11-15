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
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static const String _tokenKey = 'teritory_access_token';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      if (kDebugMode) {
        print('🌐 TeritoryApiService initialized. Token present: $isAuthenticated');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to load stored token: $e');
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

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

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await http
        .get(uri, headers: _buildHeaders())
        .timeout(AppConfig.requestTimeout);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = _buildUri(endpoint);
    final response = await http
        .post(
          uri,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConfig.requestTimeout);
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    final uri = _buildUri(endpoint);
    final response = await http
        .patch(
          uri,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConfig.requestTimeout);
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = _buildUri(endpoint);
    final response = await http
        .delete(uri, headers: _buildHeaders())
        .timeout(AppConfig.requestTimeout);
    return _handleResponse(response);
  }
}
