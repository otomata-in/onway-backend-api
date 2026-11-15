# Teritory v2 — UI/UX Design System & Technical Architecture

---

## 1. Design Token Additions (V2)

Building on the v1 palette, v2 adds tokens for new components:

### New Color Tokens
| Token | Hex | Usage |
|:---|:---|:---|
| `clanPurple` | `#8B5CF6` | Clan badges, clan headers |
| `communityIndigo` | `#6366F1` | Community accent, community chips |
| `tripRoute` | `#22D3EE` | Trip polyline on map, active trip indicators |
| `rallyGold` | `#FBBF24` | Legendary Rally flag rim, rally badges |
| `validatedGreen` | `#10B981` | Waypoint validated checkmark, trip complete |
| `expiredRed` | `#EF4444` | Trip expired, waypoint missed, incomplete |
| `gearAmber` | `#F59E0B` | Gear/service marketplace cards |
| `chatBubbleSelf` | `#1E293B` | User's own chat bubble |
| `chatBubbleOther` | `#F1F5F9` | Other user's chat bubble |
| `subTerritoryTeal` | `#38BDF8` | Sub-territory discovery pins |
| `foodOrange` | `#FB923C` | Nearby food spot indicators |

### New Icon Conventions
| Feature | Icon | Color |
|:---|:---|:---|
| Clan | `castle_rounded` | `clanPurple` |
| Community | `groups_3_rounded` | `communityIndigo` |
| Trip | `route_rounded` | `tripRoute` |
| Rally | `flag_circle_rounded` | `rallyGold` |
| Gear | `handyman_rounded` | `gearAmber` |
| Leaderboard | `leaderboard_rounded` | `majorGold` |
| Sub-territory | `pin_drop_rounded` | `subTerritoryTeal` |
| Food | `restaurant_rounded` | `foodOrange` |

---

## 2. Navigation Architecture (V2)

### Bottom Navigation (5 Tabs)
```
MainNavigationShell (IndexedStack, 5 tabs)
├── Tab 0: ExploreMapScreen (Home)
├── Tab 1: ClanBrowserScreen (Clans & Communities)
├── Tab 2: TripsHubScreen (Trip Plans & Execution)
├── Tab 3: LeaderboardScreen (Rankings)
└── Tab 4: ProfileScreen (Enhanced)
```

### Nested Navigation
Each tab uses its own `Navigator` for push/pop within the tab:

```
Tab 1 (Clans):
  ClanBrowserScreen
    → ClanDetailScreen
      → CommunityDetailScreen
        → CommunityCreateScreen
        → CommunityChatScreen
        → CommunityMembersScreen
        → TripPlanDetailScreen

Tab 2 (Trips):
  TripsHubScreen (tabs: Active / My Plans / History)
    → TripPlannerScreen
    → TripPlanDetailScreen
    → ActiveTripScreen
    → SavedPlansScreen
    → TripHistoryScreen

Tab 4 (Profile):
  ProfileScreen
    → FriendsListScreen
      → FriendProfileScreen
    → FriendRequestsScreen
    → CompletedTripsScreen
    → SettingsScreen
```

---

## 3. Data Architecture (V2)

### V1 → V2 Model Evolution

```
V1 Models (6):                    V2 Models (20+):
──────────────                    ────────────────
FlagItem                     →    FlagItem (+ reactions, comments, subTerritory tag)
FriendFlag                   →    FlagItem (unified, author field)
PassportStamp                →    PassportStamp (unchanged)
UserStats                    →    UserStats (+ completedTrips, rallies, streak)
CurrentUserProfile           →    UserProfile (+ friendIds, clanIds, communityIds)
MajorWonder                  →    MajorWonder (+ nearbyServiceIds)
TravelTribe                  →    (deprecated → Clan + Community)

NEW:
  - Clan
  - ClanMember
  - Community
  - CommunityMember
  - CommunityMessage
  - TripPlan
  - TripWaypoint
  - TripVote
  - Trip (execution instance)
  - TripParticipant
  - TripWaypointValidation
  - TripCompletion
  - LegendaryRally
  - RallyParticipant
  - FriendRelationship
  - PartnerService
  - ServiceProvider
  - LeaderboardEntry
  - Notification
  - FlagComment
  - FlagReaction
```

### State Management (V2)
V1 uses a single `TeritoryDataService` singleton with `ChangeNotifier`. V2 should evolve to:

- **Recommended**: `Riverpod` for scalable, testable, provider-based state management.
- **Alternative**: `Bloc/Cubit` for strict separation of events and states.

