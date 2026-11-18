import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Phase 7.5: the Wonders catalogue reads `GET /flags/wonders`.
/// Drops a major-wonder flag and a normal flag under unique place names, then
/// checks the registry aggregates the major one (claim count, claimants, own
/// claim flag) and never lists the plain flag.
///
/// Run against `teritory-api` on :4000:
/// `flutter test test/live_wonders_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;

  test('wonders registry aggregates major-wonder flags only', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final wonderName = 'Wonders smoke $stamp';
    final plainName = 'Plain flag smoke $stamp';

    await repo.loginWithOtp('+919876543210', '12345');
    await repo.dropFlag(
      placeName: wonderName,
      latitude: 27.1751,
      longitude: 78.0421,
      city: 'Agra',
      isMajorFlag: true,
      notes: 'created by live_wonders_smoke_test (safe to delete)',
    );
    await repo.dropFlag(
      placeName: plainName,
      latitude: 27.1752,
      longitude: 78.0422,
      city: 'Agra',
      notes: 'created by live_wonders_smoke_test (safe to delete)',
    );

    final firstRead = await repo.fetchWonders();
    final mine = firstRead.firstWhere(
      (wonder) => wonder.placeName == wonderName,
      orElse: () => throw StateError('major flag missing from the registry'),
    );
    expect(mine.claimCount, greaterThanOrEqualTo(1));
    expect(mine.claimedByMe, isTrue);
    expect(mine.latestFlagId, isNotEmpty);
    expect(mine.claimers, isNotEmpty);
    expect(mine.continent, isNotEmpty);
    expect(
      firstRead.any((wonder) => wonder.placeName == plainName),
      isFalse,
      reason: 'non-major flags must not enter the registry',
    );

    // A second traveler claims the same wonder.
    await repo.loginWithOtp('+919876543211', '12345');
    await repo.dropFlag(
      placeName: wonderName,
      latitude: 27.1751,
      longitude: 78.0421,
      city: 'Agra',
      isMajorFlag: true,
      notes: 'second claim by live_wonders_smoke_test',
    );

    final otherRead = await repo.fetchWonders();
    final shared = otherRead.firstWhere(
      (wonder) => wonder.placeName == wonderName,
      orElse: () => throw StateError('shared wonder disappeared'),
    );
    expect(shared.claimCount, greaterThanOrEqualTo(2));
    expect(shared.claimers.length, greaterThanOrEqualTo(2));
    expect(shared.claimedByMe, isTrue, reason: 'u2 also claimed it');
    expect(shared.country, 'India');
    expect(shared.city, 'Agra');

    // Back as the first traveler: still claimed, still aggregated.
    await repo.loginWithOtp('+919876543210', '12345');
    final finalRead = await repo.fetchWonders();
    final again = finalRead.firstWhere((wonder) => wonder.placeName == wonderName);
    expect(again.claimedByMe, isTrue);
    expect(again.claimCount, shared.claimCount);

    // Server ordering contract: most-claimed first.
    final counts = finalRead.map((wonder) => wonder.claimCount).toList();
    final sorted = [...counts]..sort((a, b) => b.compareTo(a));
    expect(counts, sorted, reason: 'server sorts by claimCount desc');

    // ignore: avoid_print
    print('wonders=${finalRead.length} seeded=${again.placeName} '
        'claims=${again.claimCount} claimers=${again.claimers.length} '
        'continent=${again.continent} latestFlag=${again.latestFlagId}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
