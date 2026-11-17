import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/socket_service.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Exercises every migrated page flow against a running `teritory-api` on
/// http://localhost:4000. Contract failures surface here as parse errors or
/// empty payloads, before they reach a widget.
///
/// Run: `flutter test test/live_flows_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test installs a fake HttpClient that answers 400 to everything.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  setUpAll(() async {
    final user = await repo.loginWithOtp('+919876543210', '12345');
    expect(user, isNotNull, reason: 'OTP login must sign in the seed traveler');
  });

  test('Explore: flags, detail, user footprint', () async {
    final flags = await repo.fetchExploreFlags(
      latitude: 9.97,
      longitude: 76.28,
      radiusKm: 100,
    );
    expect(flags, isNotEmpty, reason: 'seed flags within 100 km of Kochi');
    for (final flag in flags) {
      expect(flag.id, isNotEmpty);
      expect(flag.placeName, isNotEmpty);
      expect(flag.userId, isNotEmpty);
    }

    final detail = await repo.fetchFlagDetail(flags.first.id);
    expect(detail.flag.id, flags.first.id);
    expect(detail.comments, isA<List>());

    final mine = await repo.fetchMyProfileLive();
    final footprint = await repo.fetchUserFlags(mine.id);
    expect(footprint, isA<List>());
    expect(footprint.every((f) => f.userId == mine.id), isTrue);

    // ignore: avoid_print
    print('explore: ${flags.length} flags, footprint ${footprint.length}, '
        'detail comments ${detail.comments.length}');
  });

  test('Clans: list, membership, detail, communities', () async {
    final clans = await repo.fetchClansLive();
    expect(clans, isNotEmpty, reason: 'seed clans');

    final myIds = await repo.fetchMyClanIds();
    final detail = await repo.fetchClanDetail(clans.first.id);
    expect(detail.clan.id, clans.first.id);
    expect(detail.members, isNotEmpty);
    expect(detail.communities, isA<List>());

    // ignore: avoid_print
    print('clans: ${clans.length} total, my ${myIds.length}, '
        'first "${clans.first.name}" members ${detail.members.length}, '
        'communities ${detail.communities.length}');
  });

  test('Communities: detail, members, feed, plans, chat send', () async {
    final communities = await repo.fetchCommunitiesLive();
    expect(communities, isNotEmpty, reason: 'seed communities');
    final community = communities.first;

    final detail = await repo.fetchCommunityDetail(community.id);
    expect(detail.id, community.id);

    final members = await repo.fetchCommunityMembersLive(community.id);
    expect(members, isNotEmpty);
    expect(members.first.userName, isNotEmpty);

    final feed = await repo.fetchCommunityFeed(community.id);
    final plans = await repo.fetchCommunityTripPlans(community.id);
    expect(plans, isNotEmpty, reason: 'seed community trip plan');
    expect(plans.first.name, isNotEmpty);
    expect(plans.first.waypoints, isNotEmpty);

    final history = await repo.fetchCommunityMessagesLive(community.id);
    final sent = await repo.sendCommunityMessageLive(
      community.id,
      'integration smoke test ${DateTime.now().millisecondsSinceEpoch}',
    );
    expect(sent.text, contains('integration smoke test'));
    expect(sent.id, isNotEmpty);

    final after = await repo.fetchCommunityMessagesLive(community.id);
    expect(after.length, greaterThanOrEqualTo(history.length + 1));

    // ignore: avoid_print
    print('community "${community.name}": members ${members.length}, '
        'feed ${feed.length}, plans ${plans.length}, '
        'messages ${history.length}->${after.length}');
  });

  test('Trips: hub, plan detail, active trip, history, saved', () async {
    final hub = await repo.fetchTripsHub();
    expect(hub.proposedPlans, isNotEmpty, reason: 'seed proposed plans');

    final plan = await repo.fetchPlanDetail(hub.proposedPlans.first.id);
    expect(plan.plan.id, hub.proposedPlans.first.id);
    expect(plan.plan.waypoints, isNotEmpty);

    final saved = await repo.fetchSavedPlans();
    final savedIds = await repo.fetchSavedPlanIds();
    expect(saved.length, savedIds.length);

    final history = await repo.fetchTripHistory();

    final active = hub.activeTrip;
    expect(active, isNotNull, reason: 'seed active trip');
    final tracker = await repo.fetchActiveTripDetail(
      active!.id,
      userId: null,
    );
    expect(tracker.waypoints, isNotEmpty);
    expect(tracker.trip.id, active.id);

    // ignore: avoid_print
    print('trips: proposed ${hub.proposedPlans.length}, active '
        '"${tracker.trip.tripName}" status ${tracker.trip.status.name}, '
        'waypoints ${tracker.waypoints.length}, validated '
        '${tracker.validatedWaypointIds.length}, saved ${saved.length}, '
        'history ${history.length}');
  });

  test('Rankings: board, week window, my rank', () async {
    final board = await repo.fetchLeaderboard();
    expect(board, isNotEmpty);
    expect(board.first.compositeScore, greaterThan(0));

    final week = await repo.fetchLeaderboard();
    expect(week.first.rank, 1);

    final me = await repo.fetchMyRank();
    expect(me.globalRank, greaterThan(0));
    expect(me.score, greaterThan(0));

    // ignore: avoid_print
    print('rankings: ${board.length} rows, leader ${board.first.userId} '
        '(${board.first.compositeScore}), me rank ${me.globalRank} '
        'score ${me.score}');
  });

  test('Profile & social: me, friends, requests, search, profiles', () async {
    final me = await repo.fetchMyProfileLive();
    expect(me.id, isNotEmpty);
    expect(me.displayName, isNotEmpty);

    final friends = await repo.fetchFriends();
    expect(friends, isNotEmpty, reason: 'seed friendships');
    expect(friends.first.user.displayName, isNotEmpty);
    expect(friends.first.user.id, isNotEmpty);
    expect(friends.first.relationshipId, isNotEmpty);

    final requests = await repo.fetchFriendRequests();
    expect(requests.incoming, isA<List>());
    expect(requests.outgoing, isA<List>());

    final found = await repo.searchUsers('priya');
    expect(found, isNotEmpty);

    final other = await repo.fetchUserProfile(friends.first.user.id);
    expect(other.id, friends.first.user.id);
    expect(other.displayName, isNotEmpty);

    // ignore: avoid_print
    print('social: me ${me.handle}, friends ${friends.length} '
        '(${friends.map((f) => f.user.displayName).join(', ')}), '
        'requests in ${requests.incoming.length}/out ${requests.outgoing.length}, '
        'search ${found.length}');
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('Planner -> community plan, feed, save, vote, 15 km rule', () async {
    final communities = await repo.fetchCommunitiesLive();
    final community = communities.first;
    final plansBefore = await repo.fetchCommunityTripPlans(community.id);

    final plan = await repo.createPlan(
      name: 'Smoke test plan (safe to delete)',
      originName: 'Kochi Marine Drive',
      destinationName: 'Top Station Munnar',
      description: 'Created by the live integration smoke test.',
      communityId: community.id,
      totalDistanceKm: 142,
      estimatedDays: 2,
      waypoints: [
        {
          'orderIndex': 0,
          'placeName': 'Kochi Marine Drive',
          'latitude': 9.979,
          'longitude': 76.276,
          'category': 'Coastal',
        },
        {
          'orderIndex': 1,
          'placeName': 'Top Station Munnar',
          'latitude': 10.125,
          'longitude': 77.245,
          'category': 'Peak View',
          'distanceFromPrevKm': 142.0,
        },
      ],
    );
    expect(plan.id, isNotEmpty);
    expect(plan.waypoints, hasLength(2));
    expect(plan.communityName, community.name,
        reason: 'plan payload must tell the client which community it belongs to');

    final plansAfter = await repo.fetchCommunityTripPlans(community.id);
    expect(plansAfter.length, plansBefore.length + 1);
    expect(plansAfter.any((p) => p.id == plan.id && p.communityName == community.name),
        isTrue);

    final feed = await repo.fetchCommunityFeed(community.id);
    expect(feed, isNotEmpty,
        reason: 'a proposed community plan should appear in the feed');
    expect(
        feed.any((a) =>
            a.title.toLowerCase().contains('trip plan') ||
            a.description.contains(plan.name)),
        isTrue);

    expect(await repo.togglePlanSaved(plan.id), isTrue);
    expect(await repo.fetchSavedPlanIds(), contains(plan.id));
    final savedPlan =
        (await repo.fetchSavedPlans()).firstWhere((p) => p.id == plan.id);
    expect(savedPlan.communityName, community.name,
        reason: 'saved community plans must not be labelled "Personal"');
    expect(await repo.togglePlanSaved(plan.id), isFalse);
    expect(await repo.fetchSavedPlanIds(), isNot(contains(plan.id)));

    expect(await repo.toggleTripPlanVote(plan.id), isTrue);
    expect(await repo.toggleTripPlanVote(plan.id), isFalse);

    final hub = await repo.fetchTripsHub();
    final active = hub.activeTrip!;
    final tracker = await repo.fetchActiveTripDetail(active.id);
    final waypoint = tracker.waypoints.first;
    final far = await repo.validateWaypointAt(
      tripId: active.id,
      waypointId: waypoint.id,
      latitude: 0,
      longitude: 0,
    );
    expect(far.isValid, isFalse, reason: '0,0 is thousands of km away');
    expect(far.distanceM, greaterThan(15000));
    expect(far.message, isNotEmpty);

    // ignore: avoid_print
    print('mutations: plan "${plan.name}" in ${community.name}, '
        'feed ${feed.length}, saved toggle ok, vote toggle ok, '
        'far check ${far.distanceM.round()}m -> ${far.isValid}');
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('Communities chat: socket delivers a REST-posted message', () async {
    final communities = await repo.fetchCommunitiesLive();
    final community = communities.first;

    SocketService.instance.connect();
    final connected = await _waitFor(
      () => SocketService.instance.isConnected,
      timeout: const Duration(seconds: 10),
    );
    expect(connected, isTrue, reason: 'Socket.IO must accept the auth token');
    SocketService.instance.joinCommunity(community.id);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final text = 'socket smoke ${DateTime.now().millisecondsSinceEpoch}';
    final received = SocketService.instance.messageStream
        .firstWhere((message) => message.text == text)
        .timeout(const Duration(seconds: 10));

    await repo.sendCommunityMessageLive(community.id, text);
    final message = await received;
    expect(message.text, text);
    expect(message.userName, isNotEmpty);

    SocketService.instance.disconnect();

    // ignore: avoid_print
    print('socket: new_message received from ${message.userName} '
        'in ${community.name}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<bool> _waitFor(
  bool Function() predicate, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  return predicate();
}
