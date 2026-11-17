# Teritory — UI ↔ API Integration Analysis & Page-by-Page Rollout

> **Status**: living document
> **Created**: 16 Nov 2026
> **Last update**: 17 Nov 2026 — profile/social pages committed (`93c697c`); see `remaining_api_integration_plan.md` for what is left
> **Scope**: `teritory/` (Flutter app) · `teritory-api/` (Node 22 + Express + Prisma)
> **Method**: source inspection of all 50 Dart files and the full backend; `flutter analyze`
> after each increment. Runtime smoke tests are listed per page.

---

## 1. Executive summary

- The app has **28 UI surfaces**: 5 tabs, 12 routed sub-screens, 4 modal sheets,
  2 dialogs, 2 orphan screens.
- The backend exposes **66 REST endpoints** and **9 socket events**.
- Before this rollout, screens exercised only ~17 endpoints, and **every repository call
  silently fell back to `MockDataService` on error or empty payload**, so live and fake
  data were indistinguishable.
- Three data planes existed side by side:
  1. live REST (`TeritoryRepository` → `teritory-api`),
  2. mock repository (`MockDataService`, 1609 lines),
  3. bundled asset JSON (`assets/data/teritory_data.json` → `TeritoryDataService`).
- Page integration strategy: migrate one page at a time to **live-only data with honest
  loading / empty / error states**, and never mix mock rows into a migrated page.

---

## 2. Architecture as implemented (before Page 1)

| Layer | Implementation | Consequence |
|---|---|---|
| Auth | `auth_provider.dart` auto-logged in with hard-coded `+919876543210` / `12345` | no OTP/login/logout UI |
| Token | access token in `SharedPreferences` | refresh token unused; 7-day cliff |
| HTTP | `api_service.dart` unwraps `body['data']`, 15 s timeout | no retry/refresh |
| Repository | 20 methods; `try/catch` → mock fallback | failures invisible |
| State | Riverpod providers seeded with mock, replaced asynchronously | mock flash, no error UI |
| Realtime | Socket.IO: room join + `new_message` consumed | typing/telemetry unused |
| Routing | `go_router` shell with 5 branches | several routes have no inbound link |

### 2.1 The "honest data" convention (introduced with Page 1)

1. **New integrations never fall back to mock.** Repository methods used by a migrated
   page let `ApiException` propagate.
2. **Providers expose `AsyncValue`** (`AsyncNotifier` / `FutureProvider`), not a
   pre-seeded fake list.
3. **Every migrated page must render three states**: loading progress, empty state,
   error with a retry action.
4. **Mutations refresh or invalidate the exact provider** that owns the data, and surface
   the server error message on failure.
5. Mock/asset providers are deleted for a page as soon as all its surfaces are migrated —
   keeping both alive is what produced the "everything looks fine" bug class.

---

## 3. Page inventory and status

Legend: `LIVE` wired and correct · `PARTIAL` wired but broken/incomplete · `MOCK` mock or
asset data · `MISSING` no API / no UI · `UNREACHABLE` no inbound navigation.

| # | Page / surface | File | Data today | Target phase |
|---|---|---|---|---|
| 1 | Explore map + flag detail | `home_map_screen.dart`, `drop_flag_modal.dart`, `live_flag_detail_sheet.dart` | **LIVE (migrated)** | done |
| 2 | Clans browser | `clan_browser_screen.dart` | **LIVE (migrated)** | done |
| 3 | Clan detail | `clan_detail_screen.dart` | **LIVE (migrated)** | done |
| 4 | Create community | `community_create_screen.dart` | LIVE | phase 2 |
| 5 | Community detail (4 tabs) | `community_detail_screen.dart` | **LIVE (migrated)** | done |
| 6 | Community chat | `community_chat_screen.dart` | **LIVE (migrated)** | done |
| 7 | Community members | `community_members_screen.dart` | **LIVE (migrated)** | done |
| 8 | Trips hub | `trips_hub_screen.dart` | **LIVE (migrated)** | done |
| 9 | Trip planner | `trip_planner_screen.dart` | PARTIAL | phase 4 |
| 10 | Trip plan detail | `trip_plan_detail_screen.dart` | **LIVE (migrated)** | done |
| 11 | Active trip | `active_trip_screen.dart` | **LIVE (migrated)**, validation needs a live position | done |
| 12 | Saved plans | `saved_plans_screen.dart` | **LIVE (migrated)**, route `/trips/saved` | done |
| 13 | Trip history / completed trips | `trip_history_screen.dart`, `completed_trips_screen.dart` | **LIVE (migrated)** | done |
| 14 | Trip completion card | `trip_completion_card.dart` | MOCK (never shown) | phase 4 |
| 15 | Leaderboard | `leaderboard_screen.dart` | **LIVE (migrated)** | done |
| 16 | Profile | `profile_screen.dart` | **LIVE (migrated)** | done |
| 17 | Friends list | `friends_list_screen.dart` | **LIVE (migrated)** | done |
| 18 | Friend requests | `friend_requests_screen.dart` | **LIVE (migrated)** | done |
| 19 | Friend profile | `friend_profile_screen.dart` | **LIVE (migrated)** | done |
| 20 | Settings | `settings_screen.dart` | STUB (every tile "Coming soon") | phase 6 |
| 21 | Gear service sheet | `gear_service_sheet.dart` | MOCK (never opened) | phase 7 |
| 22 | Invite friends sheet | `invite_friends_sheet.dart` | PARTIAL (never opened) | phase 7 |
| 23 | Legendary rally sheet | `legendary_rally_sheet.dart` | MOCK (never opened) | phase 7 |
| 24 | Wonders catalogue | `wonders_catalog_screen.dart` | MOCK, no backend | phase 7 |
| 25 | Legacy community/tribes | `community_screen.dart` | MOCK (orphan) | delete or phase 7 |

