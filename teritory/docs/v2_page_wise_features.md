# Teritory v2 — Page-Wise Feature & UI Specifications

> Complete screen-by-screen functional and UI specification for every page, modal, and component in Teritory v2.

---

## Tab 1: Explore Map (Home Screen)

### Screen: `HomeMapScreen` (Enhanced)

#### What's New in V2
- Sub-territory auto-discovery when near a main territory.
- Nearby food shelf integrated into the map viewport.
- "Who's Here Now" friend presence indicators.
- Enhanced flag pins with reaction counts.

#### UI Elements

1. **Full-Screen OpenStreetMap Canvas**
   - Midnight Oceanic (default) / Daylight toggle (carried from v1).
   - Sub-territory pins appear as smaller, semi-transparent pulse dots in a secondary color (`#38BDF8` teal) when the user is within 5 km of a main territory.
   - Friend presence beacons: If a friend has flagged within the last 2 hours and is nearby, show a green glowing ring around their pin.

2. **Top Header Bar**
   - Teritory logo + `X Friends Active` badge (carried from v1).
   - **New**: Notification bell icon with unread badge count (top-right corner).
   - Filter chips: `All`, `Friends`, `My Flags`, `Major Wonders`, **`Sub-Spots`** (new filter for nearby hidden gems).

3. **Territory Intelligence Bottom Sheet** (appears when tapping a main territory pin)
   - **Section 1**: Territory hero image, name, country, major flag badge, total community flags count.
   - **Section 2**: `🗺️ Nearby Sub-Territories` — horizontal scrollable cards showing hidden gems within 5 km.
   - **Section 3**: `🍽️ Eat Nearby` — top food/dining flags within 5 km, sorted by popularity.
   - **Section 4**: `⚙️ Gear & Services` — partner services available for this terrain type.
   - **Section 5**: `👥 Who's Here Now` — friend avatars currently flagged within 15 km.

4. **Floating Action Controls**
   - Theme toggle FAB (Oceanic / Daylight).
   - Recenter compass FAB.
   - `🚩 Flag My Teritory` primary action pill (enhanced: now shows `🏴 Start Rally` option when long-pressed).

5. **Bottom Friends Carousel** (carried from v1, enhanced)
   - Now shows a `🔴 On Trip` indicator badge if a friend is in active trip mode.

---

## Tab 2: Clans & Communities

### Screen: `ClanBrowserScreen`
**Purpose**: Discover and browse travel clans by region, interest, or popularity.

#### UI Elements
1. **Search Bar**: Search clans by name, region, or interest keyword.
2. **Category Chips**: `Nearby`, `Popular`, `Nature & Trekking`, `Heritage & Culture`, `Road Trips`, `International`.
3. **Clan Cards** (vertical scrollable list):
   - Cover image (blurred background).
   - Clan name, region tag, member count, communities count.
   - `Join Clan` / `Joined ✓` button.
4. **Create Clan FAB**: `+ Create Clan` button (bottom-right).

---

### Screen: `ClanDetailScreen`
**Purpose**: Overview of a specific clan — its communities, members, and stats.

#### UI Elements
1. **Clan Hero Header**: Cover image, clan name, region, description, member count.
2. **Chieftain & Moderators Bar**: Avatars of clan governance.
3. **Communities List**: Cards for each community within the clan:
   - Community name, description, member count, active trip plans count.
   - `Join` / `View` button.
4. **Clan Activity Feed**: Recent flags and trip completions from clan members.
5. **Create Community Button**: `+ Create Community` (available to clan members).

---

### Screen: `CommunityDetailScreen`
**Purpose**: The heart of a community — feed, trip plans, chat, and members.

#### UI Elements
1. **Community Header**: Name, description, parent clan tag, member count.
2. **Tab Bar** (scrollable horizontal):
   - `Feed` — Community activity stream (flag drops, trip completions, announcements).
   - `Trip Plans` — List of proposed trip plans with vote counts.
   - `Members` — Member list with roles and invite button.
   - `Chat` — Community group chat.
