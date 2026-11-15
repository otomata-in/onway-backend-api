# Teritory v2 — Master Upgrade Plan

> **From Solo Flagging to Full Expedition Command Platform**
> _"Your Map. Your Crew. Your Expedition."_

---

## Executive Summary

Teritory v1 delivered a solid interactive prototype: a map-first Flutter app where solo users drop flags, view friend pins, and browse a static wonders catalog. All data is hardcoded JSON with zero backend, zero auth, zero social graph, and zero trip orchestration.

**Teritory v2** transforms the platform from a solo flag-dropping showcase into a **complete travel expedition lifecycle engine** — from discovering nearby hidden gems and food spots, to forming clans, planning collaborative waypoint-based trips, executing live expeditions with GPS validation, renting gear from local partners, and climbing global leaderboards.

---

## V1 Audit — What Exists Today

| Component | V1 Status | V2 Requirement |
|:---|:---|:---|
| **Data Source** | Static JSON (`teritory_data.json`) | Real-time backend API + Spatial DB |
| **Authentication** | None — single hardcoded user | Full auth (OAuth / OTP / Social login) |
| **Social Graph** | None — friend names from JSON | Friend requests, friend lists, profiles |
| **Community** | Static tribe cards (join/leave toggle) | Clans → Communities → Trip Plans → Votes |
| **Trip Planning** | None | Waypoint route builder with flag-based suggestions |
| **Trip Execution** | None | Live trip mode with GPS validation |
| **Nearby Discovery** | None | Proximity radar for food, hidden spots, sub-territories |
| **Gear & Services** | None | Partner marketplace integration |
| **Leaderboards** | None | Multi-scope rankings (global to friend circle) |
| **Group Flagging** | None | Legendary Rally Flag with multi-user ceremony |
| **Models** | 6 models (FlagItem, FriendFlag, PassportStamp, UserStats, CurrentUserProfile, MajorWonder, TravelTribe) | 20+ models with relationships |
| **Screens** | 4 screens + 2 modals | 15+ screens + 8+ modals/sheets |
| **Navigation** | 4-tab bottom nav | 5-tab bottom nav + nested page navigation |

---

## V2 Feature Architecture — Complete Breakdown

---

### Module 1: Territory Proximity Radar & Nearby Discovery

#### 1.1 Sub-Territory Discovery
When a user enters a **main territory** (a famous location with high flag density), the map automatically reveals **sub-territories** — nearby lesser-known spots flagged by other travelers within a configurable radius (default: 5 km).

- **Visual**: Sub-territory pins appear as smaller, semi-transparent pulse markers with a `"Discovered by X travelers"` tag.
- **Data Source**: Spatial query — all flags by all users within radius of the main territory, ranked by flag count and recency.
- **Filter**: `Hidden Gems Only` (< 50 flags), `Popular Nearby` (50+ flags), `Food & Dining`, `Viewpoints`, `Camping`.

#### 1.2 Nearby Food Spots
When inside or approaching a major territory, surface curated nearby food & dining flags dropped by other travelers.

- **UI**: Horizontal scrollable "🍽️ Eat Nearby" card shelf below the main territory detail sheet.
- **Categories**: `Street Food`, `Local Cuisine`, `Cafes`, `Restaurants`, `Highway Stops`.
- **Sorting**: By flag count (popularity), by recency, by distance.

#### 1.3 Territory Intelligence Sheet
When tapping a main territory pin, the detail sheet expands to show:
- Core territory info (name, photos, flag count, major status).
- **"Nearby Sub-Territories"** carousel — hidden viewpoints discovered by travelers.
- **"Eat Nearby"** shelf — top-flagged food spots within 5 km.
- **"Gear & Services"** shelf — available partner services for the area (see Module 8).
- **"Who's Here Now"** — friends or community members currently flagged within 15 km.

---

### Module 2: Travel Community Interaction System

#### 2.1 Interaction Methods
Introduce structured ways for travelers to interact within the platform:

| Method | Description |
|:---|:---|
| **Flag Kudos** | Quick appreciation on any flag (existing in v1, enhanced with reaction types: 🔥 Epic, 💎 Hidden Gem, 📸 Great Shot) |
| **Flag Comments** | Threaded text comments on any flag with @mentions |
| **Trip Stories** | Short-form travel stories (text + 5 photos max) attached to a trip completion |
| **Trail Notes** | Geocached tips visible only to travelers who reach the same spot |
| **Direct Messaging** | 1-to-1 chat between friends |
| **Community Chat** | Group chat within a community |
| **Activity Reactions** | React to friend activity feed items |

