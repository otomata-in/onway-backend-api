import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/features/profile/presentation/worldwide_flag_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleFlags = <ApiFlag>[
    ApiFlag(
      id: 'flag-1',
      userId: 'user-1',
      latitude: 25.1972,
      longitude: 55.2744,
      placeName: 'Burj Khalifa Peak',
      category: 'Wonders',
      continent: 'Asia',
      country: 'United Arab Emirates',
      countryCode: 'AE',
      city: 'Dubai',
      isMajorFlag: true,
      notes: 'Stunning viewpoint',
      photoUrl: '',
      kudos: 10,
      distanceKm: 0.0,
      authorName: 'Alex Explorer',
      authorHandle: '@alex',
      authorAvatar: '',
      createdAt: DateTime.now(),
    ),
    ApiFlag(
      id: 'flag-2',
      userId: 'user-1',
      latitude: 48.8584,
      longitude: 2.2945,
      placeName: 'Eiffel Tower',
      category: 'Monument',
      continent: 'Europe',
      country: 'France',
      countryCode: 'FR',
      city: 'Paris',
      isMajorFlag: false,
      notes: 'Classic monument',
      photoUrl: '',
      kudos: 5,
      distanceKm: 0.0,
      authorName: 'Alex Explorer',
      authorHandle: '@alex',
      authorAvatar: '',
      createdAt: DateTime.now(),
    ),
  ];

  group('WorldwideFlagMapScreen Tests', () {
    testWidgets('renders flags, default Daylight theme, and control buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorldwideFlagMapScreen(
            flags: sampleFlags,
            startInLandscape: false,
            initialOceanic: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title stats
      expect(find.text('2 Spots • 2 Continents'), findsOneWidget);
      expect(find.text('⭐ 1 Major'), findsOneWidget);

      // Check theme buttons
      expect(find.text('☀️ Daylight'), findsOneWidget);
      expect(find.text('🌊 Oceanic'), findsOneWidget);

      // Check regional presets
      expect(find.text('🌍 World'), findsOneWidget);
      expect(find.text('🇮🇳 Asia / India'), findsOneWidget);
      expect(find.text('🇪🇺 Europe'), findsOneWidget);
      expect(find.text('🇦🇪 Middle East'), findsOneWidget);
      expect(find.text('🌎 Americas'), findsOneWidget);
      expect(find.text('🇦🇺 Oceania'), findsOneWidget);

      // Check rotate toggle button icon
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('toggles Daylight to Oceanic and back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorldwideFlagMapScreen(
            flags: sampleFlags,
            startInLandscape: false,
            initialOceanic: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Oceanic theme button
      await tester.tap(find.text('🌊 Oceanic'));
      await tester.pumpAndSettle();

      // Tap Daylight theme button
      await tester.tap(find.text('☀️ Daylight'));
      await tester.pumpAndSettle();
    });

    testWidgets('toggles orientation between landscape and portrait',
        (tester) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorldwideFlagMapScreen(
            flags: sampleFlags,
            startInLandscape: true,
            initialOceanic: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have requested landscape
      expect(
        log.any((call) =>
            call.method == 'SystemChrome.setPreferredOrientations' &&
            call.arguments.toString().contains('DeviceOrientation.landscape')),
        isTrue,
      );

      // Tap orientation toggle icon
      final rotateBtn = find.byIcon(Icons.stay_current_portrait_rounded);
      expect(rotateBtn, findsOneWidget);
      await tester.tap(rotateBtn);
      await tester.pumpAndSettle();

      // Now should have toggled to portrait
      expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
    });

    testWidgets('empty flags renders empty indicator cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldwideFlagMapScreen(
            flags: [],
            startInLandscape: false,
            initialOceanic: false,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No flags dropped yet'), findsOneWidget);
      expect(find.text('0 Spots • 0 Continents'), findsOneWidget);
    });

    testWidgets('landscape dialog returns true on Yes and false on No',
        (tester) async {
      bool? result;

      Widget buildTestApp() => MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: ctx,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Landscape World View?'),
                        content: const Text('Open in Landscape?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: const Text('No, Keep Portrait'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            child: const Text('Yes, Landscape'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Landscape World View?'), findsOneWidget);

      // Tap Yes, Landscape
      await tester.tap(find.text('Yes, Landscape'));
      await tester.pumpAndSettle();

      expect(result, isTrue);

      // Tap again to test No
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No, Keep Portrait'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('exits cleanly and restores portrait when back button tapped',
        (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorldwideFlagMapScreen(
                      flags: sampleFlags,
                      startInLandscape: false,
                      initialOceanic: false,
                    ),
                  ),
                );
                popped = true;
              },
              child: const Text('Open Map'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();

      expect(find.byType(WorldwideFlagMapScreen), findsOneWidget);

      // Tap back button
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(WorldwideFlagMapScreen), findsNothing);
    });

    testWidgets('exits cleanly on system pop navigation', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorldwideFlagMapScreen(
                      flags: sampleFlags,
                      startInLandscape: false,
                      initialOceanic: false,
                    ),
                  ),
                );
                popped = true;
              },
              child: const Text('Open Map'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();

      expect(find.byType(WorldwideFlagMapScreen), findsOneWidget);

      // Simulate system pop via navigator
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      // ignore: avoid_dynamic_calls
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(WorldwideFlagMapScreen), findsNothing);
    });
  });
}
