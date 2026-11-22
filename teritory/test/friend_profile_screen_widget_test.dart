import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/models/api_user.dart';
import 'package:teritory/core/models/user_models.dart';
import 'package:teritory/core/providers/auth_provider.dart';
import 'package:teritory/features/profile/application/profile_providers.dart';
import 'package:teritory/features/profile/presentation/friend_profile_screen.dart';

void main() {
  testWidgets('FriendProfileScreen renders details, friend action, mutuals, clans and flags',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final currentUser = User(
      id: 'u_akhil',
      displayName: 'Akhil V',
      handle: 'akhilva',
      avatarUrl: '',
      email: 'akhil@example.com',
      phone: '+919876543210',
      createdAt: DateTime.now(),
    );

    final targetProfile = const ApiUser(
      id: 'u_aarav',
      displayName: 'Aarav Patel',
      handle: 'aarav_wander',
      avatarUrl: '',
      bio: 'Highland trailblazer & UNESCO explorer',
      country: 'India',
      state: 'Kerala',
      district: 'Palakkad',
      totalFlags: 24,
      majorFlags: 6,
      countriesVisited: 8,
      continentsVisited: 3,
      completedTripsCount: 5,
      legendaryRalliesCount: 2,
      clans: [
        ApiUserClan(
          id: 'c1',
          name: 'Highland Trailblazers',
          tag: 'HTB',
          category: 'Adventure',
          role: 'CHIEFTAIN',
          memberCount: 28,
        ),
      ],
      mutualFriends: [
        ApiMutualFriend(
          id: 'u_sarah',
          displayName: 'Sarah Jenkins',
          handle: 'sarah_nomad',
          avatarUrl: '',
        ),
      ],
      mutualExploredAreas: ApiMutualExploredAreas(
        commonCountries: ['India', 'Nepal'],
        commonStates: ['Kerala'],
        commonContinents: ['Asia'],
      ),
      relationship: ApiUserRelationship(status: 'NONE'),
      passportStamps: [
        ApiPassportStamp(
          id: 's1',
          title: 'Machu Picchu Summit',
          category: 'World Wonder',
          date: '2026-03-15',
        ),
      ],
    );

    final targetFlags = <ApiFlag>[
      ApiFlag(
        id: 'f1',
        userId: 'u_aarav',
        placeName: 'Ponmudi Hill Peak',
        city: 'Thiruvananthapuram',
        country: 'India',
        countryCode: 'IN',
        continent: 'Asia',
        latitude: 8.76,
        longitude: 77.11,
        category: 'Summit',
        isMajorFlag: true,
        notes: 'Summit expedition',
        photoUrl: '',
        kudos: 12,
        distanceKm: 0,
        authorName: 'Aarav Patel',
        authorHandle: 'aarav_wander',
        authorAvatar: '',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(currentUser),
          userProfileProvider('u_aarav')
              .overrideWith((ref) async => targetProfile),
          userFlagsProvider('u_aarav')
              .overrideWith((ref) async => targetFlags),
          userFlagsProvider('u_akhil')
              .overrideWith((ref) async => const <ApiFlag>[]),
          friendsLiveProvider
              .overrideWith((ref) async => const <ApiFriend>[]),
          friendRequestsLiveProvider
              .overrideWith((ref) async => const FriendRequestsSnapshot(
                    incoming: [],
                    outgoing: [],
                  )),
        ],
        child: const MaterialApp(
          home: FriendProfileScreen(userId: 'u_aarav'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Name, Handle, Bio
    expect(find.text('Aarav Patel'), findsWidgets);
    expect(find.text('@aarav_wander'), findsOneWidget);
    expect(find.text('Highland trailblazer & UNESCO explorer'), findsOneWidget);

    // Verify Friend Action Button
    expect(find.text('Send Friend Request'), findsOneWidget);

    // Verify Expedition Telemetry Stats
    expect(find.text('Flags Staked'), findsOneWidget);
    expect(find.text('World Wonders'), findsOneWidget);
    expect(find.text('Nations'), findsOneWidget);
    expect(find.text('Continents'), findsOneWidget);

    // Verify Mutual Connections
    expect(find.text('MUTUAL CONNECTIONS (1)'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);

    // Verify Mutual Explored Areas
    expect(find.text('SHARED EXPLORED FRONTIERS'), findsOneWidget);
    expect(find.text('India'), findsWidgets);
    expect(find.text('Nepal'), findsOneWidget);
    expect(find.text('Kerala'), findsWidgets);

    // Verify Clans
    expect(find.text('CLANS & EXPEDITION FLEETS (1)'), findsOneWidget);
    expect(find.text('Highland Trailblazers'), findsOneWidget);

    // Scroll down to see map & flags
    await tester.scrollUntilVisible(
      find.text('Ponmudi Hill Peak'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ponmudi Hill Peak'), findsOneWidget);

    // Verify Passport Stamps
    expect(find.text('Passport Stamps (1)'), findsOneWidget);
    expect(find.text('Machu Picchu Summit'), findsOneWidget);
  });
}
