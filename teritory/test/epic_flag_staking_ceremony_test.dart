import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:teritory/features/flag/presentation/epic_flag_staking_ceremony.dart';

void main() {
  group('EpicFlagStakingCeremony Widget Tests', () {
    testWidgets('renders initial ceremony without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EpicFlagStakingCeremony(
            placeName: 'Machu Picchu Citadel',
            city: 'Cusco, Peru',
            coordinates: LatLng(-13.1631, -72.5450),
            isMajorFlag: true,
            category: 'Wonder',
          ),
        ),
      );

      // Initially, ceremony is running plunge animation
      expect(find.byType(EpicFlagStakingCeremony), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows bedrock shove effort indicator during mid-animation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EpicFlagStakingCeremony(
            placeName: 'Taj Mahal Monument',
            city: 'Agra, India',
            coordinates: LatLng(27.1751, 78.0421),
            isMajorFlag: true,
            category: 'Wonder',
          ),
        ),
      );

      // Fast forward to t ~ 0.46 (46% of 2400ms ≈ 1100ms)
      await tester.pump(const Duration(milliseconds: 1100));

      // Check for muscular effort indicator
      expect(find.text('CLAIMING BEDROCK...'), findsOneWidget);
    });

    testWidgets('completes ceremony and displays telemetry HUD and continue button',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await EpicFlagStakingCeremony.show(
                    context,
                    placeName: 'Fort Kochi Waterfront',
                    city: 'Kochi, India',
                    coordinates: const LatLng(9.9656, 76.2421),
                    isMajorFlag: false,
                    category: 'Beach & Coastal',
                  );
                  dismissed = true;
                },
                child: const Text('Launch Ceremony'),
              ),
            ),
          ),
        ),
      );

      // Launch modal route
      await tester.tap(find.text('Launch Ceremony'));
      await tester.pump(); // Start transition

      // Settle the 2400ms ceremony + fade
      await tester.pump(const Duration(milliseconds: 2500));

      // Telemetry HUD card details
      expect(find.text('Fort Kochi Waterfront'), findsOneWidget);
      expect(find.text('Kochi, India • Beach & Coastal'), findsOneWidget);
      expect(
        find.text('TERITORY EXPEDITION FLAG STAKED • +100 MERIT'),
        findsOneWidget,
      );
      expect(find.text('CONTINUE EXPEDITION'), findsOneWidget);

      // Tap continue expedition to dismiss
      await tester.tap(find.text('CONTINUE EXPEDITION'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(find.byType(EpicFlagStakingCeremony), findsNothing);
    });

    testWidgets('Major Wonder displays +250 MERIT badge and wonder gold accents',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EpicFlagStakingCeremony(
            placeName: 'Colosseum Amphitheatre',
            city: 'Rome, Italy',
            coordinates: LatLng(41.8902, 12.4922),
            isMajorFlag: true,
            category: 'Ancient Wonder',
          ),
        ),
      );

      // Advance through full ceremony
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('MAJOR WONDER CONQUERED • +250 MERIT'),
        findsOneWidget,
      );
      expect(find.text('Colosseum Amphitheatre'), findsOneWidget);
    });
  });
}

