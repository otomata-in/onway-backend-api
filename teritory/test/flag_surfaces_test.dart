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

    await tester.pump(const Duration(milliseconds: 1400));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1800));

    expect(tester.takeException(), isNull);
    expect(find.text('Test Point'), findsOneWidget);
    expect(find.textContaining('Black Pirate'), findsWidgets);
  });

  testWidgets('reduce motion jumps straight to the stamped frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EpicFlagStakingCeremony(
            placeName: 'Calm Point',
            city: 'Kochi',
            coordinates: LatLng(9.97, 76.28),
            isMajorFlag: false,
            category: 'Hidden Gem',
            style: FlagStyle(theme: 'midnight_tide', emblem: 'compass'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(tester.takeException(), isNull);
    expect(find.text('Calm Point'), findsOneWidget);
    expect(find.text('CONTINUE EXPEDITION'), findsOneWidget);
  });

  for (final size in const [
    Size(390, 844), // iPhone 14 / Pixel 8
    Size(360, 640), // small Android
    Size(412, 915), // tall Android
    Size(844, 390), // landscape
    Size(820, 1180), // tablet portrait
  ]) {
    testWidgets('ceremony fits ${size.width.toInt()}x${size.height.toInt()} with a gesture bar', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              devicePixelRatio: 3,
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: const EpicFlagStakingCeremony(
              placeName: 'Varkala Cliff',
              city: 'Varkala, Kerala',
              coordinates: LatLng(8.7379, 76.7163),
              isMajorFlag: true,
              category: 'Scenic Viewpoint',
              style: FlagStyle(
                theme: 'crimson_charge',
                emblem: 'star',
                motion: 'storm',
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 4800));
      expect(tester.takeException(), isNull);

      final cta = tester.getRect(find.byType(ElevatedButton));
      expect(cta.top, greaterThan(0));
      // The CTA must sit above the 34px gesture bar, not under it.
      expect(cta.bottom, lessThanOrEqualTo(size.height - 30));
      expect(find.text('CONTINUE EXPEDITION'), findsOneWidget);
    });
  }

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