---

## 4. Page details (findings that drive each phase)

### Phase 1 — Explore (DONE)

| Feature | Required API | Was | Now |
|---|---|---|---|
| Flags on map | `GET /flags/explore?lat&lng&radiusKm&category` | asset JSON | **live** |
| My flags filter | ownership from `userId` | asset split | **live** |
| Friends filter | `GET /users/friends` + flag `userId` | asset split | **live** (friend ids) |
| Major wonders filter | `isMajorFlag` | asset | **live** |
| Flag detail | `GET /flags/:id` | asset object | **live** |
| Reactions | `POST /flags/:id/reactions` | local set | **live** |
| Kudos | `POST /flags/:id/kudos` | local counter | **live** |
| Comments | `GET /flags/:id`, `POST /flags/:id/comments` | hard-coded | **live** |
| Drop flag | `POST /flags` | fire-and-forget | **awaited + refreshes map** |
| Wishlist | none (no model/endpoint) | fake success | explicit "not implemented" message |
| Device GPS | geolocation package | hard-coded Kochi | still centre constant (documented) |
| Reverse geocoding | external service | none | not implemented |

### Phase 2 — Clans

| Feature | Required API | Current state |
|---|---|---|
| List + search | `GET /clans?search=` | live list, search filters client-side |
| Interest/category chips | `GET /clans?interestTag=` (missing) | client-side substring |
| Nearby | clan geo columns + geo query (missing) | impossible |
| Join / leave | `POST /clans/:id/join|leave`, `GET /clans/my` | local `Set` |
| Create clan | `POST /clans` | "Coming soon" FAB |
| Detail + chieftain | `GET /clans/:id` | live via cached list |
| Community list | `GET /clans/:id/communities` | client filter of `/communities` |
| Member roster | included in `GET /clans/:id` | not rendered |
| Invite friends | `POST /users/invites {type: CLAN}` | missing |

### Phase 3 — Communities

| Feature | Required API | Current state |
|---|---|---|
| Feed | `GET /communities/:id/feed` | pure mock provider; JSON shape mismatch (`userName` vs nested `user`) |
| Trip plans | `GET /communities/:id/trip-plans` | filtered global plans; planner never sets `communityId` |
| Members | `GET /communities/:id/members` | live |
| Chat history/send | `GET|POST /communities/:id/messages` | live only on chat route; detail-tab send is fake |
| Vote | `POST /trips/plans/:id/vote` | no-op icons |
| Join / leave | `POST /communities/:id/join|leave` | no UI |
| Invite | `POST /users/invites` | snackbar |
| Realtime | socket `join_community`, `new_message`, `chat_typing` | send/receive only |
| Membership enforcement | server-side check | missing (security) |

### Phase 4 — Trips

