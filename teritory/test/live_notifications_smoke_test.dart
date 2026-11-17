import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/models/notification_models.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Exercises Phase 7.0 against a running `teritory-api` on :4000:
/// an invite written by the API shows up in the invitee's inbox, is parsed
/// from the Prisma enum, can be marked read one-by-one and all at once.
///
/// Run: `flutter test test/live_notifications_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  test('invite → notification → mark read → mark all read', () async {
    await repo.loginWithOtp('+919876543210', '12345');
    final communities = await repo.fetchCommunitiesLive();
    expect(communities, isNotEmpty,
        reason: 'the seed must expose at least one community');
    final communityId = communities.first.id;

    final invited = await repo.sendInvites(
      userIds: const ['u2'],
      type: 'COMMUNITY',
      targetId: communityId,
    );
    expect(invited, 1);

    // Read the invitee's inbox: the server write must be visible there.
    await repo.loginWithOtp('+919876543211', '12345');
    final inbox = await repo.fetchNotifications();
    expect(inbox, isNotEmpty, reason: 'the invite must create a notification');

    final invite = inbox.firstWhere(
      (n) => n.type == NotificationType.communityInvite,
      orElse: () => throw StateError('no COMMUNITY_INVITE in inbox: '
          '${inbox.map((n) => n.type).toList()}'),
    );
    expect(invite.title, isNotEmpty);
    expect(invite.actionUrl, startsWith('/clans/'),
        reason: 'the app routes on actionUrl');

    await repo.markNotificationRead(invite.id);
    final afterOne = await repo.fetchNotifications();
    expect(afterOne.firstWhere((n) => n.id == invite.id).isRead, isTrue);

    await repo.markAllNotificationsRead();
    final afterAll = await repo.fetchNotifications();
    expect(afterAll.every((n) => n.isRead), isTrue,
        reason: 'mark-all must clear the remaining unread rows');

    // ignore: avoid_print
    print('notifications: invite read/mark-all ok for ${inbox.length} rows');

    // Leave the shared seed signed in as the primary traveler.
    await repo.loginWithOtp('+919876543210', '12345');
    // The shared Neon dev database gets slow under load; give the round-trips
    // room instead of failing on the 30 s default.
  }, timeout: const Timeout(Duration(minutes: 3)));
}