#### 2.2 Notification System
- Push notifications for: Friend flag drops nearby, community trip invitations, trip vote results, kudos received, clan invitations, leaderboard rank changes.
- In-app notification bell with badge count.

---

### Module 3: Clans, Communities & Trip Planning

This is the largest new module. It introduces a **three-tier social hierarchy**:

```
Clan (Regional Travel Hub)
  └── Community (Focused Travel Group)
        └── Trip Plan (Collaborative Itinerary)
              └── Trip Execution (Live GPS-Validated Expedition)
```

#### 3.1 Travel Clans
A **Clan** is a regional or interest-based travel hub — the broadest container.

- **Examples**: `Kerala Explorers Clan`, `Himalayan Trekkers Clan`, `European Backpackers Clan`.
- **Properties**: Name, cover image, region/interest tag, description, member count, communities count.
- **Membership**: Any user can browse and join public clans. Private clans require an invite from an existing member.
- **Governance**: Clan has a creator (Chieftain) and optional moderators.
- **Discovery**: Clans surfaced on the Community tab, searchable by region, interest, or name.

#### 3.2 Travel Communities
A **Community** lives inside a Clan. It is a focused group around a specific travel theme or destination.

- **Examples**: Inside `Kerala Explorers Clan` → `Wayanad Weekenders`, `Coastal Route Riders`, `Monsoon Trekkers`.
- **Properties**: Name, description, parent clan, member list, trip plans list, activity feed.
- **Creation**: Any clan member can create a community within their clan.
- **Membership**: Any clan member can join any community within that clan freely. Users outside the clan require a direct friend invite to join a community.
- **Features**: Community-level activity feed, shared trip plans, community chat, shared flag map overlay.

#### 3.3 Trip Planning Engine (Flag-Based Waypoint Router)
The core innovation of v2. Users leverage the **entire Teritory flag database** to build optimized travel plans.

##### Trip Plan Creation Flow:
1. **Set Origin & Destination**: E.g., `Palakkad → Kanyakumari`.
2. **Smart Waypoint Suggestions**: Teritory queries all flags along the route corridor (configurable width: 10-50 km from the straight line) and ranks them by:
   - Flag density (most-flagged spots).
   - Major Flag status (UNESCO / landmark priority).
   - Category match (user preferences: Nature, Food, Heritage, Viewpoints).
   - Friend flags (spots your friends have flagged and recommended).
3. **Interactive Waypoint Builder**: User sees a map with suggested stops rendered as selectable pins. They tap to add/remove waypoints, reorder stops, and adjust the route.
4. **Plan Details**:
   - Trip name, description, estimated duration.
   - List of ordered waypoints with expected arrival/departure times.
   - Accommodation suggestions near each waypoint.
   - Estimated distance and travel time between each leg.
   - Gear recommendations based on terrain and weather of waypoints.
5. **Save & Share**: Plan is saved to the community.

##### Community Trip Voting:
- Any community member can create a trip plan.
- Members can create **multiple alternative plans** for the same trip goal.
- The community votes on the best plan (upvote/downvote).
- Winning plan gets promoted to **"Official Community Trip"** status.

##### Personal Trip Plan Library:
- Users can save any community trip plan to their **personal Saved Plans** list.
- They can fork and customize saved plans (adjust waypoints, dates, duration).
- Personal plans can be shared to any community or sent to friends.

---

### Module 4: Friends & Social Graph

