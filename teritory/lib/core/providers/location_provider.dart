import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';

/// Single source of truth for "where am I" across the map: the pulsing pin, the
/// explore query centre, Sub-Spots and the services sheet all read this.
///
/// Emits without waiting on GPS:
///  1. a cached device position when one exists (`isStale`), else
///     [MapLocation.resolving] — the labelled fallback centre;
///  2. the fresh device fix (or a labelled failure) once the lookup completes.
///
/// Consumers that `watch` the provider re-run on the second value, so pins load
/// immediately and are replaced with ones from the traveller's actual position.
///
/// `ref.invalidate(mapLocationProvider)` asks for a fresh fix (recenter button,
/// permission granted, backgrounded too long).
final mapLocationProvider = StreamProvider<MapLocation>((ref) async* {
  // Reading the cache is a fast platform call, so it is safe to await — but it
  // is bounded just in case a platform leaves the call hanging, and the first
  // value must never wait on the GPS itself.
  final cached = await LocationService.instance
      .lastKnown()
      .timeout(const Duration(milliseconds: 750), onTimeout: () => null);

  yield cached ?? MapLocation.resolving;
  yield await LocationService.instance.resolve();
});