3. **Feed Tab**: Social cards with flag drops, trip completions, trail notes from community members.
4. **Trip Plans Tab**:
   - List of trip plans with: Route summary line, waypoint count, creator name, vote score.
   - `+ Create Trip Plan` FAB.
   - **Vote buttons**: ⬆️ Upvote / ⬇️ Downvote on each plan.
   - **Winning plan** highlighted with gold crown badge.
5. **Members Tab**: Avatar list with roles (Creator, Moderator, Member). `Invite Friends` button.
6. **Chat Tab**: Real-time group chat with text messages.

---

### Screen: `CommunityCreateScreen`
**Purpose**: Create a new community within a clan.

#### UI Elements
1. Community name input.
2. Description textarea.
3. Cover image upload.
4. Interest tags (multi-select chips).
5. Privacy toggle: `Public` (any clan member joins) / `Invite Only`.
6. `Create Community` button.

---

## Tab 3: Trips

### Screen: `TripPlannerScreen`
**Purpose**: Build a waypoint-based trip plan using the Teritory flag database.

#### UI Elements
1. **Origin & Destination Input**: Two location search bars with autocomplete.
2. **Interactive Route Map**: Shows the straight-line corridor between origin and destination with flagged spots rendered as selectable waypoint pins.
3. **Waypoint Suggestion Panel** (scrollable left sidebar or bottom sheet):
   - Ranked by: Flag density, Major Flag status, Category match, Friend recommendations.
   - Each suggestion: Place name, flag count, category icon, distance from route, `+ Add` button.
4. **Active Waypoint List** (ordered): Drag-to-reorder, swipe-to-remove.
5. **Trip Details Form**:
   - Trip name, description.
   - Estimated duration (auto-calculated from waypoints).
   - Date range picker.
   - Gear suggestions (auto-populated based on waypoint terrain).
6. **Action Bar**: `Save to My Plans` / `Share to Community`.

---

### Screen: `TripPlanDetailScreen`
**Purpose**: View a full trip plan — waypoints, map route, gear, and stats.

#### UI Elements
1. **Route Map**: Polyline connecting all waypoints with numbered markers.
2. **Waypoint Timeline**: Vertical list of ordered stops with:
   - Stop number, place name, estimated arrival.
   - Distance/time from previous stop.
   - Category and terrain tags.
3. **Trip Stats Card**: Total distance, estimated hours, waypoints count, terrain types.
4. **Gear Recommendations**: Based on waypoint terrain (forest → tent, mountain → trekking poles).
5. **Actions**: `Start Trip` / `Fork & Customize` / `Vote` (if in community context).

---

### Screen: `ActiveTripScreen`
**Purpose**: Live trip execution mode with GPS tracking and waypoint validation.

#### UI Elements
1. **Full-Screen Map** with trip route polyline.
2. **Current Position Beacon** with heading indicator.
3. **Upcoming Waypoint Card** (bottom): Name, distance, ETA, `Flag This Stop` button.
4. **Trip Progress Bar**: X of Y waypoints validated.
5. **Participant Sidebar** (for community trips): Friend avatars on the map showing their real-time positions.
6. **15 km Radius Ring**: Visual circle around each waypoint showing the validation zone.
7. **Trip Complete Celebration**: Full-screen confetti + Trip Completion Card when all waypoints flagged.

---

### Screen: `SavedPlansScreen`
**Purpose**: Personal library of saved and forked trip plans.

#### UI Elements
1. **Plan Cards**: Trip name, route summary, waypoint count, source (personal / community name).
2. **Actions**: `View`, `Edit/Fork`, `Start Trip`, `Share`, `Delete`.
3. **Sort/Filter**: By date saved, by distance, by waypoint count.

---

### Screen: `TripHistoryScreen`
**Purpose**: Archive of all completed and incomplete trips.

#### UI Elements
1. **Completed Trips** section: Green checkmark, route thumbnail, date, participants, trip badge.
2. **Incomplete Trips** section: Red cross, route thumbnail, missing waypoints highlighted.
3. **Trip Detail Expand**: Tap to see full route map, validated waypoints, duration, and trip story (if written).

---

## Tab 4: Rankings & Leaderboards