| Feature | Required API | Current state |
|---|---|---|
| Hub active/proposed | `GET /trips/hub` | live, mock when empty |
| Start trip | `POST /trips/plans/:id/start` | no-op |
| Plan detail | `GET /trips/plans/:id` | never called |
| Save / vote | `POST /trips/plans/:id/save|vote` | live toggles, server `isSaved`/`hasVoted` |
| Validation | `POST /trips/:tripId/validate-waypoint` | live, uses `isValid`/`distanceM`/`message` |
| GPS source | device location | recorded trip position (no location plugin yet) |
| Live tracking | socket `trip_location_update` | never emitted |
| Join / complete | `POST /trips/:tripId/join|complete` | complete live; join not exposed in UI |
| History | `GET /trips/history` | live |
| Completion card | — | never triggered (complete posts, then leaves the tracker) |
| Planner geocoding/ETA | no geocoder | stops picked from live flags; distance/days computed |
### Phase 5 — Rankings

| Feature | Required API | State after migration |
|---|---|---|
| Global / Friends | `GET /rankings?scope=` | **live** |
| Country / State / District | same + geo params | **live**, values picked from live standings |
| Clan / Community | scope values + server membership aggregation | **live** (backend added) |
| Periods | server-side windowed aggregation | **live** (`WEEK` / `MONTH` / `ALLTIME`) |
| My rank + breakdown | `GET /rankings/me` | **live**, collapsible breakdown card |
| Pagination | `?page&limit` + meta | server-side only; the screen loads one page of up to 100 rows |

### Phase 6 — Profile & social

| Feature | Required API | Current state |
|---|---|---|
| Profile + stats + stamps | `GET /users/me` | asset JSON |
| Edit profile / trip mode | `PATCH /users/me`, `/trip-mode` | unused |
| Friends list | `GET /users/friends` | mock |
| Requests list | **no GET endpoint** (only POST) | mock |
| Accept / decline | `POST /users/friends/requests/:id/respond` | snackbar |
| Add friend | `POST /users/friends/request` | snackbar |
| Friend profile | `GET /users/:userId` | mock |
| Remove friend / DM | missing | snackbar / none |
| Settings actions | logout, delete, prefs | "Coming soon" |

### Phase 7 — Secondary surfaces

Gear services (`GET /services/gear`, no booking), invites (`POST /users/invites`, wrong
`targetId`), rallies (`POST /rallies`, join/arrive/complete unused), wonders (no backend),
legacy tribes screen (orphan, duplicates communities).

---

## 5. Endpoint coverage after Page 1

**Consumed by screens now**: `/auth/verify-otp`, `/users/me`, `/users/friends`,
`/users/search`, `/users/invites`, `/flags/explore`, `/flags`, `/flags/:id`,
`/flags/:id/reactions`, `/flags/:id/kudos`, `/flags/:id/comments`,
`/clans`, `/clans/:id`, `/communities`, `/communities/:id`, `/communities/:id/members`,
`/communities/:id/messages`, `/trips/hub`, `/trips/plans`, `/trips/plans/saved`,
`/trips/plans/:id/save`, `/trips/plans/:id/vote`, `/trips/:id/validate-waypoint`,
`/rankings` (scopes, geo filters, periods), `/rankings/me`, `/notifications` (fetched),
`/rallies/nearby` (fetched), `/services/gear` (fetched).

**Still unused (server-complete)**: `send-otp`, `refresh`, `logout`, `auth/me`,
`PATCH /users/me`, `trip-mode`, friends request/respond, `GET /users/:id`,
`GET /clans/my`, `POST /clans`, join/leave clan, `GET /clans/:id/communities`,
`GET /flags`, `/flags/sub-territories`, join/leave community, community feed,
community trip-plans, `GET /trips/plans`, `GET /trips/plans/:id`,
`POST /trips/plans/:id/start`, `GET /trips/history`, `GET /trips/:id`,
join/complete trip, rallies create/get/join/arrive/complete,
`GET /services/nearby-food`, notification read / read-all.

**Absent from backend but required by UI**: file upload, geocoding, directions/ETA,
plan fork, wishlist, DMs, friend removal, notification prefs, account deletion, clan
coordinates, XP/level/streak, wonders registry, community invite links,
activity-feed writes, gear booking.

---

## 6. Known defects to fix inside their phase

1. Silent mock fallback across legacy repository methods (fixed for Explore; others remain).
2. Waypoint validation response-key mismatch — **phase 4, P0**.
3. Validation submits waypoint coordinates instead of user GPS — **phase 4, P0**.
4. `validatedCount = 2` hard-coded — phase 4.
5. No start/complete trip wiring — phase 4.
6. ~~Planner sends `communityId: null`~~ — now selected from live communities (`GET /communities`).
7. Community detail chat is fake; real chat unreachable — phase 3.
8. Self-message detection hard-coded `'u1'` — phase 3 (replace with `currentUserProvider`).
9. `CommunityActivity.fromJson` shape mismatch — phase 3.
10. ~~Leaderboard `period` ignored; scopes absent~~ — fixed in phase 5 (backend windowed aggregation + clan/community scopes, live UI filters).
11. Vote toggle can remove a vote while claiming success — phase 4.
12. Refresh token unused, logout unreachable — phase 0/6.
13. Community/trip read endpoints lack membership checks; CORS `*` — backend hardening.
14. Community create falls back to `parentClanId: 'c1'` and a hard-coded cover — phase 2.

