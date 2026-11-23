import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/core/models/flag_style.dart';
import 'package:teritory/core/widgets/flag/teritory_flag.dart';
import 'package:teritory/features/flag/presentation/epic_flag_staking_ceremony.dart';
import 'package:teritory/features/flag/presentation/flag_studio_screen.dart';

void main() {
  testWidgets('the studio opens on the saved signature and marks edits', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FlagStudioScreen())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Flag Studio'), findsOneWidget);
    expect(find.text('QUICK STARTS'), findsOneWidget);
    // Nothing has been touched yet, so the save action is a status, not a verb.
    expect(find.text('Signature saved'), findsOneWidget);
    expect(find.text('All changes saved'), findsOneWidget);

    await tester.ensureVisible(find.text('Black Pirate').first);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Black Pirate').first);
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('Save signature'), findsOneWidget);
  });

  testWidgets('every studio section lays out while scrolling', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FlagStudioScreen())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    var sawEmblem = false;
    var sawMotion = false;
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
      if (find.text('EMBLEM').evaluate().isNotEmpty) sawEmblem = true;
      if (find.text('MOTION').evaluate().isNotEmpty) sawMotion = true;
    }

    expect(sawEmblem, isTrue, reason: 'the emblem section never laid out');
    expect(sawMotion, isTrue, reason: 'the motion section never laid out');
    expect(find.text('Wind speed'), findsOneWidget);
  });

  testWidgets('the staking ceremony reveals the staked style', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EpicFlagStakingCeremony(
          placeName: 'Test Point',
          city: 'Kochi',
          coordinates: LatLng(9.97, 76.28),
          isMajorFlag: false,
          category: 'Hidden Gem',
          style: FlagStyle(
            theme: 'black_pirate',
            emblem: 'skull',
            motion: 'storm',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(tester.takeException(), isNull);
    expect(find.text('Test Point'), findsOneWidget);
    expect(find.textContaining('Black Pirate'), findsWidgets);
  });

  testWidgets('map pins follow one shared wind clock', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            devicePixelRatio: tester.view.devicePixelRatio,
          ),
          child: const Scaffold(
            body: Center(
              child: FlagMotionHost(
                child: FlagPinFlag(
                  style: FlagStyle(theme: 'crimson_charge', motion: 'storm'),
                  width: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 420));

    expect(tester.takeException(), isNull);
    expect(find.byType(FlagPinFlag), findsOneWidget);
    expect(find.byType(TeritoryFlag), findsOneWidget);
  });
}
