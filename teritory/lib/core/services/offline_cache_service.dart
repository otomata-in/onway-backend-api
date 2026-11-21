import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local disk cache for offline viewing of saved expeditions,
/// wishlist spots and the active trip when cell service drops in remote areas.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  static const String _savedPlansKey = 'teritory_cached_saved_plans';
  static const String _savedFlagsKey = 'teritory_cached_saved_flags';
  static const String _tripsHubKey = 'teritory_cached_trips_hub';
  static const String _activeTripPrefix = 'teritory_cached_active_trip_';

  Future<void> _writeJson(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (_) {}
  }

  Future<dynamic> _readJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null) return jsonDecode(raw);
    } catch (_) {}
    return null;
  }

  Future<void> cacheSavedPlans(List<dynamic> rawPlans) {
    return _writeJson(_savedPlansKey, rawPlans);
  }

  Future<List<Map<String, dynamic>>?> getCachedSavedPlans() async {
    final decoded = await _readJson(_savedPlansKey);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return null;
  }

  Future<void> cacheSavedFlags(List<dynamic> rawFlags) {
    return _writeJson(_savedFlagsKey, rawFlags);
  }

  Future<List<Map<String, dynamic>>?> getCachedSavedFlags() async {
    final decoded = await _readJson(_savedFlagsKey);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return null;
  }

  /// The whole `GET /trips/hub` payload, including the active trip summary.
  Future<void> cacheTripsHub(Map<String, dynamic> rawHub) {
    return _writeJson(_tripsHubKey, rawHub);
  }

  Future<Map<String, dynamic>?> getCachedTripsHub() async {
    final decoded = await _readJson(_tripsHubKey);
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return null;
  }

  Future<void> cacheActiveTrip(String tripId, Map<String, dynamic> rawTrip) {
    return _writeJson('$_activeTripPrefix$tripId', rawTrip);
  }

  Future<Map<String, dynamic>?> getCachedActiveTrip(String tripId) async {
    final decoded = await _readJson('$_activeTripPrefix$tripId');
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return null;
  }
}