---

## 7. Rollout order and acceptance criteria

For **every** page:

- [ ] every feature maps to a named endpoint; no UI element silently fakes success;
- [ ] provider is `AsyncValue`-based and mock rows are removed for that page;
- [ ] loading, empty and error (with retry) states are rendered;
- [ ] mutations await the API, invalidate the owning provider, and show server errors;
- [ ] `flutter analyze` passes;
- [ ] runtime smoke test against `teritory-api` (documented per page).

Order: **1 Explore (done)** → 2 Clans (done) → 3 Communities (done) → 4 Trips (done) →
5 Rankings (done) → 6 Profile/social → 7 secondary surfaces; auth/session hardening
lands together with phase 2 so later phases inherit a real session.

---

## 8. Page 1 implementation log (Explore)

### 8.1 Files added

| File | Purpose |
|---|---|
| `lib/core/models/api_flag.dart` | `ApiFlag`, `ApiFlagReaction`, `ApiFlagComment`, `ApiFlagDetail` + presentation adapters |
| `lib/features/explore/application/explore_flags_provider.dart` | `exploreFlagsProvider` (flags + friend ids, live-only), `flagDetailProvider(id)` |
| `lib/features/flag/presentation/live_flag_detail_sheet.dart` | API-backed detail with reactions, kudos, comments, wishlist notice |

### 8.2 Files changed

| File | Change |
|---|---|
| `lib/core/services/teritory_repository.dart` | added `fetchExploreFlags`, `fetchFlagDetail`, `toggleFlagReaction`, `addFlagKudos`, `postFlagComment`, `fetchFriendIds` — these throw instead of falling back to mock |
| `lib/features/home/presentation/home_map_screen.dart` | `ConsumerStatefulWidget`; renders live flags, server-derived filters, friends count; loading/error/empty banners with retry; live detail sheet; refreshes after a drop |
| `lib/features/flag/presentation/drop_flag_modal.dart` | awaits `POST /flags`, shows server errors, disables the button while submitting, returns `true` on success |
| `lib/core/services/teritory_data_service.dart` | `addFlag(..., persistToBackend: false)` to avoid double-posting a flag the modal already sent |

### 8.3 Behaviour now

- The map shows only flags returned by the backend; no bundled pins.
- Filters: All (nearby 100 km), Friends (accepted friends), My Flags (own), Major Wonders.
- Drop flag → `POST /flags` → success refreshes the map; failure keeps the sheet open
  with the server message.
- Tap a pin/carousel chip → live detail: reactions toggle, kudos increments, comments
  post, all re-read after mutation.
- API down → map still renders (base tiles + retry banner), nothing is faked.
- Wishlist reports that the bucket-list API does not exist instead of pretending.

### 8.4 Verification

- `flutter pub get` → exit 0.
- `flutter analyze` → **No issues found** (exit 0).
- Live API smoke test: **not run** — `teritory-api` was not listening on `:4000` at the
  time of the change (`curl /health` returned nothing). Start the backend
  (`npm run dev` in `teritory-api`) and re-run the Explore flow to confirm the JSON
  contract behaves as modelled.

### 8.5 Known limits on this page

- Map centre is still the Kochi constant; device geolocation is a separate task
  (new dependency + permissions).
- No reverse geocoding, so the city field stays manual.
- Friends filter depends on `GET /users/friends`; if that call fails the map still loads
  flags and the Friends filter simply shows nothing.
- Pin/carousel avatars fall back to an icon when a user has no `avatarUrl`.

---

## 9. Page 2 implementation log (Clans)

### 9.1 Files added

| File | Purpose |
|---|---|
| `lib/core/models/api_clan.dart` | `ApiClanMember` (maps the nested `user` shape) and `ApiClanDetail` (clan + communities + roster) |
| `lib/features/clans/application/clans_provider.dart` | `clansProvider` (list + my memberships, live-only), `clanDetailProvider(id)` |
| `lib/features/clans/presentation/create_clan_sheet.dart` | Found-a-clan form backed by `POST /clans` |

