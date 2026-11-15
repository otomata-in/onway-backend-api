import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../models/clan_models.dart';
import '../models/community_models.dart';
import '../models/trip_models.dart';
import '../models/rally_models.dart';
import '../models/service_models.dart';
import '../models/leaderboard_models.dart';
import '../models/notification_models.dart';
import '../services/mock_data_service.dart';

// ─── Clans ─────────────────────────────────────────────────────────────

final clansProvider = Provider<List<Clan>>((ref) {
  return MockDataService.instance.clans;
});

// ─── Communities ───────────────────────────────────────────────────────

final communitiesProvider = Provider<List<Community>>((ref) {
  return MockDataService.instance.communities;
});

final communityByIdProvider =
    Provider.family<Community?, String>((ref, id) {
  return MockDataService.instance.communityById(id);
});

// ─── Friends ───────────────────────────────────────────────────────────

final friendsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendsForUser('u1');
});

final friendRequestsProvider = Provider<List<FriendRelationship>>((ref) {
  return MockDataService.instance.friendRequestsForUser('u1');
});

// ─── Trips ─────────────────────────────────────────────────────────────

final tripPlansProvider = Provider<List<TripPlan>>((ref) {
  return MockDataService.instance.tripPlans;
});

final activeTripProvider = Provider<List<Trip>>((ref) {
  return MockDataService.instance.activeTrips
      .where((t) => t.status == TripStatus.active)
      .toList();
});

final tripHistoryProvider = Provider<List<TripCompletion>>((ref) {
  return MockDataService.instance.tripCompletions;
});

final savedPlansProvider = Provider<List<TripPlan>>((ref) {
  return MockDataService.instance.savedPlans;
});

// ─── Leaderboard ───────────────────────────────────────────────────────

final leaderboardProvider = Provider.family<List<LeaderboardEntry>,
    ({LeaderboardScope scope, LeaderboardPeriod period})>((ref, params) {
  return MockDataService.instance.leaderboard(params.scope, params.period);
});

// ─── Notifications ─────────────────────────────────────────────────────

final notificationsProvider = Provider<List<NotificationItem>>((ref) {
  return MockDataService.instance.notifications;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return MockDataService.instance.unreadNotifications.length;
});

// ─── Services ──────────────────────────────────────────────────────────

final nearbyServicesProvider = Provider<List<ServiceListing>>((ref) {
  return MockDataService.instance.serviceListings;
});

// ─── Rallies ───────────────────────────────────────────────────────────

final ralliesProvider = Provider<List<LegendaryRally>>((ref) {
  return MockDataService.instance.rallies;
});

// ─── Community Messages & Activities ───────────────────────────────────

final communityMessagesProvider =
    Provider.family<List<CommunityMessage>, String>((ref, communityId) {
  return MockDataService.instance.messagesByCommunity(communityId);
});

final communityActivitiesProvider =
    Provider.family<List<CommunityActivity>, String>((ref, communityId) {
  return MockDataService.instance.activitiesByCommunity(communityId);
});

// ─── Clan by ID ────────────────────────────────────────────────────────

final clanByIdProvider = Provider.family<Clan?, String>((ref, id) {
  return MockDataService.instance.clanById(id);
});

// ─── Communities by Clan ───────────────────────────────────────────────

final communitiesByClanProvider =
    Provider.family<List<Community>, String>((ref, clanId) {
  return MockDataService.instance.communitiesByClan(clanId);
});

// ─── Trip Plans by Community ───────────────────────────────────────────

final tripPlansByCommunityProvider =
    Provider.family<List<TripPlan>, String>((ref, communityId) {
  return MockDataService.instance.tripPlans
      .where((tp) => tp.communityId == communityId)
      .toList();
});

// ─── Community Members (mock) ──────────────────────────────────────────

final communityMembersProvider =
    Provider.family<List<CommunityMember>, String>((ref, communityId) {
  final users = MockDataService.instance.users;
  final community = MockDataService.instance.communityById(communityId);
  if (community == null) return [];

  final roles = [CommunityRole.creator, CommunityRole.moderator];
  return List.generate(
    users.length > community.memberCount ? community.memberCount : users.length,
    (i) => CommunityMember(
      id: 'cm_${communityId}_$i',
      communityId: communityId,
      userId: users[i].id,
      userName: users[i].displayName,
      userAvatar: users[i].avatarUrl,
      role: i == 0 ? roles[0] : (i == 1 ? roles[1] : CommunityRole.member),
      joinedAt: DateTime(2025, 4 + i, 1),
    ),
  );
});
