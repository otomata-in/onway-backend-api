import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/services/location_service.dart';

/// The map must never wait on GPS or crash when the platform has no location
/// plugin (unit-test hosts, desktop builds), so both are covered here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a cached position reads as a device position but is flagged stale', () {
    final known = MapLocation.lastKnown(const LatLng(9.9312, 76.2673));

    expect(known.isDeviceLocation, isTrue);
    expect(known.isStale, isTrue);
    expect(known.isResolving, isTrue);
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
    expect(MapLocation.resolving.isResolving, isTrue);
    expect(MapLocation.resolving.isDeviceLocation, isFalse);
  });

  test('no platform plugin means no cached position, not an exception', () async {
    final known = await LocationService.instance.lastKnown();
    expect(known, isNull);
  });
}