### 9.2 Files changed

| File | Change |
|---|---|
| `lib/core/services/teritory_repository.dart` | added live-only `fetchClansLive`, `fetchClanDetail`, `fetchMyClanIds`, `joinClan`, `leaveClan`, `createClan` |
| `lib/core/models/clan_models.dart` | `Clan.copyWith` so membership changes can patch `memberCount` |
| `lib/features/clans/presentation/clan_browser_screen.dart` | `clansProvider` data, loading/error/empty states, pull-to-refresh, real Join/Leave with per-card pending state, Create Clan sheet |
| `lib/features/clans/presentation/clan_detail_screen.dart` | `clanDetailProvider`, Join/Leave (leave asks for confirmation), member roster, communities from the clan payload, stale-data retry |
| `lib/core/providers/data_providers.dart` | removed `ClansNotifier`/`clansProvider`/`clanByIdProvider` and the unused `communitiesByClanProvider` (mock-seeded duplicates) |

### 9.3 Behaviour now

- Clan list, member counts and community counts come from `GET /clans`; membership comes from `GET /clans/my`.
- Join/Leave await the API, patch the list locally (button + count), and surface the server error on failure; leaving asks for confirmation.
- Create Clan posts the real form and opens the new clan.
- Detail shows the clan, chieftain, real `communities` and the first page of `members` from `GET /clans/:id`.
- No clan surface reads `MockDataService` any more; API failure shows a retry state instead of sample clans.
- Join/Leave patches the list card immediately, then invalidates the detail payload; the header count and member roster are re-read from the server, so both screens settle on the same numbers without a manual refresh.
- Opening a clan (from the list or right after creating one) pushes the detail route, so the back button returns to the list; a deep-linked detail with no stack falls back to `/clans`. Re-tapping the active Clans tab already resets that branch to `/clans` (the shell passes `initialLocation` on a repeat tap).

### 9.4 Verification

- `flutter analyze` → **No issues found** (exit 0).
- Live API smoke test: **not run** — `teritory-api` was not listening on `:4000`.

### 9.5 Known limits on this page

- Search and category chips filter the fetched list client-side. `/clans` returns the complete list, so results are correct; `?search=`/`?region=` remain available for when the list grows.
- `Nearby` has no behaviour: the schema stores no clan coordinates.
- `GET /clans/:id` returns at most 20 members, so the roster is a preview (`memberCount` is the true total).
- Detail requests happen per open (`autoDispose`); there is no push/write-through cache between list and detail.
- The list card is patched by ±1 for instant feedback; the detail header comes from the server refetch, so it can trail the list by one request and briefly differ if other travelers join at the same moment.
- Join/Leave is disabled while membership is unknown: "Checking membership…" while `GET /clans/my` is in flight, "Membership unavailable" once it has failed. It never silently does nothing.
- Rapid double taps on a clan card are guarded, so only one detail page is pushed.

---

## 10. Page 3 implementation log (Communities)

### 10.1 Files added

| File | Purpose |
|---|---|
| `lib/features/community/application/community_detail_provider.dart` | live community detail, members, feed, trip plans, invite candidates and chat (socket + `POST`) providers |
| `lib/features/community/presentation/invite_friends_sheet.dart` | friend picker that sends real `POST /users/invites` and reports failures |

### 10.2 Files changed

| File | Change |
|---|---|
| `lib/core/services/teritory_repository.dart` | added live-only `fetchCommunityDetail`, `fetchCommunityMembersLive`, `fetchCommunityFeed`, `fetchCommunityTripPlans`, `fetchCommunityMessagesLive`, `sendCommunityMessageLive`, `joinCommunity`, `leaveCommunity`, `toggleTripPlanVote`, `fetchFriendsLive`, `sendInvites` |
| `lib/core/models/community_models.dart` | `CommunityMember.fromJson` / `CommunityActivity.fromJson` now accept the API's nested `user` and `MEMBER_JOIN`-style type names |
| `lib/features/community/presentation/community_detail_screen.dart` | all four tabs live, Join/Leave with confirmation, real vote toggle, real chat send, invite sheet, loading/error/empty per tab, avatar fallbacks |
| `lib/features/community/presentation/community_chat_screen.dart` | live `AsyncValue` messages, awaited send with error snackbar, self detection from auth instead of `'u1'` |
| `lib/features/community/presentation/community_members_screen.dart` | live members, error/empty states, invite sheet |
| `lib/features/community/presentation/community_create_screen.dart` | refreshes the clan detail instead of the deleted mock list provider; a failed create now reports an error instead of "created successfully" |
| `lib/core/providers/data_providers.dart` | removed mock-seeded community detail/members/messages/activities providers and the now-unused `tripPlansByCommunityProvider` |

