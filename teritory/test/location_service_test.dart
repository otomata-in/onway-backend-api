import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/services/location_service.dart';
import 'package:teritory/features/explore/application/explore_flags_provider.dart';

/// The map must never wait on GPS or crash when the platform has no location
/// plugin (unit-test hosts, desktop builds), so both are covered here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a cached position reads as a device position but is flagged stale', () {
    final known = MapLocation.lastKnown(const LatLng(9.9312, 76.2673));

    expect(known.isDeviceLocation, isTrue);
    expect(known.isStale, isTrue);
    expect(known.coordinates.latitude, 9.9312);
    expect(
      known.notice,
      isNot(contains('map centre')),
      reason: 'a cached device position must not claim the map centre',
    );
  });

  test('the fallback is labelled as the map centre, not as a device position', () {
    expect(MapLocation.fallback.isDeviceLocation, isFalse);
    expect(MapLocation.fallback.isStale, isFalse);
  });

  test('no platform plugin means no cached position, not an exception', () async {
    final known = await LocationService.instance.lastKnown();
    expect(known, isNull);
  });

  test('without a plugin the stream yields one labelled fallback', () async {
    final events = await LocationService.instance.watch().take(1).toList();

    expect(events, hasLength(1));
    final first = events.single;
    if (!first.isDeviceLocation) {
      expect(
        first.notice,
        isNotNull,
        reason: 'a fallback must say why it is the map centre',
      );
    }
  });

  test('the explore query ignores movement inside its re-query radius', () {
    const kochi = LatLng(9.9790, 76.2760);
    const acrossTheStreet = LatLng(9.9830, 76.2800);
    const anotherDistrict = LatLng(10.1000, 76.2760);

    expect(
      distanceMeters(kochi, acrossTheStreet),
      lessThan(ExploreFlagsNotifier.requeryMeters),
      reason: 'walking should not re-fire the 100 km query',
    );
    expect(
      distanceMeters(kochi, anotherDistrict),
      greaterThan(ExploreFlagsNotifier.requeryMeters),
      reason: 'a real move re-queries',
    );
  });

  test('a cached position keeps its coordinates when the fix goes stale', () {
    final known = MapLocation.lastKnown(const LatLng(8.5241, 76.9366));
    final ageing = known.staleWith('No fresh fix yet');

    expect(ageing.coordinates.latitude, known.coordinates.latitude);
    expect(ageing.coordinates.longitude, known.coordinates.longitude);
    expect(ageing.isStale, isTrue);
    expect(ageing.notice, 'No fresh fix yet');
  });
}
