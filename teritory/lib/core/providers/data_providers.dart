import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_models.dart';
import '../models/notification_models.dart';
import '../services/teritory_repository.dart';

// ─── Notifications ─────────────────────────────────────────────────────

/// Live notification inbox: the server list is the only source, so an error
/// is rendered as an error (with retry) instead of falling back to mock rows.
class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() =>
      TeritoryRepository.instance.fetchNotifications();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => TeritoryRepository.instance.fetchNotifications(),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull ?? const <NotificationItem>[];
    state = AsyncData([
      for (final item in current)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ]);
    try {
      await TeritoryRepository.instance.markNotificationRead(id);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? const <NotificationItem>[];
    state = AsyncData([
      for (final item in current) item.copyWith(isRead: true),
    ]);
    try {
      await TeritoryRepository.instance.markAllNotificationsRead();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
      NotificationsNotifier.new,
    );

final notificationsProvider = Provider<AsyncValue<List<NotificationItem>>>((
  ref,
) {
  return ref.watch(notificationsNotifierProvider);
});

/// Zero while loading or signed out — the bell never invents a count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items =
      ref.watch(notificationsNotifierProvider).valueOrNull ??
      const <NotificationItem>[];
  return items.where((n) => !n.isRead).length;
});

// ─── Services ──────────────────────────────────────────────────────────

/// The map centre the services endpoints are queried around.
typedef ServiceLocation = ({double lat, double lng});

/// Live `GET /services/gear?lat&lng`, already distance-sorted by the API.
final gearServicesProvider = FutureProvider.autoDispose
    .family<List<ServiceProvider>, ServiceLocation>(
      (ref, location) => TeritoryRepository.instance.fetchGearProviders(
        latitude: location.lat,
        longitude: location.lng,
      ),
    );

/// Live `GET /services/nearby-food?lat&lng` (10 km radius server-side).
final nearbyFoodProvidersProvider = FutureProvider.autoDispose
    .family<List<ServiceProvider>, ServiceLocation>(
      (ref, location) => TeritoryRepository.instance.fetchNearbyFoodProviders(
        latitude: location.lat,
        longitude: location.lng,
      ),
    );

// ─── Removed with Phase 7.5 ────────────────────────────────────────────
// The mock-seeded `tripPlans*`, `activeTrip*`, `friends` and `friendRequests`
// providers were deleted: no screen read them, and they were pinned to the
// fake user `u1`. Trips read through `tripsHubProvider`, friends through
// `friendsLiveProvider` / `friendRequestsLiveProvider` in `profile_providers.dart`.
