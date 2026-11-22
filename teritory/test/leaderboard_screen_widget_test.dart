import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/user_models.dart';
import 'package:teritory/core/models/leaderboard_models.dart';
import 'package:teritory/core/providers/auth_provider.dart';
import 'package:teritory/features/rankings/application/rankings_provider.dart';
import 'package:teritory/features/rankings/presentation/leaderboard_screen.dart';

class _FakeFeedNotifier extends LeaderboardFeedNotifier {
  _FakeFeedNotifier(this._fakeEntries);

  final List<LeaderboardEntry> _fakeEntries;

  @override
  Future<LeaderboardFeedState> build(LeaderboardQuery query) async {
    return LeaderboardFeedState(
      entries: _fakeEntries,
      hasMore: false,
      total: _fakeEntries.length,
    );
  }

  @override
  Future<void> loadMore() async {}

  Future<void> refresh() async {}
}

void main() {
  testWidgets('LeaderboardScreen renders the Grand Expedition Vanguard and explorer logs',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final fakeUser = User(
      id: 'u_akhil',
      displayName: 'Akhil V',
      handle: 'akhilva',
      avatarUrl: '',
      email: 'akhil@example.com',
      phone: '+919876543210',
      bio: 'Expedition explorer',
      createdAt: DateTime.now(),
    );

    final fakeEntries = [
      const LeaderboardEntry(
        id: 'u3',
        userId: 'u3',
        userName: 'Aarav Patel',
        userHandle: 'aarav_wander',
        userAvatar: '',
        rank: 1,
        compositeScore: 3785,
        majorFlags: 4,
        totalFlags: 28,
        countriesVisited: 12,
        continentsExplored: 3,
        completedTrips: 6,
      ),
      const LeaderboardEntry(
        id: 'u1',
        userId: 'u1',
        userName: 'Sarah Jenkins',
        userHandle: 'sarah_nomad',
        userAvatar: '',
        rank: 2,
        compositeScore: 3130,
        majorFlags: 3,
        totalFlags: 20,
        countriesVisited: 8,
        continentsExplored: 2,
        completedTrips: 4,
      ),
      const LeaderboardEntry(
        id: 'u5',
        userId: 'u5',
        userName: 'Elena Rostova',
        userHandle: 'elena_explorer',
        userAvatar: '',
        rank: 3,
        compositeScore: 2215,
        majorFlags: 2,
        totalFlags: 15,
        countriesVisited: 5,
        continentsExplored: 2,
        completedTrips: 3,
      ),
      const LeaderboardEntry(
        id: 'u_akhil',
        userId: 'u_akhil',
        userName: 'Akhil V',
        userHandle: 'akhilva',
        userAvatar: '',
        rank: 4,
        compositeScore: 2175,
        majorFlags: 2,
        totalFlags: 14,
        countriesVisited: 4,
        continentsExplored: 2,
        completedTrips: 2,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(fakeUser),
          rankingsFacetsProvider.overrideWith(
            (ref) async => const RankingsFacets(
              countries: ['India', 'Nepal'],
              states: ['Kerala', 'Karnataka'],
              districts: ['Thiruvananthapuram'],
            ),
          ),
          leaderboardFeedProvider.overrideWith(
            () => _FakeFeedNotifier(fakeEntries),
          ),
          myRankProvider.overrideWith(
            (ref) async => const MyRank(
              score: 2175,
              globalRank: 4,
              totalUsers: 120,
              breakdown: {
                'majorFlagsPoints': 800,
                'flagsPoints': 700,
                'countriesPoints': 400,
                'continentsPoints': 200,
                'tripsPoints': 75,
              },
            ),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title
    expect(find.text('EXPEDITION ANNALS'), findsOneWidget);
    expect(find.text('ROSTER'), findsOneWidget);
    expect(find.text('GPS TELEMETRY'), findsOneWidget);

    // Verify Grand Expedition Vanguard
    expect(find.text('GRAND EXPEDITION VANGUARD'), findsOneWidget);
    expect(find.text('APEX TRAILBLAZER #1'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('MASTER NAVIGATOR'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('VANGUARD PIONEER'), findsOneWidget);
    expect(find.text('Elena Rostova'), findsOneWidget);

    // Verify Explorer Field Logbook
    expect(find.text('EXPLORER FIELD LOGBOOK'), findsOneWidget);
    expect(find.text('Akhil V'), findsWidgets);

    // Verify Sticky Bottom Field HUD
    expect(find.text('FIELD STANDING'), findsOneWidget);
    expect(find.text('#4'), findsWidgets);

    // Verify Expedition Merit Ledger
    expect(find.text('EXPEDITION MERIT LEDGER'), findsOneWidget);
  });
}
