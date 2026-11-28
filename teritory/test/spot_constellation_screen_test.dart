import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/models/flag_style.dart';
import 'package:teritory/core/models/user_models.dart';
import 'package:teritory/core/providers/auth_provider.dart';
import 'package:teritory/core/widgets/flag/teritory_flag.dart';
import 'package:teritory/features/explore/presentation/spot_constellation_screen.dart';

ApiFlag _makeFlag({
  required String id,
  required String userId,
  required String authorName,
  bool isMajor = false,
}) {
  return ApiFlag(
    id: id,
    userId: userId,
    placeName: 'Taj Mahal',
    city: 'Agra',
    country: 'India',
    countryCode: 'IN',
    continent: 'Asia',
    latitude: 27.1751,
    longitude: 78.0421,
    isMajorFlag: isMajor,
    category: 'Heritage',
    notes: '',
    photoUrl: '',
    kudos: 12,
    distanceKm: 0.0,
    flagStyle: FlagStyle.fallback,
    createdAt: DateTime(2026, 11, 28),
    authorName: authorName,
    authorHandle: userId,
    authorAvatar: '',
  );
}

void main() {
  testWidgets(
    'SpotConstellationScreen renders center monument, surrounding flags, and filters',
    (tester) async {
      final flags = [
        _makeFlag(id: 'f1', userId: 'u_me', authorName: 'Akhil V A', isMajor: true),
        _makeFlag(id: 'f2', userId: 'u_friend', authorName: 'Priya Menon'),
        _makeFlag(id: 'f3', userId: 'u_other', authorName: 'Stranger Explorer'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              User(
                id: 'u_me',
                email: 'akhil@teritory.app',
                phone: '+918848793417',
                displayName: 'Akhil V A',
                handle: 'akhilva',
                avatarUrl: '',
                createdAt: DateTime(2026, 11, 28),
              ),
            ),
          ],
          child: MaterialApp(
            home: SpotConstellationScreen(
              flags: flags,
              friendIds: const {'u_friend'},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Taj Mahal'), findsWidgets);
      expect(find.text('3 of 3 flags · Spot Constellation'), findsOneWidget);
      expect(find.byType(FlagPinFlag), findsNWidgets(3));

      // Filter by Friends
      await tester.tap(find.text('Friends'));
      await tester.pump();
      expect(find.text('1 of 3 flags · Spot Constellation'), findsOneWidget);
      expect(find.byType(FlagPinFlag), findsOneWidget);

      // Filter by My Flags
      await tester.tap(find.text('My Flags'));
      await tester.pump();
      expect(find.text('1 of 3 flags · Spot Constellation'), findsOneWidget);

      // Back to All
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(find.text('3 of 3 flags · Spot Constellation'), findsOneWidget);
      expect(find.byType(FlagPinFlag), findsNWidgets(3));
    },
  );
}
