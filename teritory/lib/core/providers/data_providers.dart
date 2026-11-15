import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../models/clan_models.dart';
import '../models/community_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/leaderboard_models.dart';
import '../models/notification_models.dart';
import '../services/teritory_repository.dart';
import '../services/mock_data_service.dart';

// ─── Clans ─────────────────────────────────────────────────────────────

class ClansNotifier extends Notifier<List<Clan>> {
  @override
  List<Clan> build() {
    _load();
    return MockDataService.instance.clans;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchClans();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final clansNotifierProvider =
    NotifierProvider<ClansNotifier, List<Clan>>(ClansNotifier.new);

final clansProvider = Provider<List<Clan>>((ref) {
  return ref.watch(clansNotifierProvider);
});

final clanByIdProvider = Provider.family<Clan?, String>((ref, id) {
  final clans = ref.watch(clansProvider);
  return clans.cast<Clan?>().firstWhere(
        (c) => c?.id == id,
        orElse: () => MockDataService.instance.clanById(id),
      );
});

// ─── Communities ───────────────────────────────────────────────────────

class CommunitiesNotifier extends Notifier<List<Community>> {
  @override
  List<Community> build() {
    _load();
    return MockDataService.instance.communities;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchCommunities();
    state = live;
  }

  Future<void> refresh() async => _load();
}

final communitiesNotifierProvider =
    NotifierProvider<CommunitiesNotifier, List<Community>>(CommunitiesNotifier.new);

final communitiesProvider = Provider<List<Community>>((ref) {
  return ref.watch(communitiesNotifierProvider);
});

final communityByIdProvider =
    Provider.family<Community?, String>((ref, id) {
  final communities = ref.watch(communitiesProvider);
  return communities.cast<Community?>().firstWhere(
        (c) => c?.id == id,
        orElse: () => MockDataService.instance.communityById(id),
      );
});

final communitiesByClanProvider =
    Provider.family<List<Community>, String>((ref, clanId) {
  final communities = ref.watch(communitiesProvider);
  return communities.where((c) => c.parentClanId == clanId).toList();
});

// ─── Community Members ─────────────────────────────────────────────────

class CommunityMembersNotifier
    extends FamilyNotifier<List<CommunityMember>, String> {
  @override
  List<CommunityMember> build(String arg) {
    _load(arg);
    return MockDataService.instance.communityMembers(arg);
  }

  Future<void> _load(String communityId) async {
    final members = await TeritoryRepository.instance.fetchCommunityMembers(communityId);
    state = members;
  }
}

final communityMembersNotifierProvider =
    NotifierProvider.family<CommunityMembersNotifier, List<CommunityMember>, String>(
        CommunityMembersNotifier.new);

final communityMembersProvider =
    Provider.family<List<CommunityMember>, String>((ref, communityId) {
  return ref.watch(communityMembersNotifierProvider(communityId));
});

// ─── Community Messages ────────────────────────────────────────────────

class CommunityMessagesNotifier
    extends FamilyNotifier<List<CommunityMessage>, String> {
  @override
  List<CommunityMessage> build(String arg) {
    _load(arg);
    return MockDataService.instance.messagesByCommunity(arg);
  }

  Future<void> _load(String communityId) async {
    final messages = await TeritoryRepository.instance.fetchCommunityMessages(communityId);
    state = messages;
  }

  Future<void> sendMessage(String text) async {
    final newMsg = await TeritoryRepository.instance.sendCommunityMessage(arg, text);
    if (newMsg != null) {
      state = [...state, newMsg];
    }
  }
}

final communityMessagesNotifierProvider =
    NotifierProvider.family<CommunityMessagesNotifier, List<CommunityMessage>, String>(
        CommunityMessagesNotifier.new);

final communityMessagesProvider =
    Provider.family<List<CommunityMessage>, String>((ref, communityId) {
  return ref.watch(communityMessagesNotifierProvider(communityId));
});

final communityActivitiesProvider =
    Provider.family<List<CommunityActivity>, String>((ref, communityId) {
  return MockDataService.instance.activitiesByCommunity(communityId);
});

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

final tripPlansByCommunityProvider =
    Provider.family<List<TripPlan>, String>((ref, communityId) {
  final plans = ref.watch(tripPlansProvider);
  return plans.where((tp) => tp.communityId == communityId).toList();
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

final tripHistoryProvider = Provider<List<TripCompletion>>((ref) {
  return MockDataService.instance.tripCompletions;
});

class SavedPlansNotifier extends Notifier<List<TripPlan>> {
  @override
  List<TripPlan> build() {
    _load();
    return MockDataService.instance.savedPlans;
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchSavedPlans();
    state = live;
  }

  Future<void> toggleSave(String planId) async {
    await TeritoryRepository.instance.toggleSavePlan(planId);
    _load();
  }
}

final savedPlansNotifierProvider =
    NotifierProvider<SavedPlansNotifier, List<TripPlan>>(SavedPlansNotifier.new);

final savedPlansProvider = Provider<List<TripPlan>>((ref) {
  return ref.watch(savedPlansNotifierProvider);
});

// ─── Friends ───────────────────────────────────────────────────────────

final friendsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendsForUser('u1');
});

final friendRequestsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendRequestsForUser('u1');
});

// ─── Leaderboard ───────────────────────────────────────────────────────

class LeaderboardNotifier extends FamilyNotifier<List<LeaderboardEntry>,
    ({LeaderboardScope scope, LeaderboardPeriod period})> {
  @override
  List<LeaderboardEntry> build(
      ({LeaderboardScope scope, LeaderboardPeriod period}) arg) {
    _load();
    return MockDataService.instance.leaderboard(arg.scope, arg.period);
  }

  Future<void> _load() async {
    final live = await TeritoryRepository.instance.fetchLeaderboard(
      scope: arg.scope,
      period: arg.period,
    );
    state = live;
  }
}

final leaderboardNotifierProvider = NotifierProvider.family<LeaderboardNotifier,
    List<LeaderboardEntry>,
    ({LeaderboardScope scope, LeaderboardPeriod period})>(
  LeaderboardNotifier.new,
);

final leaderboardProvider = Provider.family<List<LeaderboardEntry>,
    ({LeaderboardScope scope, LeaderboardPeriod period})>((ref, params) {
  return ref.watch(leaderboardNotifierProvider(params));
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
