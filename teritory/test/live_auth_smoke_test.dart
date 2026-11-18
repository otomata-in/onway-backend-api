import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/services/api_service.dart';
import 'package:teritory/core/services/teritory_repository.dart';

/// Exercises the Phase 6.0 session gate against a running `teritory-api` on
/// http://localhost:4000: OTP dispatch, OTP verification, silent access-token
/// refresh and logout revocation.
///
/// Run: `flutter test test/live_auth_smoke_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final repo = TeritoryRepository.instance;
  final api = TeritoryApiService.instance;
  const phone = '+919876543210';

  test('send-otp then reject a wrong code', () async {
    await repo.sendOtp(phone);

    await expectLater(
      () => repo.loginWithOtp(phone, '00000'),
      throwsA(isA<ApiException>()),
      reason: 'only the dev bypass codes should be accepted',
    );
    expect(api.isAuthenticated, isFalse);
  });

  test('verify-otp stores both tokens', () async {
    final user = await repo.loginWithOtp(phone, '12345');
    expect(user.id, isNotEmpty);
    expect(user.phone, phone);

    expect(api.isAuthenticated, isTrue);
    expect(api.refreshToken, isNotNull);

    // Tokens live in the platform keystore keyed by flutter_secure_storage, so
    // the assertion here is that they are held in the session and never written
    // to plaintext preferences (§20).
    expect(api.accessToken, isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('teritory_access_token'), isNull);
    expect(prefs.getString('teritory_refresh_token'), isNull);

    // ignore: avoid_print
    print('auth: signed in as ${user.handle} (${user.id})');
  });

  test('expired access token refreshes silently and rotates tokens', () async {
    final expiredAccess = 'expired.${api.accessToken}';
    final refreshBefore = api.refreshToken!;
    await api.saveTokens(
      accessToken: expiredAccess,
      refreshToken: refreshBefore,
    );

    final me = await repo.fetchMyProfileOrThrow();
    expect(me.id, isNotEmpty);
    expect(api.accessToken, isNot(expiredAccess));
    expect(api.refreshToken, isNot(refreshBefore),
        reason: 'refresh tokens rotate on every use');

    // ignore: avoid_print
    print('auth: silent refresh ok, refresh token rotated');
  });

  test('logout revokes the session and clears local tokens', () async {
    await repo.logout();
    expect(api.isAuthenticated, isFalse);
    expect(api.refreshToken, isNull);

    await expectLater(
      () => repo.fetchMyProfileOrThrow(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('teritory_access_token'), isNull);
    expect(prefs.getString('teritory_refresh_token'), isNull);
  });
}