### 10.3 Behaviour now

- Feed, trip plans, members and chat all read their own endpoints; no tab can fall back to sample rows.
- Each tab renders loading, empty and error-with-retry states; chat also shows a send spinner and the server's message when a send fails.
- Join/Leave posts to the API, asks for confirmation when leaving, then re-reads the detail and member list (membership is derived from the roster, so no separate endpoint is needed).
- Voting calls `POST /trips/plans/:id/vote` and refreshes the plan list; the old no-op thumbs-down is gone (the API has a single toggle).
- Invites open a friend picker and post `targetUserIds` with `type: COMMUNITY`; the old "Invite link copied!" toast is gone.
- Self-messages are detected with the signed-in user id rather than a hard-coded `'u1'`.

### 10.4 Verification

- `flutter analyze` → **No issues found** (exit 0).
- Live API smoke test: **not run** — `teritory-api` was not listening on `:4000`.

### 10.5 Known limits on this page

- `POST /communities/:id/join` and the members endpoint have no server-side membership check, so a non-member can read chat history if they call the API directly (backend hardening, not a UI bug).
- The plan vote button always renders un-voted: the list endpoint returns `voteCount` but not the caller's `hasVoted`.
- "Create Trip Plan" still reports that plan creation is unavailable; the planner does not yet accept a `communityId`.
- `CommunityCreateScreen` still falls back to `parentClanId: 'c1'` when opened without a clan id.
- The legacy `community_screen.dart` tribes page remains mock-only and unreachable from the shell.

---

## 11. Page 4 implementation log (Trips hub + history)

### 11.1 Files added

| File | Purpose |
|---|---|
| `lib/core/models/api_trip.dart` | `TripsHubSnapshot` and `TripHistoryEntry` (history rows are trips with `myBadge`, not `TripCompletion`) |
| `lib/features/trips/application/trips_provider.dart` | `tripsHubProvider` (active trip + proposed/saved plans) and `tripHistoryLiveProvider`, plus `startTrip` |

### 11.2 Files changed

| File | Change |
|---|---|
| `lib/core/services/teritory_repository.dart` | added live-only `fetchTripsHub`, `fetchTripHistory`, `startTrip` |
| `lib/core/models/trip_models.dart` | `Trip` now flattens `originName`, `destinationName`, `plannedWaypoints` and `estimatedDurationHours` from its nested `tripPlan` |
| `lib/features/trips/presentation/trips_hub_screen.dart` | live hub data, per-tab loading/error/empty states, pull-to-refresh, working Start action (POST then navigate to the active trip), avatar fallbacks, removed the fake Search/Filter actions and the dead Share button; "My Plans" renamed "Plans" because the hub returns global proposed plans |
| `lib/features/trips/presentation/trip_history_screen.dart` | live history with error/retry and `TripHistoryEntry` cards |
| `lib/features/profile/presentation/completed_trips_screen.dart` | live history, removed the fake `picsum` avatar stack and the duration field the API does not return |
| `lib/core/providers/data_providers.dart` | removed the mock `tripHistoryProvider` |

### 11.3 Verification

- `flutter analyze` → **No issues found** (exit 0).
- Live API smoke test: **not run** — `teritory-api` was not listening on `:4000`.

### 11.4 Known limits on this page

- The hub's active card shows planned waypoints, not validated ones: `GET /trips/hub` returns no per-user validation counts.
- History cards show the plan's waypoint total and distance; the API returns no validated count or duration per trip.
- Plan detail and the active-trip tracker are migrated — see 11.5, which also fixes the `isWithinRadius`/`distanceMeters` contract bug. The planner is still on the older providers.
- ~~The planner still posts `communityId: null`~~ — migrated in 11.6.

### 11.5 Plan detail + active trip

**Repository additions** (`teritory_repository.dart`): `fetchPlanDetail`, `fetchSavedPlanIds`, `togglePlanSaved`, `fetchActiveTripDetail`, `validateWaypointAt`, `completeTrip`. All let `ApiException` through; the legacy swallowing `validateWaypoint` is left for unmigrated callers but is no longer used by the tracker.

