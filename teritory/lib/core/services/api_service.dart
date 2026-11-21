import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  /// Session tokens belong in the platform keystore/keychain, not in plain
  /// preferences.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Set when the platform store rejects us (a desktop/test host with no
  /// keyring). The session then lives in memory for this run only — it is never
  /// written to plaintext storage as a fallback.
  bool _secureStorageUnavailable = false;

  Future<void> init() async {
    try {
      _token = await _secureStorage.read(key: _tokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (_token == null || _token!.isEmpty) {
        await _migrateLegacyTokens();
      }
      if (kDebugMode) {
        print('🌐 TeritoryApiService initialized. Token present: $isAuthenticated');
      }
    } catch (e) {
      _secureStorageUnavailable = true;
      if (kDebugMode) {
        print('⚠️ Secure storage unavailable; session is memory-only: $e');
      }
    }
  }

  /// Older builds kept the tokens in `SharedPreferences`. Move them into secure
  /// storage once, and only then delete the plaintext copies.
  Future<void> _migrateLegacyTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return;
    final legacyRefresh = prefs.getString(_refreshTokenKey);

    final moved = await _persist(_tokenKey, legacyToken);
    if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
      await _persist(_refreshTokenKey, legacyRefresh);
    }
    if (!moved) return; // keep the plaintext copy rather than lose the session

    _token = legacyToken;
    if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
      _refreshToken = legacyRefresh;
    }
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    if (kDebugMode) print('🔐 Migrated the stored session into secure storage');
  }

  Future<bool> _persist(String key, String value) async {
    if (_secureStorageUnavailable) return false;
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      _secureStorageUnavailable = true;
      if (kDebugMode) print('⚠️ Could not write $key to secure storage: $e');
      return false;
    }
  }

  Future<void> _erase(String key) async {
    if (_secureStorageUnavailable) return;
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not delete $key from secure storage: $e');
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _token = accessToken;
    final nextRefresh = (refreshToken != null && refreshToken.isNotEmpty)
        ? refreshToken
        : _refreshToken;
    if (nextRefresh != null && nextRefresh.isNotEmpty) {
      _refreshToken = nextRefresh;
    }
    await _persist(_tokenKey, accessToken);
    if (nextRefresh != null && nextRefresh.isNotEmpty) {
      await _persist(_refreshTokenKey, nextRefresh);
    }
  }

  Future<void> saveToken(String token) => saveTokens(accessToken: token);

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    await _erase(_tokenKey);
    await _erase(_refreshTokenKey);
    // Also drop any plaintext copy a pre-§20 build may have left behind.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not clear legacy token keys: $e');
    }
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

  /// GET without unwrapping the `data` envelope, so paginated callers can read
  /// `meta.hasMore` instead of silently seeing only the first page.
  Future<Map<String, dynamic>> getEnvelope(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    var res = await _dispatch('GET', endpoint, queryParams: queryParams);
    if (res.statusCode == 401 &&
        !endpoint.startsWith('/auth/') &&
        _refreshToken != null) {
      if (await _refreshAccessToken()) {
        res = await _dispatch('GET', endpoint, queryParams: queryParams);
      }
    }

    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = res.body;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    var message = 'Network request failed (${res.statusCode})';
    if (body is Map<String, dynamic> && body['message'] != null) {
      message = body['message'].toString();
    }
    throw ApiException(message, statusCode: res.statusCode, details: body);
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

  /// Uploads a file via multipart POST. Returns the parsed JSON response body
  /// (the `data` envelope is unwrapped like other methods).
  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    String fieldName = 'image',
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);

    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamed = await request.send().timeout(AppConfig.requestTimeout);
    final res = await http.Response.fromStream(streamed);

    // Handle 401 refresh once, like _send does
    if (res.statusCode == 401 &&
        !endpoint.startsWith('/auth/') &&
        _refreshToken != null) {
      if (await _refreshAccessToken()) {
        final retryRequest = http.MultipartRequest('POST', uri);
        retryRequest.headers['Authorization'] = 'Bearer $_token';
        retryRequest.files.add(
          await http.MultipartFile.fromPath(fieldName, filePath),
        );
        final retryStreamed =
            await retryRequest.send().timeout(AppConfig.requestTimeout);
        final retryRes = await http.Response.fromStream(retryStreamed);
        return _handleResponse(retryRes);
      }
    }

    return _handleResponse(res);
  }
}
