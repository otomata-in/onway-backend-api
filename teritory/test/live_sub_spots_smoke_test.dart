import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Phase 7.4: the Explore Sub-Spots filter reads `GET /flags/sub-territories`.
/// Seeds one non-major flag at the Explore centre, marks it a hidden gem from a
/// second account, then checks the endpoint returns it within 5 km, ordered by
/// gem count.
///
/// Run against `teritory-api` on :4000:
/// `flutter test test/live_sub_spots_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;
  const centerLat = 9.9790;
  const centerLng = 76.2760;

  test('sub-territories surface nearby hidden gems only', () async {
    await repo.loginWithOtp('+919876543210', '12345');

    final placeName =
        'Sub-spot smoke ${DateTime.now().millisecondsSinceEpoch}';
    await repo.dropFlag(
      placeName: placeName,
      latitude: centerLat,
      longitude: centerLng,
      city: 'Kochi',
      notes: 'created by live_sub_spots_smoke_test (safe to delete)',
    );

    final flags = await repo.fetchExploreFlags(
      latitude: centerLat,
      longitude: centerLng,
      radiusKm: 5,
    );
    final seeded = flags.firstWhere(
      (flag) => flag.placeName == placeName,
      orElse: () => throw StateError('seeded flag not in explore results'),
    );

    // A second traveler marks it as a hidden gem.
    await repo.loginWithOtp('+919876543211', '12345');
    await repo.toggleFlagReaction(seeded.id, 'HIDDEN_GEM');
    await repo.loginWithOtp('+919876543210', '12345');

    final spots = await repo.fetchSubTerritories(
      latitude: centerLat,
      longitude: centerLng,
    );
    expect(spots, isNotEmpty);

    final mine = spots.firstWhere(
      (spot) => spot.placeName == placeName,
      orElse: () => throw StateError('seeded sub-spot not returned'),
    );
    expect(mine.hiddenGemCount, greaterThanOrEqualTo(1));
    expect(mine.distanceKm, lessThanOrEqualTo(5.0));

    // Endpoint contract: 5 km ceiling and gem-first ordering.
    expect(spots.every((spot) => spot.distanceKm <= 5.0), isTrue);
    final gems = spots.map((spot) => spot.hiddenGemCount).toList();
    final sorted = [...gems]..sort((a, b) => b.compareTo(a));
    expect(gems, sorted, reason: 'server sorts by hiddenGemCount desc');

    // ignore: avoid_print
    print('sub-spots=${spots.length} seeded=${mine.placeName} '
        'gems=${mine.hiddenGemCount} distanceKm=${mine.distanceKm} '
        'top=${spots.first.hiddenGemCount}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
