import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/providers/location_provider.dart';
import 'package:teritory/core/services/location_service.dart';
import 'package:teritory/features/explore/application/explore_flags_provider.dart';

class _MockExploreDataSource implements ExploreDataSource {
  final List<ApiFlag> returnedFlags;
  final List<LatLng> queriedLocations = [];

  _MockExploreDataSource({
    this.returnedFlags = const [],
  });

  @override
  Future<List<ApiFlag>> fetchExploreFlags({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    queriedLocations.add(LatLng(latitude, longitude));
    return returnedFlags;
  }

  @override
  Future<Set<String>> fetchFriendIds() async => const <String>{};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testFlag = ApiFlag(
    id: 'flag-paris-1',
    userId: 'user-paris',
    placeName: 'Eiffel Tower Viewpoint',
    city: 'Paris',
    country: 'France',
    countryCode: 'FR',
    continent: 'Europe',
    latitude: 48.8584,
    longitude: 2.2945,
    isMajorFlag: true,
    category: 'Monument',
    notes: 'Iconic spot',
    photoUrl: '',
    kudos: 15,
    distanceKm: 0.0,
    authorName: 'Pierre Explorer',
    authorHandle: '@pierre',
    authorAvatar: '',
    createdAt: DateTime.now(),
  );

  test('customExploreTargetProvider forces query at custom location', () async {
    final positions = StreamController<MapLocation>();

    final mockSource = _MockExploreDataSource(returnedFlags: [testFlag]);
    final container = ProviderContainer(
      overrides: [
        mapLocationProvider.overrideWith((ref) => positions.stream),
        exploreDataSourceProvider.overrideWithValue(mockSource),
      ],
    );

    container.listen(exploreFlagsProvider, (_, _) {});

    addTearDown(() async {
      container.dispose();
      await positions.close();
    });

    final initial = await container.read(exploreFlagsProvider.future);
    expect(initial.flags, contains(testFlag));
    // Initial query uses fallback before stream emission
    expect(
      mockSource.queriedLocations.first.latitude,
      closeTo(MapLocation.fallback.coordinates.latitude, 0.01),
    );

    // Now user searches for Paris and selects it
    const parisCoords = LatLng(48.8584, 2.2945);
    container.read(customExploreTargetProvider.notifier).state =
        const ExploreTarget(
      coordinates: parisCoords,
      label: 'Paris, France',
    );

    await pumpEventQueue();
    final updated = await container.read(exploreFlagsProvider.future);
    expect(updated.flags, isNotEmpty);
    expect(mockSource.queriedLocations.last.latitude, closeTo(48.8584, 0.01));
  });

  test('customExploreTarget with focusedFlag guarantees flag is included',
      () async {
    final positions = StreamController<MapLocation>();

    final mockSource = _MockExploreDataSource(returnedFlags: []);
    final container = ProviderContainer(
      overrides: [
        mapLocationProvider.overrideWith((ref) => positions.stream),
        exploreDataSourceProvider.overrideWithValue(mockSource),
      ],
    );

    container.listen(exploreFlagsProvider, (_, _) {});

    addTearDown(() async {
      container.dispose();
      await positions.close();
    });

    // Target with focused flag
    container.read(customExploreTargetProvider.notifier).state = ExploreTarget(
      coordinates: testFlag.coordinates,
      label: testFlag.placeName,
      focusedFlag: testFlag,
    );

    final result = await container.read(exploreFlagsProvider.future);
    expect(result.flags, hasLength(1));
    expect(result.flags.first.id, testFlag.id);
    expect(result.flags.first.placeName, testFlag.placeName);
  });
}
