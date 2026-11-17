import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/sea_wave_nav_bar.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';

// ─── Screen imports ─────────────────────────────────────────────────────
import '../../features/home/presentation/home_map_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/clans/presentation/clan_browser_screen.dart';
import '../../features/clans/presentation/clan_detail_screen.dart';
import '../../features/community/presentation/community_detail_screen.dart';
import '../../features/community/presentation/community_create_screen.dart';
import '../../features/community/presentation/community_members_screen.dart';
import '../../features/community/presentation/community_chat_screen.dart';
import '../../features/trips/presentation/trips_hub_screen.dart';
import '../../features/trips/presentation/trip_planner_screen.dart';
import '../../features/trips/presentation/trip_plan_detail_screen.dart';
import '../../features/trips/presentation/active_trip_screen.dart';
import '../../features/trips/presentation/saved_plans_screen.dart';
import '../../features/trips/presentation/trip_history_screen.dart';
import '../../features/rankings/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/friends_list_screen.dart';
import '../../features/profile/presentation/friend_profile_screen.dart';
import '../../features/profile/presentation/friend_requests_screen.dart';
import '../../features/profile/presentation/completed_trips_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/info_page_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

// ─── Navigation keys ───────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorExploreKey =
    GlobalKey<NavigatorState>(debugLabel: 'explore');
final _shellNavigatorClansKey =
    GlobalKey<NavigatorState>(debugLabel: 'clans');
final _shellNavigatorTripsKey =
    GlobalKey<NavigatorState>(debugLabel: 'trips');
final _shellNavigatorRankingsKey =
    GlobalKey<NavigatorState>(debugLabel: 'rankings');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

// ─── Router ────────────────────────────────────────────────────────────

/// The router lives behind a provider so its redirect follows the session
/// state: restoring → `/splash`, signed out → `/login`, signed in → the shell.
final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier<AuthStatus>(ref.read(authStatusProvider));
  ref.listen<AuthStatus>(authStatusProvider, (_, next) {
    authRefresh.value = next;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/explore',
  refreshListenable: authRefresh,
  redirect: (context, state) {
    final status = ref.read(authStatusProvider);
    final location = state.matchedLocation;

    if (status == AuthStatus.restoring) {
      return location == '/splash' ? null : '/splash';
    }
    if (status == AuthStatus.signedOut) {
      return location == '/login' ? null : '/login';
    }
    if (location == '/login' || location == '/splash') return '/explore';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Explore
        StatefulShellBranch(
          navigatorKey: _shellNavigatorExploreKey,
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const HomeMapScreen(),
            ),
          ],
        ),

        // Tab 1: Clans
        StatefulShellBranch(
          navigatorKey: _shellNavigatorClansKey,
          routes: [
            GoRoute(
              path: '/clans',
              builder: (context, state) => const ClanBrowserScreen(),
              routes: [
                GoRoute(
                  path: ':clanId',
                  builder: (context, state) => ClanDetailScreen(
                    clanId: state.pathParameters['clanId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'create',
                      builder: (context, state) => CommunityCreateScreen(
                        clanId: state.pathParameters['clanId'],
                      ),
                    ),
                    GoRoute(
                      path: 'communities/:communityId',
                      builder: (context, state) => CommunityDetailScreen(
                        communityId:
                            state.pathParameters['communityId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'chat',
                          builder: (context, state) =>
                              CommunityChatScreen(
                            communityId:
                                state.pathParameters['communityId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'members',
                          builder: (context, state) =>
                              CommunityMembersScreen(
                            communityId:
                                state.pathParameters['communityId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tab 2: Trips
        StatefulShellBranch(
          navigatorKey: _shellNavigatorTripsKey,
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsHubScreen(),
              routes: [
                GoRoute(
                  path: 'planner',
                  builder: (context, state) =>
                      const TripPlannerScreen(),
                ),
                GoRoute(
                  path: 'saved',
                  builder: (context, state) =>
                      const SavedPlansScreen(),
                ),
                GoRoute(
                  path: 'history',
                  builder: (context, state) =>
                      const TripHistoryScreen(),
                ),
                GoRoute(
                  path: ':tripId',
                  builder: (context, state) => TripPlanDetailScreen(
                    tripPlanId: state.pathParameters['tripId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'active',
                      builder: (context, state) => ActiveTripScreen(
                        tripId: state.pathParameters['tripId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Rankings
        StatefulShellBranch(
          navigatorKey: _shellNavigatorRankingsKey,
          routes: [
            GoRoute(
              path: '/rankings',
              builder: (context, state) => const LeaderboardScreen(),
            ),
          ],
        ),

        // Tab 4: Profile
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'friends',
                  builder: (context, state) =>
                      const FriendsListScreen(),
                  routes: [
                    GoRoute(
                      path: ':friendId',
                      builder: (context, state) =>
                          FriendProfileScreen(
                        userId:
                            state.pathParameters['friendId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'friend-requests',
                  builder: (context, state) =>
                      const FriendRequestsScreen(),
                ),
                GoRoute(
                  path: 'completed-trips',
                  builder: (context, state) =>
                      const CompletedTripsScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) =>
                      const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'about',
                      builder: (context, state) => InfoPageScreen.about(),
                    ),
                    GoRoute(
                      path: 'terms',
                      builder: (context, state) => InfoPageScreen.terms(),
                    ),
                    GoRoute(
                      path: 'privacy',
                      builder: (context, state) => InfoPageScreen.privacy(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  );
});

// ─── Main scaffold with bottom nav ─────────────────────────────────────

class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _MainScaffold({required this.navigationShell});

  static const _navItems = [
    SeaWaveNavItem(icon: Icons.explore_rounded, label: 'Explore'),
    SeaWaveNavItem(icon: Icons.shield_rounded, label: 'Clans'),
    SeaWaveNavItem(icon: Icons.route_rounded, label: 'Trips'),
    SeaWaveNavItem(icon: Icons.leaderboard_rounded, label: 'Rankings'),
    SeaWaveNavItem(icon: Icons.person_pin_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SeaWaveNavBar(
        currentIndex: navigationShell.currentIndex,
        items: _navItems,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