**New providers** (`trips_provider.dart`): `planDetailLiveProvider` (plan + `hasVoted`), `savedPlanIdsProvider` (bookmark ids only, so a failure there cannot hide the plan), `activeTripDetailProvider` (`GET /trips/:id` → trip, plan waypoints, this user's validations).

**Plan detail**

- Live plan via `GET /trips/plans/:id`; loading / error+retry states instead of silently falling back to mock data.
- Bookmark is a real `POST /trips/plans/:id/save` toggle with server-reported result; refreshes the saved ids and the hub.
- Vote is a single real toggle (`hasVoted` from the server drives the filled icon); the fake downvote and the "Fork & Customize" / "Share" buttons, which had no endpoint and only showed a snackbar, are gone.
- **Start Trip** awaits `POST /trips/plans/:id/start`, refreshes the hub and pushes the returned trip id; the button reports "Trip Already Active" for an active plan.

**Active trip**

- Loads `GET /trips/:tripId`: validated stops come from the user's `validations`, so the progress bar, marker ticks and "next waypoint" are real. The hard-coded `validatedCount = 2` and the invented "2.4 km away / ~15 min" are gone; distance is computed from the recorded position.
- **Contract bug fixed**: the app read `isWithinRadius` / `distanceMeters`, but the API returns `isValid` / `distanceM` / `maxAllowedMeters` / `message`. It now reads the documented keys and shows the server message, so an out-of-range stop no longer reports success.
- **Validation now sends a real position**: previously it posted the *waypoint's own* coordinates, which always passed. It now sends the traveler's recorded position and refuses to validate when none exists ("Live position unavailable") rather than claiming a GPS check.
- **Complete Trip** added: confirm dialog → `POST /trips/:tripId/complete`, then invalidates the hub and history.
- Socket room is joined in `initState` and left in `dispose` (it used to be re-joined on every build); added `SocketService.leaveTrip`.

**Verification**: `flutter analyze` clean. Live smoke test still blocked — no API on `:4000`.

### 11.6 Planner + saved plans

**Planner** (`trip_planner_screen.dart`)

- **No fake coordinates any more.** Origin and destination were pre-filled as "Munnar Town"/"Kodaikanal" with fixed lat/lng, so every plan was created at those points regardless of what the user typed. Both now come from a picker of **live flagged places** (`GET /flags/explore`, the same query the Explore map uses); the same list feeds the waypoint suggestions that used to be eight hard-coded places with invented flag counts.
- **Distance and days are computed**, not hard-coded (145 km / 3 days): route distance is the sum of segment distances between the chosen stops, and days assume ~150 km per day, stated in the UI. Both are sent to `POST /trips/plans` along with per-stop `distanceFromPrevKm`.
- **Community is a real picker** over `GET /communities` (new live-only `fetchCommunitiesLive`); "Personal plan" leaves `communityId` out. Previously it displayed a hard-coded "Munnar Trail Blazers" and always sent null.
- Saving uses a new throwing `createPlan`; a failure now shows the API message instead of reporting "Trip plan saved!" after a null result. Removed the dead Share button and the legacy `createTripPlan` it used.

**Saved plans** (`saved_plans_screen.dart`)

- Reads `GET /trips/plans/saved` through `savedPlansLiveProvider` with loading / error+retry / empty / pull-to-refresh states, instead of the mock-seeded `savedPlansProvider`.
- "View" opens the plan detail route, "Start" calls `POST /trips/plans/:id/start` and opens the tracker, and the delete icon now **removes the bookmark** via the save toggle (it used to only show a "Plan deleted" snackbar). Removed the mock `SavedPlansNotifier` and the swallowing `toggleSavePlan`/`voteTripPlan` repository methods.

**Verification**: `flutter analyze` clean. No runtime test — API still not running on `:4000`.

**Open on planner + saved plans**

- Stops are limited to flagged places within 100 km of the Explore centre; there is no geocoding, so a plan cannot include an arbitrary address.
- The completion card still is not shown when a trip completes.

**Open on the tracker**

- **No device location plugin** is in `pubspec.yaml`, so the tracker relies on positions already recorded for the trip (server/socket side). Until the app streams its own GPS (`SocketService.sendTripLocation` exists), validation stays disabled for trips with no recorded position. Adding `geolocator` plus permissions is a product decision, not a silent dependency addition.
- `POST /trips/:tripId/join` is not wired: the hub only lists trips the user is already part of, so there is no join entry point in the UI yet.

---

## 12. Page 5 implementation log (Rankings)

### 12.1 Backend (`teritory-api`)

`GET /rankings` now implements everything the screen's filters offered but the server
expectedly ignored or rejected:

| Change | Detail |
|---|---|
| Scope validation | `GLOBAL`, `COUNTRY`, `STATE`, `DISTRICT`, `FRIENDS`, `CLAN`, `COMMUNITY`; an unknown scope is a `400` instead of a silent global board |
| Geo scopes | `COUNTRY`/`STATE`/`DISTRICT` require their value and filter users by it |
| `FRIENDS` | accepted `FriendRelationship` rows plus the caller |
| `CLAN` / `COMMUNITY` | members of every clan/community the caller belongs to; empty membership returns an empty page, not the global board |
| Periods | `ALLTIME`, `WEEK`, `MONTH`; non-all-time periods aggregate only activity inside the window (`Flag`, completed `TripParticipant`, completed `RallyParticipant`, `PassportStamp`) and score it with the same weights as `calculateUserScore` |
| Pagination | `page`/`limit` are applied after ranking and returned with `meta` (`total`, `page`, `limit`, `totalPages`, `hasMore`) |

Rows are returned as `id`, `displayName`, `handle`, `avatarUrl`, `country`, `state`,
`district`, `totalFlags`, `majorFlags`, `completedTripsCount`, `score`, `rank`.

### 12.2 Frontend

| File | Change |
|---|---|
| `lib/core/models/leaderboard_models.dart` | `LeaderboardScope` gained `clan`/`community`; new `LeaderboardQuery` (value equality so the provider family caches per filter combination) and `MyRank` (`GET /rankings/me` payload incl. the points breakdown) |
| `lib/features/rankings/application/rankings_provider.dart` | `rankingsProvider(query)` (`AsyncValue`, live-only), `rankingsFacetsProvider` (country/state/district options taken from live standings) and `myRankProvider` |
| `lib/core/services/teritory_repository.dart` | `fetchLeaderboard({scope, period, country, state, district, limit})` sends every filter and lets `ApiException` through; `fetchMyRank()` |
| `lib/features/rankings/presentation/leaderboard_screen.dart` | scope pills for all seven scopes, season selector (All time / Month / Week), geo dropdowns populated from live facets, podium + ranked list, sticky "your rank" card with distance to the next traveler, collapsible server score breakdown; loading / empty / error+retry / pull-to-refresh per view; removed the mock-seeded board |

### 12.3 Behaviour now

- Every filter maps to a query parameter the server actually reads; changing scope, season,
  country, state or district refetches that exact combination.
- Geo scopes default to the first live value so the board never waits on a tap, and show
  "no … data in the rankings yet" when the standings contain no placed travelers.
- A geo scope with no value shows an explicit "pick a country/state/district" state instead
  of an unfiltered global board.
- Friends/clan/community require a session; a signed-out or failing call renders the server
  message with Retry rather than a fabricated leaderboard.
- "Your rank" comes from `GET /rankings/me`; when the signed-in traveler is in the current
  board, the card also shows their position and the gap to the traveler above.

### 12.4 Verification

- `node --check src/modules/rankings/rankings.controller.js` → exit 0.
- `flutter analyze` → **No issues found** (exit 0).
- **Live smoke test run**: `teritory-api` on `:4000` + `flutter test test/live_rankings_smoke_test.dart` →
  **All tests passed**. Observed against the seed:
  `global = u5:4180, u3:3785, u1:3160, u2:2130, u4:1565`;
  `country India = 5`, `state Kerala = 5`, `state Karnataka = 0` (empty result, not the global board);
  `clan = 4`, `community = 3` (proper subsets);
  `WEEK = u1:725, u2:635, u5:610` — a different ordering from all-time, so the window is real;
  `GET /rankings/me` → rank 3, score 3160 with a populated breakdown.
- The smoke test now declares a 3-minute timeout: the default 30 s is tight for a cold
  `flutter test` start plus ten sequential live calls (a passing run takes ~15 s).

### 12.5 Known limits on this page

- The board loads a single page (up to 100 rows); the API supports `?page`/`?limit` with
  `meta.total`/`hasMore`, but there is no "load more" control yet.
- Geo filter options are derived from the top 200 all-time rows, so a place whose travelers
  all sit below that cut is not offered in the dropdown.
- `CLAN`/`COMMUNITY` rank across **all** of the caller's clans/communities combined; the
  server has no per-clan selector yet.
- Period boards only include travelers with activity inside the window, so a quiet week
  yields a short (or empty) board by design.
- `streakDays`, `communityContributions`, `countriesVisited` and `continentsExplored` are
  modelled in the client but not returned by `GET /rankings`; those tiles are not rendered.

