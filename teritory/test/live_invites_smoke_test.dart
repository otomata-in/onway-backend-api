import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/models/notification_models.dart';
import 'package:teritory/core/services/api_service.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Phase 7.3: the shared friend picker's payload — `POST /users/invites` for a
/// CLAN, a TRIP and a RALLY — must reach the invitee's inbox with a notification
/// type and a deep link the app can route.
///
/// Run against `teritory-api` on :4000:
/// `flutter test test/live_invites_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  Future<List<NotificationItem>> inboxOf(String phone) async {
    await repo.loginWithOtp(phone, '12345');
    return repo.fetchNotifications();
  }

  test('clan, trip and rally invites reach the invitee', () async {
    await repo.loginWithOtp('+919876543210', '12345');

    final friends = await repo.fetchFriends();
    expect(friends, isNotEmpty,
        reason: 'the picker lists GET /users/friends');
    final invitee = friends.first.user.id;

    final clans = await repo.fetchClansLive();
    expect(clans, isNotEmpty);
    final clanId = clans.first.id;

    final hub = await repo.fetchTripsHub();
    final plans = [...hub.proposedPlans, ...hub.savedPlans];
    expect(plans, isNotEmpty);
    final planId = plans.first.id;

    // Prefer a nearby rally, then any gathering rally, then create one so the
    // test does not depend on seed geography.
    var rallies = await repo.fetchNearbyRallies(
      latitude: 9.9312,
      longitude: 76.2673,
    );
    if (rallies.isEmpty) rallies = await repo.fetchNearbyRallies();
    if (rallies.isEmpty) {
      rallies = [
        await repo.createRally(
          name: 'Smoke test invite rally (safe to ignore)',
          placeName: 'Kochi Smoke Point',
          latitude: 9.9312,
          longitude: 76.2673,
          minParticipants: 2,
          expiresHours: 1,
        ),
      ];
    }
    final rallyId = rallies.first.id;

    final clanInvites = await repo.sendInvites(
      userIds: [invitee],
      type: 'CLAN',
      targetId: clanId,
    );
    final tripInvites = await repo.sendInvites(
      userIds: [invitee],
      type: 'TRIP',
      targetId: planId,
      title: 'Join my trip',
    );
    final rallyInvites = await repo.sendInvites(
      userIds: [invitee],
      type: 'RALLY',
      targetId: rallyId,
    );
    expect([clanInvites, tripInvites, rallyInvites], [1, 1, 1]);

    // Read the invitee's inbox through the real client.
    final inbox = await inboxOf('+919876543211');
    NotificationItem pick(NotificationType type) => inbox.firstWhere(
          (n) => n.type == type,
          orElse: () => throw StateError(
              'no $type in inbox: ${inbox.map((n) => n.type).toList()}'),
        );

    final clanInvite = pick(NotificationType.clanInvite);
    final tripInvite = pick(NotificationType.tripInvite);
    final rallyInvite = pick(NotificationType.rallyAlert);

    expect(clanInvite.actionUrl, '/clans/$clanId',
        reason: 'the app routes clan notifications on /clans/<id>');
    expect(tripInvite.actionUrl, '/trips/$planId',
        reason: 'the app routes trip notifications on /trips/<id>');
    expect(tripInvite.title, 'Join my trip',
        reason: 'custom copy from the picker is forwarded');
    expect(rallyInvite.title, isNotEmpty);

    // ignore: avoid_print
    print('invites: clan=${clanInvite.actionUrl} trip=${tripInvite.actionUrl} '
        'rally=${rallyInvite.actionUrl} inbox=${inbox.length}');

    // The API rejects invites it cannot deep-link instead of reporting a
    // successful send: unknown type -> 400, missing target -> 404.
    await expectLater(
      repo.sendInvites(
        userIds: [invitee],
        type: 'POTLUCK',
        targetId: planId,
      ),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repo.sendInvites(
        userIds: [invitee],
        type: 'TRIP',
        targetId: '00000000-0000-0000-0000-000000000000',
      ),
      throwsA(isA<ApiException>()),
    );

    // Leave the shared seed signed in as the primary traveler.
    await repo.loginWithOtp('+919876543210', '12345');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