Each module gets its own set of providers/blocs:
- `AuthProvider` — Login state, current user, tokens.
- `FlagProvider` — Flag CRUD, reactions, comments, nearby queries.
- `SocialProvider` — Friends, friend requests, friend profiles.
- `ClanProvider` — Clan browse, join, create.
- `CommunityProvider` — Community CRUD, membership, feed, chat.
- `TripProvider` — Trip plans, voting, active trip mode, validation.
- `LeaderboardProvider` — Multi-scope ranking queries.
- `NotificationProvider` — Push and in-app notification state.
- `ServiceProvider` — Partner gear/service listings.

---

## 4. API Contract (V2 Backend Endpoints — High Level)

### Auth
- `POST /auth/register` — Register with email/phone
- `POST /auth/login` — Login, receive JWT
- `POST /auth/refresh` — Refresh token

### Users & Friends
- `GET /users/:id/profile` — Public profile
- `POST /friends/request` — Send friend request
- `POST /friends/accept` — Accept request
- `GET /friends` — List friends
- `DELETE /friends/:id` — Remove friend

### Flags
- `POST /flags` — Create flag (with GPS validation)
- `GET /flags/nearby?lat=&lng=&radius=` — Proximity search
- `GET /flags/corridor?fromLat=&fromLng=&toLat=&toLng=&width=` — Route corridor search
- `POST /flags/:id/reactions` — Add reaction
- `POST /flags/:id/comments` — Add comment

### Clans & Communities
- `GET /clans` — Browse clans
- `POST /clans` — Create clan
- `POST /clans/:id/join` — Join clan
- `GET /clans/:id/communities` — List communities in clan
- `POST /communities` — Create community (within a clan)
- `POST /communities/:id/join` — Join community
- `POST /communities/:id/invite` — Invite friend
- `GET /communities/:id/feed` — Activity feed
- `WebSocket /communities/:id/chat` — Real-time chat

### Trips
- `POST /trips/plans` — Create trip plan
- `GET /trips/plans/suggestions?from=&to=&width=` — Waypoint suggestions from flag DB
- `POST /trips/plans/:id/vote` — Vote on a plan
- `POST /trips/start` — Start trip execution mode
- `POST /trips/:id/validate` — Validate waypoint (GPS check)
- `GET /trips/:id/participants` — Live participant positions
- `GET /trips/history` — User's completed/incomplete trips

### Rallies
- `POST /rallies` — Create Legendary Rally
- `POST /rallies/:id/join` — Join rally
- `POST /rallies/:id/drop` — Trigger group flag drop

### Leaderboards
- `GET /leaderboards?scope=global|country|state|district|friends|clan|community&period=alltime|month|week`

### Services
- `GET /services/nearby?lat=&lng=&radius=&terrain=` — Partner services near location

---

## 5. Spatial Query Architecture

### Sub-Territory Discovery
```sql
SELECT f.*, COUNT(*) as flag_count
FROM flags f
WHERE ST_DWithin(
  f.coordinates::geography,
  ST_MakePoint(:lng, :lat)::geography,
  5000  -- 5 km radius
)
AND f.id != :mainTerritoryFlagId
GROUP BY f.place_name, f.coordinates
ORDER BY flag_count DESC
LIMIT 20;
```

### Trip Waypoint Corridor Search
```sql
SELECT f.*, COUNT(*) as popularity
FROM flags f
WHERE ST_DWithin(
  f.coordinates::geography,
  ST_MakeLine(
    ST_MakePoint(:fromLng, :fromLat),
    ST_MakePoint(:toLng, :toLat)
  )::geography,
  :corridorWidth  -- 10-50 km configurable
)
GROUP BY f.place_name, f.coordinates
ORDER BY popularity DESC, f.is_major_flag DESC;
```

### 15 km Trip Validation
```sql
SELECT ST_DWithin(
  ST_MakePoint(:userLng, :userLat)::geography,
  ST_MakePoint(:waypointLng, :waypointLat)::geography,
  15000  -- 15 km radius
) as is_valid;
```

---

## 6. Leaderboard Scoring Formula

```
Score = (totalFlags × 0.15) +
        (majorFlags × 0.25) +
        (countriesVisited × 0.15) +
        (continentsExplored × 0.10) +
        (completedTrips × 0.15) +
        (legendaryRallies × 0.10) +
        (communityContributions × 0.05) +
        (streakDays × 0.05)
```

Each parameter is normalized to a 0-1000 scale before weighting.

---

> **Document Version**: 2.0.0-plan  
> **Created**: 2026-11-15  
> **Status**: Technical architecture spec — Ready for Development

