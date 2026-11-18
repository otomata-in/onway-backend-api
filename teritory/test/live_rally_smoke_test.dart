import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Drives the real client against a local `teritory-api` on :4000:
/// create → appear nearby → join → 500 m arrival check → complete.
///
/// Run with the API up: `flutter test test/live_rally_smoke_test.dart`.
/// It creates a rally (and, on completion, the collective flag + stamps the
/// server awards), so it is a dev-database smoke test, not a unit test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test installs a fake HttpClient that answers 400 to everything;
  // this test intentionally talks to the local API.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;
  const lat = 9.9312;
  const lng = 76.2673;

  test('rally lifecycle runs against the live API', () async {
    final organizer = await repo.loginWithOtp('+919876543210', '12345');
    expect(organizer, isNotNull);

    final created = await repo.createRally(
      name: 'Smoke test rally (safe to ignore)',
      placeName: 'Kochi Smoke Point',
      latitude: lat,
      longitude: lng,
      description: 'Created by live_rally_smoke_test.dart',
      minParticipants: 2,
      expiresHours: 2,
    );
    expect(created.id, isNotEmpty);
    expect(created.minParticipants, 2);

    final nearby = await repo.fetchNearbyRallies(latitude: lat, longitude: lng);
    final mine = nearby.where((rally) => rally.id == created.id);
    expect(mine, hasLength(1));
    expect(mine.first.participantIds, contains(organizer.id));

    final organizerDetail = await repo.fetchRallyDetail(created.id,
        latitude: lat, longitude: lng);
    expect(organizerDetail.roster, hasLength(1));

    // Organizer check-in at the rally point passes the server's 500 m rule.
    final organizerArrival = await repo.markRallyArrival(
      created.id,
      latitude: lat,
      longitude: lng,
    );
    expect(organizerArrival.arrived, isTrue,
        reason: organizerArrival.message);

    // A second traveler joins and must fail the check from 6 km away.
    final friend = await repo.loginWithOtp('+919876543211', '12345');
    expect(friend, isNotNull);
    await repo.joinRally(created.id);

    final farArrival = await repo.markRallyArrival(
      created.id,
      latitude: lat + 0.05,
      longitude: lng,
    );
    expect(farArrival.arrived, isFalse);
    expect(farArrival.distanceM, greaterThan(500));

    final friendArrival = await repo.markRallyArrival(
      created.id,
      latitude: lat,
      longitude: lng,
    );
    expect(friendArrival.arrived, isTrue, reason: friendArrival.message);

    final joinedDetail = await repo.fetchRallyDetail(created.id,
        latitude: lat, longitude: lng);
    expect(joinedDetail.roster, hasLength(2));
    expect(joinedDetail.arrivedCount, 2);
    expect(joinedDetail.rally.isParticipant(friend.id), isTrue);

    // Only the organizer may complete, and now there are enough arrivals.
    await repo.loginWithOtp('+919876543210', '12345');
    await repo.completeRally(created.id);

    final completed = await repo.fetchRallyDetail(created.id,
        latitude: lat, longitude: lng);
    expect(completed.rally.status.name, 'completed');

    final afterCompletion =
        await repo.fetchNearbyRallies(latitude: lat, longitude: lng);
    expect(afterCompletion.any((rally) => rally.id == created.id), isFalse,
        reason: 'completed rallies leave the nearby gathering list');

    // ignore: avoid_print
    print('rally=${created.id} roster=${joinedDetail.roster.length} '
        'arrived=${joinedDetail.arrivedCount} '
        'far=${farArrival.distanceM}m status=${completed.rally.status.name}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
