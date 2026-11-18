import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Where the map should centre.
///
/// Either a real device fix ([isDeviceLocation] true) or an explicit fallback
/// with a [notice] explaining why no fix was available. Callers that write data
/// (dropping a flag) must check [isDeviceLocation] — the fallback exists so the
/// map still renders, not so the app can pretend it knows where the traveller is.
class MapLocation {
  final LatLng coordinates;
  final bool isDeviceLocation;

  /// Human-readable reason the fallback is in use; null for a real fix.
  final String? notice;

  /// True while the GPS lookup is still in flight. Consumers may query from
  /// [coordinates] now and re-run when the real fix lands.
  final bool isResolving;

  /// True when [coordinates] are a cached device position rather than a fresh
  /// fix: good enough to read from, not good enough to write a flag at.
  final bool isStale;

  const MapLocation({
    required this.coordinates,
    required this.isDeviceLocation,
    this.notice,
    this.isResolving = false,
    this.isStale = false,
  });

  /// Kazhakkoottam, Thiruvananthapuram — home base for testing & exploration.
  static const double fallbackLat = 8.5686;
  static const double fallbackLng = 76.8731;

  static const MapLocation fallback = MapLocation(
    coordinates: LatLng(fallbackLat, fallbackLng),
    isDeviceLocation: false,
    notice: 'Location unavailable',
  );

  /// First value emitted so the map can load immediately; replaced by the real
  /// fix (or [fallback]) as soon as the lookup finishes.
  static const MapLocation resolving = MapLocation(
    coordinates: LatLng(fallbackLat, fallbackLng),
    isDeviceLocation: false,
    notice: 'Finding your location',
    isResolving: true,
  );

  /// A cached device position used for the first query. It is a real position,
  /// so it is not labelled as the map centre, but it is stale and will be
  /// replaced by a fresh fix moments later.
  factory MapLocation.lastKnown(LatLng coordinates) => MapLocation(
    coordinates: coordinates,
    isDeviceLocation: true,
    isStale: true,
    isResolving: true,
    notice: 'Using your last known location',
  );

  MapLocation withNotice(String reason) => MapLocation(
    coordinates: coordinates,
    isDeviceLocation: false,
    notice: reason,
  );
}

/// Thin wrapper over `geolocator` that never throws: callers get a [MapLocation]
/// that says whether it is a real fix, so no screen has to invent coordinates.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 12),
  );

  /// The best position we can produce without waiting on GPS: a cached device
  /// fix when the platform has one and permission was already granted, else
  /// null. Never prompts, never throws.
  Future<MapLocation?> lastKnown() async {
    if (kIsWeb) return null;
    try {
      final permission = await Geolocator.checkPermission();
      final granted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!granted) return null;

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return MapLocation.lastKnown(
        LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [LocationService] no cached position: $e');
      }
      return null;
    }
  }

  Future<MapLocation> resolve() async {
    if (kIsWeb) {
      return MapLocation.fallback.withNotice(
        'Location is not available in this build',
      );
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return MapLocation.fallback.withNotice('Location services are off');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return MapLocation.fallback.withNotice('Location permission denied');
      }
      if (permission == LocationPermission.deniedForever) {
        return MapLocation.fallback.withNotice(
          'Location permission blocked in settings',
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: _settings,
        );
      } catch (e) {
        // A cold GPS start can time out; a recent cached fix is still a real
        // device location, unlike the map-centre fallback.
        if (kDebugMode) debugPrint('⚠️ [LocationService] fix failed: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return MapLocation.fallback.withNotice('No GPS fix yet');
      }

      return MapLocation(
        coordinates: LatLng(position.latitude, position.longitude),
        isDeviceLocation: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [LocationService] unavailable: $e');
      return MapLocation.fallback.withNotice('Location unavailable');
    }
  }
}
