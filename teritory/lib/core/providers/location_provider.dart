import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';

/// Single source of truth for "where am I" across the map: the pulsing pin, the
/// explore query centre, Sub-Spots and the services sheet all read this.
///
/// Emits the cached position first when there is one, then every device fix from
/// the position stream (at most once per [LocationService.distanceFilterMeters]),
/// or one labelled fallback if location cannot be provided at all. Until the
/// first value arrives the map shows its own default centre and a loading
/// banner — it never waits on a GPS fix to draw something.
///
/// Consumers react to each value, so the pin follows while the app is open. The
/// map screen moves its camera once per new position, and the explore query only
/// re-runs when the centre has moved far enough to matter (see
/// `ExploreFlagsNotifier`).
///
/// `ref.invalidate(mapLocationProvider)` restarts the stream: a fresh cached
/// read, a fresh permission check and a fresh subscription.
final mapLocationProvider = StreamProvider<MapLocation>((ref) {
  return LocationService.instance.watch();
});
