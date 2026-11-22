import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/models/search_models.dart';
import 'package:teritory/features/explore/presentation/expedition_omni_search_sheet.dart';

void main() {
  test('SearchLocation model parses correctly from JSON', () {
    final json = {
      'city': 'Paris',
      'country': 'France',
      'latitude': 48.8584,
      'longitude': 2.2945,
      'flagCount': 3,
      'isGeocoded': true,
    };
    final loc = SearchLocation.fromJson(json);
    expect(loc.title, 'Paris');
    expect(loc.subtitle, 'France');
    expect(loc.latitude, 48.8584);
    expect(loc.longitude, 2.2945);
    expect(loc.flagCount, 3);
    expect(loc.isGeocoded, isTrue);
    expect(loc.coordinates, const LatLng(48.8584, 2.2945));
  });

  test('OmniSearchResult detects empty and non-empty state', () {
    const emptyResult = OmniSearchResult();
    expect(emptyResult.isEmpty, isTrue);
    expect(emptyResult.isNotEmpty, isFalse);

    final flag = ApiFlag(
      id: 'f1',
      userId: 'u1',
      placeName: 'Eiffel Tower',
      city: 'Paris',
      country: 'France',
      countryCode: 'FR',
      continent: 'Europe',
      latitude: 48.8584,
      longitude: 2.2945,
      isMajorFlag: true,
      category: 'Heritage',
      notes: 'Iconic iron tower',
      photoUrl: '',
      kudos: 100,
      distanceKm: 0.0,
      hiddenGemCount: 0,
      createdAt: DateTime.now(),
      authorName: 'Jean',
      authorHandle: 'jean',
      authorAvatar: '',
    );

    final result = OmniSearchResult(flags: [flag]);
    expect(result.isEmpty, isFalse);
    expect(result.isNotEmpty, isTrue);
  });

  testWidgets('ExpeditionOmniSearchSheet renders search bar and category chips',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpeditionOmniSearchSheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify search bar presence
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText ==
                'Search places, flags, explorers, clans...',
      ),
      findsOneWidget,
    );

    // Verify category chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Places & Flags'), findsOneWidget);
    expect(find.text('Explorers'), findsOneWidget);
    expect(find.text('Clans'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