### Screen: `LeaderboardScreen`
**Purpose**: Multi-scope competitive benchmarking.

#### UI Elements
1. **Scope Selector Pills**: `🌍 Global`, `🇮🇳 Country`, `State`, `District`, `👥 Friends`, `🏕️ Clan`, `🧭 Community`.
2. **Time Filter**: `All Time`, `This Month`, `This Week`.
3. **Top 3 Podium**: Large avatar cards with rank 1 (gold), 2 (silver), 3 (bronze) badges, score, and key stats.
4. **Ranked List**: Scrollable list with:
   - Rank number, avatar, name, composite score.
   - Key stat badges (flags, major flags, trips completed).
5. **My Rank Card**: Floating card at bottom showing user's own rank, score, and nearest competitor.
6. **Score Breakdown** (expandable): Tap to see the weighted parameter breakdown for any user.

---

## Tab 5: Profile (Enhanced)

### Screen: `ProfileScreen` (Enhanced)
**Purpose**: Personal travel portfolio with trip profiling, friends, and clan membership.

#### New V2 Sections (added to existing v1 profile layout)
1. **Trip Profiling Section** (new):
   - `🧭 Active Trip` banner (if in trip mode): Trip name, progress, destination.
   - `✅ Completed Trips (X)`: Horizontal shelf of trip completion cards.
   - Each card: Trip name, route thumbnail, date, distance, participants count, badge.
2. **Friends Section** (new):
   - `👥 Friends (X)` header with `View All` link.
   - Horizontal avatar row of closest friends.
   - Tap any avatar → Navigate to `FriendProfileScreen`.
3. **Clans & Communities Section** (new):
   - List of joined clans and communities with badges.
4. **Legendary Rally Badges** (new):
   - Golden-rimmed rally flag badges with participant counts.
5. **Leaderboard Rank Summary** (new):
   - Compact card showing: Global rank, country rank, friend circle rank.

---

### Screen: `FriendsListScreen`
**Purpose**: Full friends list with search, categories, and management.

#### UI Elements
1. **Search Bar**: Search friends by name or handle.
2. **Category Tabs**: `All`, `Favorites`, `Travel Buddies`, `Family`.
3. **Friend Cards**: Avatar, name, handle, mutual friends count, last active.
4. **Actions**: `View Profile`, `Remove`, `Invite to Community`.
5. **Pending Requests Badge**: `X Pending` button → navigates to `FriendRequestsScreen`.

---

### Screen: `FriendProfileScreen`
**Purpose**: View a friend's complete travel portfolio.

#### UI Elements
1. **Profile Header**: Avatar, name, handle, bio, nomad rank, add/remove friend button.
2. **Stats Row**: Total flags, major flags, countries, continents, completed trips.
3. **Worldwide Flag Map**: Same map viewport as personal profile, but showing the friend's flags.
4. **Trip Profiling**: Completed trips list with route summaries.
5. **Legendary Rally Badges**: Shared rally flags.
6. **Actions**: `Invite to Community`, `Invite to Trip`, `Send Message`.

---

## Modals & Sheets

### `LegendaryRallySheet`
- Rally name input, time window selector, invite type (Community / Friends / Open).
- Participant roster with live join status.
- `🏴 Drop Rally Flag` button (enabled when ≥2 participants confirmed within 500m).

### `InviteFriendsSheet`
- Multi-select friend picker with avatar, name, and checkboxes.
- Context label: "Invite to [Community Name]" or "Invite to [Trip Name]".
- `Send Invites` button with count badge.

### `GearServiceSheet`
- Service provider card: Name, service type, price range, rating stars, distance.
- `Book Now` deep link button.
- Gallery of service photos.

### `TripCompletionCard`
- Full-screen celebration modal.
- Route map thumbnail with all validated waypoints.
- Stats: Duration, distance, waypoints, participants.
- `Share to Feed` / `Write Trip Story` / `Done` buttons.

---

> **Document Version**: 2.0.0-plan  
> **Created**: 2026-11-15  
> **Status**: Page-wise feature spec — Ready for Design Phase