#### 4.1 Friend System
- **Add Friend**: Search by handle/name, send friend request, accept/decline.
- **Friend List**: Dedicated friends list in the Profile section with search, categorization (favorites, travel buddies, family).
- **Friend Profile View**: When viewing a friend's profile, see their:
  - Flag world map and statistics (existing v1 profile adapted for public viewing).
  - **Completed Trips** section (trip history with dates, routes, photos).
  - **Active Trips** (if they're currently in trip mode).
  - Mutual friends count.
  - Mutual communities/clans.
  - Option to invite to a community or a trip.

#### 4.2 Friend Invite to Community
- From any community screen → `Invite Friends` button.
- Shows friend list with checkboxes for multi-select invite.
- Friends receive notification with community preview and one-tap join.

#### 4.3 Friend Profile Enhancements
- **Trip Profiling Section**: Completed trips listed chronologically with:
  - Trip name, route summary, waypoints visited.
  - Trip completion badge (fully completed vs partially completed).
  - Group participants (if it was a community trip).
  - Trip duration and total distance.
- **Activity Heatmap**: Calendar view showing travel activity intensity.

---

### Module 5: Trip Execution Mode & GPS Validation

#### 5.1 Trip Mode Activation
Users can enter **"Trip Mode"** from:
- A personal trip plan (from saved plans).
- A community-organized trip plan (after voting/approval).

##### Trip Mode UI:
- Full-screen map with the trip route rendered as a connected polyline.
- Upcoming waypoint highlighted with distance/ETA.
- Bottom sheet showing: Current waypoint info, next stop, trip progress bar.
- Live GPS tracking beacon with route deviation warnings.

#### 5.2 Community Trip Participation
- When a community trip organizer sets a trip plan as **"Active"**, all community members see a "Join This Trip" button.
- Joined members appear on the trip participant list.
- Their trip mode shows shared progress — see where other participants are on the route in real time.

#### 5.3 Trip Destination Validation (15 km Rule)
- For each waypoint in the trip, the user must **flag the destination** while physically within a **15 km radius** of the waypoint's coordinates.
- If they flag it: The waypoint is marked as ✅ **Validated** on their trip profile.
- If they do NOT flag within 15 km before the trip timeline expires:
  - The trip is marked as ❌ **Incomplete** and is erased from their public trip profiling.
  - They keep the individual flags they did drop, but lose the trip completion badge.

#### 5.4 Trip Completion & Profiling
- Upon flagging all waypoints within the timeline:
  - Trip is marked as ✅ **Completed**.
  - A **Trip Completion Card** is generated: Route map thumbnail, duration, distance, waypoints visited, group photo mosaic.
  - Trip appears permanently on the user's profile under **"Completed Trips"**.
  - XP and badge rewards granted.
  - Community-wide announcement: "Team X completed the Palakkad → Kanyakumari expedition!"

---

### Module 6: Legendary Rally Flagging (Group Flag Ceremony)

Instead of "Gigantic Flagging," we call it **"Legendary Rally"** — a coordinated group flagging event at a significant destination.

#### 6.1 Rally Mechanics
- **Initiation**: Any user can initiate a Legendary Rally at their current location.
  - Set rally name (e.g., "Team Summit at Munnar Peak").
  - Set rally window (e.g., "Next 4 hours").
  - Invite: Community members, friends, or open to all nearby travelers.
- **Participation**: Invited users must physically reach the rally location (within 500 meters) and tap "Join Rally" during the active window.
- **Rally Flag Drop**: When the organizer triggers the drop, all participants simultaneously stake the **Legendary Rally Flag** — a special golden-rimmed flag with all participants' avatars embedded.
- **Profile Recognition**: The Rally Flag appears as a premium badge on every participant's profile with the full participant roster.

#### 6.2 Rally Types
- **Community Rally**: Organized through a community for its members.
- **Friend Rally**: Personal invitation to friends for a private group flag.
- **Open Rally**: Broadcast to all nearby Teritory users — anyone within range can join.

---

### Module 7: Multi-Scope Leaderboards & Benchmarking

#### 7.1 Leaderboard Scopes

| Scope | Description |
|:---|:---|
| **🌍 Global** | All Teritory users worldwide |
| **🇮🇳 Country** | Users within the same country |
| **📍 State / Province** | Users within the same state |
| **🏘️ District / City** | Users within the same district |
| **👥 Friend Circle** | Only among your friends |
| **🏕️ Clan** | Within your travel clan |
| **🧭 Community** | Within a specific community |

#### 7.2 Ranking Parameters
Rankings are computed from a weighted composite score:

| Parameter | Weight | Description |
|:---|:---|:---|
| Total Flags | 15% | Raw count of all flags dropped |
| Major Flags | 25% | UNESCO / landmark flags (premium weight) |
| Countries Visited | 15% | Geographic diversity |
| Continents Explored | 10% | Continental reach |
| Completed Trips | 15% | Fully GPS-validated trip completions |
| Legendary Rallies | 10% | Group flag ceremonies participated |
| Community Contributions | 5% | Trip plans created, votes received, trail notes |
| Streak Days | 5% | Consecutive days with at least one flag |

#### 7.3 Leaderboard UI
- Dedicated leaderboard screen accessible from Community tab.
- Scope selector pills at the top (Global → Country → State → District → Friends → Clan → Community).
- Top 3 podium display with avatar, rank badge, and score.
- Scrollable ranked list below with the user's own rank highlighted.
- Time filters: `All Time`, `This Month`, `This Week`.

---

### Module 8: Travel Gear & Partner Services Marketplace

#### 8.1 Service Categories (Context-Aware)
Based on the **environment, terrain, and speciality** of the travel destination:

| Destination Type | Suggested Services |
|:---|:---|
| **Forest / Jungle Camping** | Tent rental, sleeping bag rental, mosquito nets, portable stoves, guided treks, wildlife spotting guides |
| **Mountain / Trekking** | Trekking poles, crampons, altitude sickness kits, sherpa services, oxygen canisters, base camp gear |
| **Beach / Coastal** | Surfboard rental, snorkeling gear, beach camping kits, boat charters, diving instructors |
| **Desert / Arid** | Camel safari, desert camping kits, sand boards, 4x4 rental, water purification |
| **Heritage / Urban** | Audio guides, local history tours, museum passes, photography permits, heritage walk guides |
| **Snow / Winter** | Ski gear, snowboard rental, thermal wear, snow chains, ice fishing equipment |
| **River / Waterfall** | Kayak rental, life jackets, river rafting packages, cliff jumping guides |
| **Road Trip / Highway** | Vehicle breakdown kits, portable chargers, dash cams, roadside assistance, fuel station locator |

#### 8.2 Service Showcase UI
- When viewing a territory detail sheet, a **"⚙️ Gear & Services"** section appears showing available partner services near the destination.
- Each service card shows: Provider name, service type, price range, rating, distance from territory, booking action.
- Booking opens a deep link to the partner platform (Teritory Partner Portal — to be built separately later).

#### 8.3 Teritory Partner Platform (Future)
- A separate admin/partner dashboard where service providers register, list their services, manage bookings, and receive leads from Teritory users.
- For v2, we build only the **consumer-facing showcase** with static/mock partner data. Backend integration comes in v3.

---

## V2 Navigation Architecture

### Bottom Navigation (5 Tabs)

| # | Tab | Icon | Screen |
|:---|:---|:---|:---|
| 1 | **Explore** | `explore_rounded` | Home Map with proximity radar, sub-territories, friend pins |
| 2 | **Clans** | `castle_rounded` | Clan browser, community list, trip plans, community chat |
| 3 | **Trips** | `route_rounded` | Trip planner, active trip mode, saved plans, trip history |
| 4 | **Rankings** | `leaderboard_rounded` | Multi-scope leaderboards and benchmarking |
| 5 | **Profile** | `person_pin_rounded` | Personal footprint map, stats, trips, friends, passport |

---

## V2 Screen Inventory — Complete Page List

### Explore Tab (Home Map)
1. **HomeMapScreen** (enhanced) — Full map with oceanic/daylight toggle, friend pins, sub-territory discovery, proximity food shelf.
2. **TerritoryDetailSheet** (enhanced) — Expanded bottom sheet with nearby sub-territories, food spots, gear services, and "Who's Here Now."
3. **SubTerritoryListScreen** — Full list of nearby sub-territories when expanded from the detail sheet.

### Clans Tab
4. **ClanBrowserScreen** — Discover and browse travel clans by region/interest.
5. **ClanDetailScreen** — Clan overview, member count, communities list, join/leave.
6. **CommunityDetailScreen** — Community feed, members, trip plans, community chat, invite friends.
7. **CommunityCreateScreen** — Create a new community within a clan.
8. **CommunityMembersScreen** — Full member list with roles and invite actions.
9. **CommunityChatScreen** — Group chat for community members.

### Trips Tab
10. **TripPlannerScreen** — Origin/destination input, smart waypoint suggestions, interactive map route builder.
11. **TripPlanDetailScreen** — Full trip plan view with ordered waypoints, times, distances, gear suggestions.
12. **TripVotingScreen** — Community trip plans with upvote/downvote and winner highlight.
13. **ActiveTripScreen** — Live trip mode with GPS tracking, waypoint progress, participant positions.
14. **SavedPlansScreen** — Personal library of saved/forked trip plans.
15. **TripHistoryScreen** — Completed and incomplete trip archive.

### Rankings Tab
16. **LeaderboardScreen** — Multi-scope leaderboards with podium, ranked list, and time filters.

### Profile Tab
17. **ProfileScreen** (enhanced) — Worldwide map, stats, nomad rank, passport stamps, trip profiling section.
18. **FriendsListScreen** — Search, browse, manage friends with categories.
19. **FriendProfileScreen** — View any friend's flags, trips, stats, mutual connections. Invite to community/trip.
20. **FriendRequestsScreen** — Pending incoming/outgoing friend requests.
21. **CompletedTripsScreen** — Detailed view of all completed trip profiles with route maps and participants.
22. **SettingsScreen** — Account, notifications, privacy, theme preferences.

### Modals & Sheets
23. **DropFlagModal** (enhanced) — Now supports Legendary Rally initiation.
24. **FlagDetailSheet** (enhanced) — Includes comments, reactions, nearby food/gear.
25. **LegendaryRallySheet** — Create or join a rally, view participants, trigger group flag.
26. **InviteFriendsSheet** — Multi-select friend picker for community/trip/rally invites.
27. **WaypointSuggestionSheet** — Flag-based waypoint picker during trip planning.
28. **GearServiceSheet** — Partner service detail and booking deep link.
29. **TripCompletionCard** — Post-trip celebration with stats, route map, and share actions.

---

## V2 Data Model Architecture

### New Models Required

```
User (auth profile)
├── UserProfile (public profile, nomad rank, stats)
├── FriendRelationship (userId, friendId, status, since)
├── UserFlag (enhanced with reactions, comments)
│
Clan
├── ClanMember (userId, role, joinedAt)
├── Community
│   ├── CommunityMember (userId, role)
│   ├── CommunityChat (messages)
│   ├── TripPlan
│   │   ├── TripWaypoint (ordered, coordinates, category, estimatedArrival)
│   │   ├── TripVote (userId, direction)
│   │   └── TripGearSuggestion (serviceId, category)
│   └── CommunityActivity (feed items)
│
Trip (execution instance)
├── TripParticipant (userId, joinedAt, status)
├── TripWaypointValidation (waypointId, userId, flaggedAt, isWithinRadius)
└── TripCompletion (userId, completedAt, badge, stats)
│
LegendaryRally
├── RallyParticipant (userId, joinedAt, location)
└── RallyFlag (shared flag with participant roster)
│
PartnerService
├── ServiceProvider (name, contact, region)
└── ServiceListing (type, price, rating, coordinates)
│
Leaderboard
└── LeaderboardEntry (userId, scope, score, rank, period)
│
Notification
└── NotificationItem (type, content, targetId, read, timestamp)
```

---

## V2 Backend Requirements (High-Level)

| Service | Technology | Purpose |
|:---|:---|:---|
| **Auth** | Better Auth / Firebase Auth / Neon Auth | User registration, login, session management |
| **Spatial Database** | Neon Postgres + PostGIS | Flag storage, proximity queries, route corridor searches |
| **Real-time** | WebSocket / Neon Realtime | Live trip tracking, chat, friend activity, rally coordination |
| **Object Storage** | Neon Object Storage / S3 | Photo uploads for flags, trip stories, avatars |
| **Push Notifications** | Firebase Cloud Messaging | Trip invites, rally alerts, friend requests, leaderboard changes |
| **API Backend** | Node.js / Neon Functions | REST + WebSocket API for all client operations |
| **Caching** | Redis / Upstash | Leaderboard scores, session tokens, rate limiting |

---

## V2 Development Phases

### Phase 2A: Foundation & Social Graph (Weeks 1-4)
- User auth and profile management.
- Friend system (add, accept, decline, list, search).
- Enhanced flag model with comments and reactions.
- Backend API scaffold and database schema.

### Phase 2B: Clans & Communities (Weeks 5-8)
- Clan CRUD, browsing, and membership.
- Community creation, membership (clan-based free join + friend invite).
- Community activity feed and chat.
- Notification system.

### Phase 2C: Trip Planning & Execution (Weeks 9-14)
- Trip plan creator with flag-based waypoint suggestions.
- Community trip voting.
- Personal saved plans library.
- Active trip mode with live GPS tracking and 15 km validation.
- Trip completion profiling and badges.

### Phase 2D: Discovery, Services & Rankings (Weeks 15-18)
- Sub-territory proximity radar.
- Nearby food and hidden gem discovery.
- Partner gear/services showcase (static data first).
- Multi-scope leaderboards with composite scoring.
- Legendary Rally flagging system.

### Phase 2E: Polish, Optimization & Launch (Weeks 19-20)
- Performance optimization (map rendering, spatial queries).
- Offline caching for trip plans and maps.
- Comprehensive testing.
- Release APK build and deployment.

---

## V2 Key Naming Conventions

| V1 Term | V2 Term | Reason |
|:---|:---|:---|
| Travel Tribe | **Community** | More universal, less jargon |
| (none) | **Clan** | Parent container for communities |
| (none) | **Trip Plan** | Structured waypoint itinerary |
| (none) | **Trip Mode** | Live expedition execution |
| Gigantic Flagging | **Legendary Rally** | Premium, aspirational naming |
| (none) | **Sub-Territory** | Nearby discovered spots |
| (none) | **Trail Note** | Geocached traveler tips |
| (none) | **Rally Flag** | Group ceremony flag |

---

> **Document Version**: 2.0.0-plan  
> **Created**: 2026-11-15  
> **Status**: Master Plan — Ready for Review  
> **Next Step**: Review, finalize, begin Phase 2A backend + auth scaffolding

