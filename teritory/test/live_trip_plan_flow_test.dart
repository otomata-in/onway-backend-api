import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Phase 7.5: the Community Plans tab creates a plan against its community, and
/// completing that trip returns the traveler's real badge.
///
/// Run against `teritory-api` on :4000:
/// `flutter test test/live_trip_plan_flow_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  test('community plan creation and completion badge', () async {
    await repo.loginWithOtp('+919876543210', '12345');

    final clans = await repo.fetchClansLive();
    expect(clans, isNotEmpty);
    final clan = await repo.fetchClanDetail(clans.first.id);
    expect(clan.communities, isNotEmpty,
        reason: 'the plans tab needs a community to plan into');
    final communityId = clan.communities.first.id;

    final planName =
        'Community plan smoke ${DateTime.now().millisecondsSinceEpoch}';
    final plan = await repo.createPlan(
      name: planName,
      originName: 'Kochi',
      destinationName: 'Munnar',
      description: 'created by live_trip_plan_flow_test (safe to delete)',
      communityId: communityId,
      totalDistanceKm: 130,
      estimatedDays: 1,
      waypoints: const [
        {
          'orderIndex': 0,
          'placeName': 'Kochi',
          'latitude': 9.9312,
          'longitude': 76.2673,
          'category': 'origin',
          'distanceFromPrevKm': 0,
        },
        {
          'orderIndex': 1,
          'placeName': 'Munnar',
          'latitude': 10.0889,
          'longitude': 77.0595,
          'category': 'destination',
          'distanceFromPrevKm': 130,
        },
      ],
    );

    // The tab is refreshed after the planner returns; that read must see it.
    final communityPlans = await repo.fetchCommunityTripPlans(communityId);
    expect(communityPlans.any((candidate) => candidate.id == plan.id), isTrue,
        reason: 'the created plan belongs to the community');

    final trip = await repo.startTrip(plan.id);
    expect(trip.id, isNotEmpty);

    final badge = await repo.completeTrip(trip.id);
    expect(const ['FULL', 'PARTIAL', 'NONE'], contains(badge),
        reason: 'badge comes from the complete-trip response');

    // ignore: avoid_print
    print('plans: community=$communityId plan=${plan.id} '
        'trip=${trip.id} badge=$badge');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
