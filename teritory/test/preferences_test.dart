import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/providers/preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('map theme is stored and restored on the next start', () async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceStore.instance.init();
    expect(PreferenceStore.instance.mapDark, isTrue, reason: 'Midnight default');

    final container = ProviderContainer();
    await container.read(mapThemeProvider.notifier).setDark(false);
    expect(container.read(mapThemeProvider), isFalse);
    container.dispose();

    // Simulate a relaunch: the store is re-read from disk.
    PreferenceStore.instance.mapDark = true;
    await PreferenceStore.instance.init();
    expect(PreferenceStore.instance.mapDark, isFalse);

    final relaunched = ProviderContainer();
    expect(relaunched.read(mapThemeProvider), isFalse);
    relaunched.dispose();
  });

  test('notification switches are stored and restored', () async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceStore.instance.init();
    expect(PreferenceStore.instance.notifications['tripUpdates'], isTrue);

    final container = ProviderContainer();
    await container
        .read(notificationPreferencesProvider.notifier)
        .setEnabled('tripUpdates', false);
    expect(container.read(notificationPreferencesProvider)['tripUpdates'], isFalse);
    container.dispose();

    PreferenceStore.instance.notifications =
        Map<String, bool>.of(PreferenceStore.defaultNotifications);
    await PreferenceStore.instance.init();

    final relaunched = ProviderContainer();
    final prefs = relaunched.read(notificationPreferencesProvider);
    expect(prefs['tripUpdates'], isFalse);
    expect(
      prefs['friendRequests'],
      isTrue,
      reason: 'other switches keep their defaults',
    );
    relaunched.dispose();
  });
}
