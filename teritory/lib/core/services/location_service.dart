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

  /// True when [coordinates] are a cached device position rather than a fresh
  /// fix: good enough to read from, not good enough to write a flag at.
  final bool isStale;

  const MapLocation({
    required this.coordinates,
    required this.isDeviceLocation,
    this.notice,
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


  /// A cached device position used for the first query. It is a real position,
  /// so it is not labelled as the map centre, but it is stale and will be
  /// replaced by a fresh fix moments later.
  factory MapLocation.lastKnown(LatLng coordinates) => MapLocation(
    coordinates: coordinates,
    isDeviceLocation: true,
    isStale: true,
    notice: 'Using your last known location',
  );

  MapLocation withNotice(String reason) => MapLocation(
    coordinates: coordinates,
    isDeviceLocation: false,
    notice: reason,
  );

  /// The same real (but old) position with a different explanation, used when a
  /// cached fix is all we have and the GPS stays silent.
  MapLocation staleWith(String reason) => MapLocation(
    coordinates: coordinates,
    isDeviceLocation: true,
    isStale: true,
    notice: reason,
  );
}

/// Thin wrapper over `geolocator` that never throws: callers get a [MapLocation]
/// that says whether it is a real fix, so no screen has to invent coordinates.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Fixes arrive only after the traveller has actually moved this far, so a
  /// stationary phone is not woken up by GPS noise.
  static const int distanceFilterMeters = 50;

  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: distanceFilterMeters,
  );

  /// How long a live stream may stay silent before the cached position is
  /// labelled as ageing instead of "updating…".
  static const Duration _silenceNotice = Duration(seconds: 45);

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

  /// Continuous fixes for as long as this stream is listened to.
  ///
  /// - The cached position goes out first when there is one (marked
  ///   [MapLocation.isStale]). Nothing else is emitted until there is something
  ///   true to say: the map queries its default centre meanwhile.
  /// - Then every device fix as the traveller moves, at most once per
  ///   [distanceFilterMeters].
  /// - When location cannot be provided (no plugin, service off, permission
  ///   denied/blocked) it emits one labelled value and closes, so the honest
  ///   banner stays and nothing retries in the background. A cached position is
  ///   kept rather than snapping the map to Kochi, and is labelled with the
  ///   reason it cannot be refreshed.
  Stream<MapLocation> watch() async* {
    final cached = await lastKnown().timeout(
      const Duration(milliseconds: 750),
      onTimeout: () => null,
    );

    // Whatever we already know goes out before any GPS work starts.
    if (cached != null) yield cached;

    if (kIsWeb) {
      yield MapLocation.fallback.withNotice(
        'Location is not available in this build',
      );
      return;
    }

    // The newest position actually shown, so silence or failure keeps the
    // traveller's latest place instead of jumping back to the cached one.
    MapLocation? latest = cached;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        yield _cannotLocate(latest, 'Location services are off');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        yield _cannotLocate(latest, 'Location permission denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        yield _cannotLocate(latest, 'Location permission blocked in settings');
        return;
      }

      final fixes = Geolocator.getPositionStream(
        locationSettings: _streamSettings,
      ).map(
        (position) => MapLocation(
          coordinates: LatLng(position.latitude, position.longitude),
          isDeviceLocation: true,
        ),
      );

      // Indoors the stream can stay silent indefinitely; without this the banner
      // would keep describing a position that is no longer being refreshed.
      final monitored = latest == null
          ? fixes
          : fixes.timeout(_silenceNotice, onTimeout: (sink) {
              final last = latest;
              if (last != null) sink.add(last.staleWith('No fresh fix yet'));
            });

      await for (final fix in monitored) {
        latest = fix;
        yield fix;
      }

      // The platform closed the stream: keep the last fix, labelled honestly.
      final shown = latest;
      if (shown != null) yield shown.staleWith('Location updates stopped');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [LocationService] stream failed: $e');
      final shown = latest;
      yield shown != null
          ? shown.staleWith('Location updates stopped')
          : MapLocation.fallback.withNotice('Location unavailable');
    }
  }

  /// A cached position with the reason it cannot be refreshed, or the labelled
  /// map centre when there is nothing cached.
  MapLocation _cannotLocate(MapLocation? cached, String reason) =>
      cached?.staleWith(reason) ?? MapLocation.fallback.withNotice(reason);
}
