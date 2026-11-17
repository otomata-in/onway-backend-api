import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/notification_models.dart';
import '../services/teritory_repository.dart';
import '../services/mock_data_service.dart';

// ─── Trips & Plans ─────────────────────────────────────────────────────

class TripPlansNotifier extends Notifier<List<TripPlan>> {
  @override
  List<TripPlan> build() {
    _load();
    return MockDataService.instance.tripPlans;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchProposedTripPlans();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final tripPlansNotifierProvider =
    NotifierProvider<TripPlansNotifier, List<TripPlan>>(TripPlansNotifier.new);

final tripPlansProvider = Provider<List<TripPlan>>((ref) {
  return ref.watch(tripPlansNotifierProvider);
});

class ActiveTripNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() {
    _load();
    return MockDataService.instance.activeTrips
        .where((t) => t.status == TripStatus.active)
        .toList();
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchActiveTrips();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final activeTripNotifierProvider =
    NotifierProvider<ActiveTripNotifier, List<Trip>>(ActiveTripNotifier.new);

final activeTripProvider = Provider<List<Trip>>((ref) {
  return ref.watch(activeTripNotifierProvider);
});

// ─── Friends ───────────────────────────────────────────────────────────

final friendsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendsForUser('u1');
});

final friendRequestsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendRequestsForUser('u1');
});

// ─── Notifications ─────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    _load();
    return MockDataService.instance.notifications;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchNotifications();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final notificationsNotifierProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        NotificationsNotifier.new);

final notificationsProvider = Provider<List<NotificationItem>>((ref) {
  return ref.watch(notificationsNotifierProvider);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});

// ─── Services ──────────────────────────────────────────────────────────

class ServicesNotifier extends Notifier<List<ServiceListing>> {
  @override
  List<ServiceListing> build() {
    _load();
    return MockDataService.instance.serviceListings;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchServices();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final servicesNotifierProvider =
    NotifierProvider<ServicesNotifier, List<ServiceListing>>(
        ServicesNotifier.new);

final nearbyServicesProvider = Provider<List<ServiceListing>>((ref) {
  return ref.watch(servicesNotifierProvider);
});

// ─── Rallies ───────────────────────────────────────────────────────────

class RalliesNotifier extends Notifier<List<LegendaryRally>> {
  @override
  List<LegendaryRally> build() {
    _load();
    return MockDataService.instance.rallies;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchRallies();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final ralliesNotifierProvider =
    NotifierProvider<RalliesNotifier, List<LegendaryRally>>(RalliesNotifier.new);

final ralliesProvider = Provider<List<LegendaryRally>>((ref) {
  return ref.watch(ralliesNotifierProvider);
});
