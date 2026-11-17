import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Exercises the Phase 6.1 profile mutations against a running `teritory-api`
/// on http://localhost:4000: `PATCH /users/me` round-trip and the trip-mode
/// toggle. Edits are reverted so the seed traveler stays as it was.
///
/// Run: `flutter test test/live_profile_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  setUpAll(() async {
    await repo.loginWithOtp('+919876543210', '12345');
  });

  test('PATCH /users/me persists edits and returns the saved traveler',
      () async {
    final before = await repo.fetchMyProfileLive();
    final marker = 'Smoke bio ${DateTime.now().millisecondsSinceEpoch}';

    final saved = await repo.updateMyProfile(
      bio: marker,
      district: 'Kochi',
      state: 'Kerala',
      country: 'India',
      isPrivate: false,
    );
    expect(saved.id, before.id);
    expect(saved.bio, marker);
    expect(saved.district, 'Kochi');

    final reread = await repo.fetchMyProfileLive();
    expect(reread.bio, marker, reason: 'the edit must survive a fresh read');

    final restored = await repo.updateMyProfile(
      bio: before.bio,
      district: before.district,
      state: before.state,
      country: before.country,
      isPrivate: before.isPrivate,
    );
    expect(restored.bio, before.bio);

    // ignore: avoid_print
    print('profile: PATCH round-trip ok for ${saved.handle}');
  });

  test('trip-mode toggle flips the stored flag', () async {
    final before = (await repo.fetchMyProfileLive()).isTripMode;

    final toggled = await repo.setTripMode(!before);
    expect(toggled, !before);

    final reread = await repo.fetchMyProfileLive();
    expect(reread.isTripMode, !before);

    await repo.setTripMode(before);
    expect((await repo.fetchMyProfileLive()).isTripMode, before);

    // ignore: avoid_print
    print('profile: trip mode toggled off/on from $before');
  });
}
