import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences, loaded once before `runApp` so providers can read
/// them synchronously (no default flash, no async work inside `build`).
class PreferenceStore {
  PreferenceStore._();
  static final PreferenceStore instance = PreferenceStore._();

  static const String _mapDarkKey = 'teritory_map_dark';
  static const String _notificationsKey = 'teritory_notification_prefs';

  static const Map<String, bool> defaultNotifications = {
    'friendRequests': true,
    'clanActivity': true,
    'tripUpdates': true,
  };

  /// Midnight Oceanic by default, matching the original Explore design.
  bool mapDark = true;
  Map<String, bool> notifications = Map<String, bool>.of(defaultNotifications);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mapDark = prefs.getBool(_mapDarkKey) ?? mapDark;
      notifications = _decodeNotifications(prefs.getString(_notificationsKey));
    } catch (_) {
      // Unreadable prefs: keep the defaults rather than block startup.
    }
  }

  Map<String, bool> _decodeNotifications(String? raw) {
    if (raw == null) return Map<String, bool>.of(defaultNotifications);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return Map<String, bool>.of(defaultNotifications);
      }
      return {
        for (final entry in defaultNotifications.entries)
          entry.key: decoded[entry.key] is bool
              ? decoded[entry.key] as bool
              : entry.value,
      };
    } catch (_) {
      return Map<String, bool>.of(defaultNotifications);
    }
  }

  Future<void> setMapDark(bool dark) async {
    mapDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mapDarkKey, dark);
  }

  Future<void> setNotification(String key, bool enabled) async {
    if (!defaultNotifications.containsKey(key)) return;
    notifications = {...notifications, key: enabled};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }
}

/// Explore's map theme: `true` = Midnight Oceanic, `false` = Daylight White.
class MapThemeNotifier extends Notifier<bool> {
  @override
  bool build() => PreferenceStore.instance.mapDark;

  Future<void> setDark(bool dark) async {
    state = dark;
    await PreferenceStore.instance.setMapDark(dark);
  }
}

final mapThemeProvider =
    NotifierProvider<MapThemeNotifier, bool>(MapThemeNotifier.new);

/// Notification switches. These stay device-local until the backend exposes a
/// preferences endpoint; the settings sheet says so instead of implying sync.
class NotificationPreferencesNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => PreferenceStore.instance.notifications;

  Future<void> setEnabled(String key, bool enabled) async {
    state = {...state, key: enabled};
    await PreferenceStore.instance.setNotification(key, enabled);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, Map<String, bool>>(
  NotificationPreferencesNotifier.new,
);
