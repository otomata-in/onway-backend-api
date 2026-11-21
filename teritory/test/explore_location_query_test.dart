import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/providers/location_provider.dart';
import 'package:teritory/core/services/location_service.dart';
import 'package:teritory/features/explore/application/explore_flags_provider.dart';

/// Offline coverage for the location → explore wiring: no GPS plugin, no HTTP.
/// Location is faked by overriding [mapLocationProvider]; the backend by
/// overriding [exploreDataSourceProvider].
void main() {
  late StreamController<MapLocation> positions;
  late _RecordingDataSource dataSource;
  late ProviderContainer container;

  setUp(() {
    positions = StreamController<MapLocation>();
    dataSource = _RecordingDataSource();
    container = ProviderContainer(
      overrides: [
        mapLocationProvider.overrideWith((ref) => positions.stream),
        exploreDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
    // Keep the notifier alive for the whole test.
    container.listen(exploreFlagsProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await positions.close();
  });

  test('queries the map centre immediately, before any position arrives', () async {
    await container.read(exploreFlagsProvider.future);

    expect(dataSource.queries, hasLength(1));
    expect(
      dataSource.queries.single.latitude,
      closeTo(MapLocation.fallback.coordinates.latitude, 1e-9),
      reason: 'the first load must not wait for a GPS fix',
    );
    expect(
      dataSource.queries.single.longitude,
      closeTo(MapLocation.fallback.coordinates.longitude, 1e-9),
    );
  });

  test('a first cached position replaces the fallback with one query', () async {
    await container.read(exploreFlagsProvider.future);
    expect(dataSource.queries, hasLength(1));

    positions.add(MapLocation.lastKnown(const LatLng(9.9312, 76.2673)));
    await pumpEventQueue();

    expect(
      dataSource.queries,
      hasLength(2),
      reason: 'the cached position is far from the fallback centre',
    );
    expect(dataSource.queries.last.latitude, closeTo(9.9312, 1e-9));
    expect(dataSource.queries.last.longitude, closeTo(76.2673, 1e-9));
  });

  test('the fresh fix costs at most one extra query, never one per update', () async {
    await container.read(exploreFlagsProvider.future);
    positions.add(MapLocation.lastKnown(const LatLng(9.9312, 76.2673)));
    await pumpEventQueue();

    final afterCached = dataSource.queries.length;
    expect(afterCached, 2);

    // The GPS fix lands next to the cached position: same neighbourhood, so the
    // pins are kept and nothing is re-queried.
    positions.add(
      const MapLocation(
        coordinates: LatLng(9.9318, 76.2679),
        isDeviceLocation: true,
      ),
    );
    await pumpEventQueue();
    expect(dataSource.queries, hasLength(afterCached));

    // A real move re-queries exactly once, and the update after it does not.
    positions.add(
      const MapLocation(
        coordinates: LatLng(10.1000, 76.2760),
        isDeviceLocation: true,
      ),
    );
    await pumpEventQueue();
    expect(dataSource.queries, hasLength(afterCached + 1));
    expect(dataSource.queries.last.latitude, closeTo(10.1000, 1e-9));

    positions.add(
      const MapLocation(
        coordinates: LatLng(10.1005, 76.2765),
        isDeviceLocation: true,
      ),
    );
    await pumpEventQueue();
    expect(
      dataSource.queries,
      hasLength(afterCached + 1),
      reason: 'small movements must not re-fire the query',
    );
  });

  test('a re-query keeps the old pins and is not duplicated mid-flight', () async {
    await container.read(exploreFlagsProvider.future);
    expect(dataSource.queries, hasLength(1));

    // Make the next query hang, so the handoff can be observed.
    final gate = Completer<void>();
    dataSource.hold = gate;

    positions.add(MapLocation.lastKnown(const LatLng(9.9312, 76.2673)));
    await pumpEventQueue();
    expect(dataSource.queries, hasLength(2));

    final duringHandoff = container.read(exploreFlagsProvider);
    expect(duringHandoff.isLoading, isTrue);
    expect(
      duringHandoff.valueOrNull,
      isNotNull,
      reason: 'pins stay on screen while the new area loads (no flicker)',
    );

    // A fix next to the cached position arrives mid-query: it must reuse the
    // pending request instead of firing a third one.
    positions.add(
      const MapLocation(
        coordinates: LatLng(9.9318, 76.2679),
        isDeviceLocation: true,
      ),
    );
    await pumpEventQueue();
    expect(dataSource.queries, hasLength(2));

    gate.complete();
    await pumpEventQueue();
    expect(container.read(exploreFlagsProvider).hasValue, isTrue);
  });
}

class _Query {
  final double latitude;
  final double longitude;

  const _Query(this.latitude, this.longitude);
}

class _RecordingDataSource implements ExploreDataSource {
  final List<_Query> queries = [];

  /// When set, queries stay in flight until it completes, so a test can look at
  /// the map while a re-query is running.
  Completer<void>? hold;

  @override
  Future<List<ApiFlag>> fetchExploreFlags({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    queries.add(_Query(latitude, longitude));
    final gate = hold;
    if (gate != null) await gate.future;
    return const <ApiFlag>[];
  }

  @override
  Future<Set<String>> fetchFriendIds() async => <String>{};
}
