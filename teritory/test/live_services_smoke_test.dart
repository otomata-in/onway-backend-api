import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Exercises Phase 7.1 against a running `teritory-api` on :4000: both
/// `/services/gear` and `/services/nearby-food` parse into providers with
/// listings, and the API's distance ordering / 10 km food radius hold.
///
/// Run: `flutter test test/live_services_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  // Seed providers sit around Kazhakkoottam.
  const lat = 8.5686;
  const lng = 76.8731;

  setUpAll(() async {
    await repo.loginWithOtp('+919876543210', '12345');
  });

  test('GET /services/gear returns providers with listings', () async {
    final providers = await repo.fetchGearProviders(latitude: lat, longitude: lng);

    expect(providers, isNotEmpty, reason: 'seed registers gear providers');
    final withListings = providers.where((p) => p.listings.isNotEmpty).toList();
    expect(withListings, isNotEmpty);

    final first = withListings.first;
    expect(first.name, isNotEmpty);
    expect(first.category, isNotEmpty);
    expect(first.listings.first.title, isNotEmpty);
    expect(first.distanceKm, isNotNull);

    final distances = providers.map((p) => p.distanceKm ?? -1).toList();
    expect(distances, orderedEquals([...distances]..sort()),
        reason: 'the API sorts gear by distance');

    // ignore: avoid_print
    print('services: gear=${providers.length} '
        'listings=${withListings.fold<int>(0, (n, p) => n + p.listings.length)} '
        'nearest=${first.distanceKm!.toStringAsFixed(1)}km');
  });

  test('GET /services/nearby-food stays inside the 10 km radius', () async {
    final food = await repo.fetchNearbyFoodProviders(latitude: lat, longitude: lng);

    expect(food, isNotEmpty, reason: 'seed registers a food provider');
    expect(food.every((p) => (p.distanceKm ?? 0) <= 10.0), isTrue,
        reason: 'the API filters food to 10 km');
    expect(food.every((p) => p.category.toLowerCase().contains('food')), isTrue,
        reason: 'only food categories are returned');

    // ignore: avoid_print
    print('services: food=${food.length} '
        'nearest=${food.first.distanceKm?.toStringAsFixed(1)}km '
        'listings=${food.first.listings.length}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
