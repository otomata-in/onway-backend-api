import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/models/leaderboard_models.dart';
import 'package:teritory/core/services/teritory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test installs a fake HttpClient that answers 400 to everything;
  // this test intentionally talks to the local API.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  test('live rankings honour geo filters, scopes and periods', () async {
    // Same auto-login the app performs, so FRIENDS/CLAN/COMMUNITY are callable.
    await repo.loginWithOtp('+919876543210', '12345');

    final global = await repo.fetchLeaderboard();
    expect(global, isNotEmpty);
    expect(global.first.country, isNotEmpty);

    final india = await repo.fetchLeaderboard(
      scope: LeaderboardScope.country,
      country: 'India',
    );
    expect(india, isNotEmpty);
    expect(india.every((e) => e.country == 'India'), isTrue);

    final kerala = await repo.fetchLeaderboard(
      scope: LeaderboardScope.state,
      state: 'Kerala',
    );
    final karnataka = await repo.fetchLeaderboard(
      scope: LeaderboardScope.state,
      state: 'Karnataka',
    );
    expect(kerala, isNotEmpty);
    expect(karnataka, isEmpty);
    expect(kerala.map((e) => e.userId).toSet(),
        isNot(equals(karnataka.map((e) => e.userId).toSet())));

    final clan = await repo.fetchLeaderboard(scope: LeaderboardScope.clan);
    final community =
        await repo.fetchLeaderboard(scope: LeaderboardScope.community);
    expect(clan.length, lessThan(global.length));
    expect(community.length, lessThan(clan.length));

    final week =
        await repo.fetchLeaderboard(period: LeaderboardPeriod.week);
    expect(week, isNotEmpty);
    expect(week.first.userId, isNot(equals(global.first.userId)));

    final myRank = await repo.fetchMyRank();
    expect(myRank.score, greaterThan(0));
    expect(myRank.breakdown, isNotEmpty);

    // ignore: avoid_print
    print('global=${global.map((e) => '${e.userId}:${e.compositeScore}').join(',')}\n'
        'india=${india.length} kerala=${kerala.length} karnataka=${karnataka.length}\n'
        'clan=${clan.length} community=${community.length}\n'
        'week=${week.map((e) => '${e.userId}:${e.compositeScore}').join(',')}\n'
        'me=rank ${myRank.globalRank} score ${myRank.score}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
