import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/models/flag_style.dart';
import 'package:teritory/core/models/user_models.dart';
import 'package:teritory/core/providers/auth_provider.dart';
import 'package:teritory/features/profile/presentation/flag_management_screen.dart';

ApiFlag _flag({
  required String id,
  required String placeName,
  bool isMajor = false,
  bool isHidden = false,
  double lat = 8.4828,
  double lng = 76.9436,
}) {
  return ApiFlag(
    id: id,
    userId: 'u_akhil',
    placeName: placeName,
    city: 'Thiruvananthapuram',
    country: 'India',
    countryCode: 'IN',
    continent: 'Asia',
    latitude: lat,
    longitude: lng,
    isMajorFlag: isMajor,
    isHidden: isHidden,
    category: 'Heritage',
    notes: 'Test note',
    photoUrl: '',
    kudos: 10,
    distanceKm: 0,
    flagStyle: FlagStyle.fallback,
    createdAt: DateTime(2026, 11, 28),
    authorName: 'Akhil V A',
    authorHandle: 'akhilva',
    authorAvatar: '',
  );
}

void main() {
  testWidgets(
    'FlagManagementScreen filters All/Major/Minor/Hidden and traverses with < / >',
    (tester) async {
      final flags = [
        _flag(id: 'f1', placeName: 'Padmanabhaswamy Temple', isMajor: true),
        _flag(id: 'f2', placeName: 'Technopark Pond', lat: 8.55, lng: 76.88),
        _flag(
          id: 'f3',
          placeName: 'Secret Cove',
          isHidden: true,
          lat: 8.51,
          lng: 76.90,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              User(
                id: 'u_akhil',
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
            home: FlagManagementScreen(initialFlags: flags),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manage My Flags'), findsOneWidget);
      expect(find.text('3 shown · 1 hidden'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Step forward with >
      await tester.tap(find.byKey(const Key('flag_mgmt_next')));
      await tester.pump();
      expect(find.text('2/3'), findsOneWidget);

      // Step backward with <
      await tester.tap(find.byKey(const Key('flag_mgmt_prev')));
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);

      // Filter by Hidden
      await tester.tap(find.text('Hidden'));
      await tester.pump();
      expect(find.text('1 shown · 1 hidden'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);

      // Filter by Major
      await tester.tap(find.text('Major'));
      await tester.pump();
      expect(find.text('1 shown · 1 hidden'), findsOneWidget);

      // Filter by Minor
      await tester.tap(find.text('Minor'));
      await tester.pump();
      expect(find.text('2 shown · 1 hidden'), findsOneWidget);
    },
  );
}

