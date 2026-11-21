import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local disk cache for offline viewing of saved expeditions and
/// wishlist spots when cell service drops in remote areas.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  static const String _savedPlansKey = 'teritory_cached_saved_plans';
  static const String _savedFlagsKey = 'teritory_cached_saved_flags';

  Future<void> cacheSavedPlans(List<dynamic> rawPlans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedPlansKey, jsonEncode(rawPlans));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> getCachedSavedPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedPlansKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheSavedFlags(List<dynamic> rawFlags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedFlagsKey, jsonEncode(rawFlags));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> getCachedSavedFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedFlagsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return null;
  }
}
