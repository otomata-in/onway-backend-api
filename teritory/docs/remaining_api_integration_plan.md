# Teritory — Remaining API Integration Audit & Page-Wise Plan

> **Date**: 17 Nov 2026
> **Baseline commit**: `93c697c feat(teritory): migrate explore-to-profile screens onto the live API` (branch `develop`, clean tree)
> **Frontend**: `teritory/` — Flutter 3.x, Riverpod, go_router, `http`, `socket_io_client`
> **Backend**: `teritory-api/` — Node 22, Express 5, Prisma/Postgres, Socket.IO
> **Method**: source inspection of every screen, provider, repository method and route file;
> `flutter analyze` + `node --check` after the commit. No live runtime smoke test was possible
> (nothing listens on `:4000`).

---

## 1. Where the integration stands

| Layer | State |
|---|---|
| HTTP client | `TeritoryApiService` — token in `SharedPreferences`, 15 s timeout, unwraps `body['data']`, throws `ApiException` |
| Repository | 30+ live methods; **legacy methods still swallow errors and fall back to `MockDataService`** |
| State | Live pages use `FutureProvider`/`AsyncNotifier` with loading / empty / error+retry; legacy providers are still mock-seeded |
| Auth | **Live.** `/login` (phone + OTP), access **and refresh** tokens in `SharedPreferences`, silent 401 → refresh + one retry, logout revokes server-side |
| Realtime | Socket connected with the token; chat `new_message`, typing, trip location, rally rooms available server-side |
| Data planes still alive | live REST · `MockDataService` (1390 lines) · `assets/data/teritory_data.json` |

**Migrated (pages 1–5 + profile/social)**: Explore, Clans, Communities, Trips, Rankings, Profile, Friends, Friend requests, Friend profile.

**Not integrated**: Notifications (no UI at all), Gear services, Legendary rallies, shared Invite sheet, Wonders catalogue, sub-territories, legacy tribes screen, trip completion card, community plan creation, join-active-trip.

---

## 2. Backend surface

**69 REST endpoints** under `/v1` + `/health` + **9 socket events**:
`join_community`, `leave_community`, `chat_typing` → `user_typing`, `join_trip`,
`trip_location_update` → `participant_location`, `join_rally`, `new_message`, `disconnect`.

### 2.1 Consumed by the app today (48 of 69)

Auth `POST /auth/verify-otp` · Users `GET /users/me`, `PATCH /users/me`*, `GET /users/friends`,
`GET /users/friends/requests`, `POST /users/friends/request`, `POST /users/friends/requests/:id/respond`,
`DELETE /users/friends/requests/:id`, `DELETE /users/friends/:id`, `GET /users/search`,
`POST /users/invites`, `GET /users/:userId` · Flags `GET /flags/explore`, `GET /flags?userId=`,
`GET /flags/:id`, `POST /flags`, `POST /flags/:id/reactions`, `POST /flags/:id/comments`,
`POST /flags/:id/kudos` · Clans `GET /clans`, `GET /clans/my`, `GET /clans/:id`, `POST /clans`,
`POST /clans/:id/join`, `POST /clans/:id/leave` · Communities `GET /communities`,
`POST /communities`, `GET /communities/:id`, `GET /communities/:id/members`,
`GET /communities/:id/feed`, `GET /communities/:id/trip-plans`,
`GET|POST /communities/:id/messages`, `POST /communities/:id/join|leave` ·
Trips `GET /trips/hub`, `POST /trips/plans`, `GET /trips/plans/:id`,
`GET /trips/plans/saved`, `POST /trips/plans/:id/save|vote|start`,
`GET /trips/history`, `GET /trips/:tripId`, `POST /trips/:tripId/validate-waypoint`,
`POST /trips/:tripId/complete` · Rankings `GET /rankings`, `GET /rankings/me`

`*` `PATCH /users/me` has a repository method but **zero UI callers**.

### 2.2 Server-ready but unused by any screen (the remaining integration list)

| # | Endpoint | Needed by | Why it is still unused |
|---|---|---|---|
| 1 | `POST /auth/send-otp` | Login page | no login screen exists |
| 2 | `POST /auth/refresh` | Session | refresh token stored nowhere; 7-day token cliff |
| 3 | `POST /auth/logout` | Settings | logout is unreachable UI |
| 4 | `GET /auth/me` | Session restore | bootstrap uses `/users/me` instead |
| 5 | `PATCH /users/me/trip-mode` | Profile header | no control rendered |
| 6 | `GET /flags/sub-territories?lat&lng` | Explore "Sub-Spots" | filter not implemented (5 km hidden gems) |
| 7 | `GET /clans/:id/communities` | Clan detail | detail payload already embeds communities |
| 8 | `GET /trips/plans` | Community/Discover | hub and community tab cover the needs |
| 9 | `POST /trips/:tripId/join` | Active trip | no join entry point in UI |
| 10 | `GET /rallies`, `GET /rallies/nearby` | Rally sheet | fetched only by a mock-seeded provider nobody watches |
| 11 | `GET /rallies/:id` | Rally detail | no rally list/detail screen |
| 12 | `POST /rallies` | Rally sheet "Drop Rally Flag" | sheet only shows a snackbar |
| 13 | `POST /rallies/:id/join` | Rally roster | roster is `MockDataService` users |
| 14 | `POST /rallies/:id/arrive` | 500 m arrival check-in | not implemented |
| 15 | `POST /rallies/:id/complete` | Rally completion + badge | not implemented |
| 16 | `GET /services/gear` | Gear sheet / Explore shelf | fetched, no UI consumes it |
| 17 | `GET /services/nearby-food` | Explore "Eat Nearby" | section does not exist |
| 18 | `GET /notifications` | Notification bell/screen | provider exists, **no screen or badge** |
| 19 | `PATCH /notifications/:id/read` | Notification list | no UI |
| 20 | `PATCH /notifications/read-all` | Notification list | no UI |

### 2.3 Backend gaps (must be added for a "perfect" integration)

| Missing capability | Blocks | Note |
|---|---|---|
| `DELETE /users/me` | Settings → Delete account | none exists; legal flow needed |
| File/avatar upload (`POST /uploads`) | Edit profile, community cover | schema has `avatarUrl` but no storage endpoint |
| Friend-request guards / rate limits | Social | already partially enforced |
| Notification writes outside the users module | Clans/communities/trips/rallies | only `users.controller` creates notifications today |
| Notification preferences | Settings | model has none |
| Geocoding / directions / ETA | Planner origin & destination | planner can only pick flagged places |
| Gear booking / deep link | Gear sheet "Book Now" | no booking model |
| Wishlist (bucket list) | Flag detail heart | UI already says "not implemented" |
| Direct messages | Friend profile "Message" | no model/endpoint |
| Plan fork/edit | Saved plans "Fork" | button removed rather than faked |
| Wonders registry | Wonders screen | derived from `isMajorFlag` flags only |
| Clan coordinates | "Nearby" clan filter | schema has no geo columns |
| Presence ("Who's here now") | Explore | no presence store |

---

## 3. Page inventory — features and integration progress

Legend: **LIVE** wired to the API · **PARTIAL** wired but incomplete · **STUB** UI only,
fakes success · **MOCK** mock/asset data · **UNREACHABLE** no inbound navigation · **MISSING** no screen.

### 3.1 Tab 0 — Explore (`lib/features/home/presentation/home_map_screen.dart`) — LIVE ~85%

| Feature | State | Endpoint |
|---|---|---|
| Full-screen OSM map, Midnight/Daylight toggle | LIVE (local theme) | — |
| Flag pins + bottom carousel | LIVE | `GET /flags/explore` |
| Filters All / Friends / My Flags / Major Wonders | LIVE (client-side over fetched payload) | `GET /flags/explore`, `GET /users/friends` |
| Friend-activity badge | LIVE | `GET /users/friends` |
| Drop flag (name, category, note, photos UI) | LIVE, awaited, refreshes map | `POST /flags` |
| Flag detail: reactions, kudos, comments | LIVE | `GET /flags/:id`, `POST …/reactions|kudos|comments` |
| Wishlist | STUB — explicit "not implemented" notice | none |
| Rally mode inside drop-flag | STUB — snackbar "coming soon" | `POST /rallies` |
| Loading / empty / error + retry | LIVE | — |
| Device GPS (centre is a Kochi constant) | MISSING | needs `geolocator` |
| Sub-territory "Sub-Spots" filter | MISSING | `GET /flags/sub-territories` |
| Notification bell + unread badge | MISSING | `GET /notifications` |
| Eat Nearby / Gear shelves | MISSING | `GET /services/nearby-food`, `/services/gear` |
| Who's here now (presence) | MISSING | none |

### 3.2 Tab 1 — Clans (`clan_browser_screen`, `clan_detail_screen`, `create_clan_sheet`) — LIVE ~90%

Features: list with counts, search + category chips (client-side), join/leave with optimistic
patch + confirmation, create clan (name/sigil/region/interest), detail with chieftain, roster
(first 20), communities, pull-to-refresh, per-card pending states.
Endpoints: `GET /clans`, `GET /clans/my`, `GET /clans/:id`, `POST /clans`, `POST /clans/:id/join|leave`.
Remaining: `Nearby` filter (no clan geo data), server-side `?search=`/`?interestTag=`, invite
friends to clan (`POST /users/invites type: CLAN`), clan activity feed.

### 3.3 Communities (`community_detail_screen`, `community_chat_screen`, `community_members_screen`, `community_create_screen`, `invite_friends_sheet`) — LIVE ~90%

| Feature | State | Endpoint |
|---|---|---|
| Feed / Plans / Members / Chat tabs | LIVE, each with loading-empty-error | `feed`, `trip-plans`, `members`, `messages` |
| Join / leave (confirm on leave) | LIVE | `POST /communities/:id/join|leave` |
| Vote on a plan | LIVE toggle | `POST /trips/plans/:id/vote` |
| Send chat message + realtime receive/typing | LIVE | `POST …/messages`, socket |
| Invite friends (multi-select) | LIVE | `POST /users/invites` |
| Create community | LIVE | `POST /communities` |
| **Create Trip Plan** (plans tab FAB) | STUB — "not available yet" | `POST /trips/plans` with `communityId` |
| Vote filled-state per user | PARTIAL — list returns `voteCount`, not `hasVoted` | needs backend field |
| Membership enforcement on read | MISSING server-side (security) | — |

### 3.4 Tab 2 — Trips (hub, planner, plan detail, active trip, saved, history, completed) — LIVE ~88%

Hub: Active / Plans / History tabs, Start action, per-tab states, pull-to-refresh (`GET /trips/hub`).
Planner: origin/destination/waypoints picked from live flags, computed distance and days,
real community picker, `POST /trips/plans`, error surfacing.
Plan detail: waypoints, map polyline, save toggle, vote toggle, Start Trip (`GET /trips/plans/:id`,
`POST …/save|vote|start`).
Active trip: live progress from `/trips/:tripId` validations, 15 km server check, complete with
confirmation, socket room join/leave, `POST …/validate-waypoint`, `POST …/complete`.
Saved / History / Completed: live with retry + empty states.

Remaining: device GPS + `trip_location_update` streaming (validations only work when a recorded
position exists), `POST /trips/:tripId/join` entry point, `TripCompletionCard` never shown,
planner has no geocoding/ETA, no plan fork, hub has no pagination.

### 3.5 Tab 3 — Rankings (`leaderboard_screen`, `rankings_provider`) — LIVE ~95%

Seven scopes (Global/Country/State/District/Friends/Clan/Community), three periods
(All-time/Month/Week), geo dropdowns from live facets, podium + ranked list, sticky my-rank card
with gap to next, collapsible server score breakdown, per-view states.
Endpoints: `GET /rankings`, `GET /rankings/me`.
Remaining: pagination / "load more" (`meta.hasMore`), geo facets limited to the top 200 rows,
per-clan selector, `streakDays`/`countriesVisited` not returned by the API.

### 3.6 Tab 4 — Profile & social — LIVE ~80%

| Surface | Features now | Endpoints |
|---|---|---|
| Profile | header, stats (flags, continents/cities), footprint map, stamps shelf, recent flags, friends entry, completed-trips entry, settings entry, refresh | `GET /users/me`, `GET /flags?userId=` |
| Friends list | search, category tabs, pending-request badge, remove with confirm, open profile | `GET /users/friends`, `GET /users/friends/requests`, `DELETE /users/friends/:id` |
| Friend requests | incoming list, accept/decline, cancel outgoing | `GET /users/friends/requests`, `POST …/respond`, `DELETE …/:id` |
| Friend profile | header, action row (add/accept/remove), stats, flags map, add-friend | `GET /users/:userId`, `/flags?userId=`, friend mutations |
| Settings | **STUB** — every tile shows "Coming soon"; Log Out unreachable | none |
| Edit profile / handle / avatar | MISSING | `PATCH /users/me`, `PATCH /users/me/trip-mode` |
| Leaderboard rank summary, clan badges, rally badges on profile | MISSING | `/rankings/me`, `/clans/my`, `/rallies` |

### 3.7 Modals, orphan and missing surfaces

| Surface | State |
|---|---|
| `LegendaryRallySheet` | MOCK + UNREACHABLE — roster from `MockDataService`, drop flag = snackbar |
| `GearServiceSheet` | STUB + UNREACHABLE — accepts a `ServiceListing`, no caller, Unsplash fallbacks |
| `shared/invite_friends_sheet.dart` | MOCK + UNREACHABLE — `MockDataService.users` (community sheet is the live one) |
| `WondersCatalogScreen` | MOCK + UNREACHABLE — asset JSON, no route, no backend |
| `community_screen.dart` (legacy tribes) | MOCK + UNREACHABLE — duplicates Communities |
| `TripCompletionCard` | MOCK — never triggered after `complete` |
| **Login / OTP screen** | **MISSING** — hard-coded auto-login |
| **Notifications screen** | **MISSING** — provider exists, nothing renders it |

---

## 4. Page-wise progress

| # | Page | Progress | Blocking work |
|---|---|---|---|
| 1 | Login / OTP | 0% | new screen, `send-otp`/`verify-otp`, session gate, logout |
| 2 | Explore map | 85% | sub-territories, GPS, notifications bell, food/gear shelves |
| 3 | Flag detail | 95% | wishlist endpoint |
| 4 | Clans browser | 90% | nearby geo, server search, invite to clan |
| 5 | Clan detail | 90% | activity feed |
| 6 | Create clan | 100% | — |
| 7 | Communities list / detail | 92% | create-plan deep link, `hasVoted` |
| 8 | Community chat | 100% | membership enforcement (server) |
| 9 | Community members | 95% | — |
| 10 | Create community | 90% | cover upload |
| 11 | Trips hub | 92% | pagination |
| 12 | Trip planner | 85% | geocoding, ETA, community prefill |
| 13 | Trip plan detail | 95% | fork |
| 14 | Active trip | 80% | GPS streaming, join trip, completion card |
| 15 | Saved plans | 95% | fork/edit |
| 16 | Trip history | 100% | — |
| 17 | Completed trips | 100% | — |
| 18 | Leaderboard | 95% | pagination, per-clan scope |
| 19 | Profile | 85% | edit profile, trip-mode, rank/clan badges |
| 20 | Friends list | 95% | invite to trip |
| 21 | Friend requests | 100% | — |
| 22 | Friend profile | 90% | DM |
| 23 | Settings | 5% | logout, edit profile, prefs, delete account |
| 24 | Notifications | 0% | screen, bell, read/read-all |
| 25 | Gear services | 5% | live list + sheet + booking link |
| 26 | Legendary rallies | 10% | full lifecycle + socket |
| 27 | Invite friends (shared) | 10% | live friends + targets |
| 28 | Wonders catalogue | 15% | registry source + route |
| 29 | Sub-territories | 0% | filter/sheet over endpoint |
| 30 | Legacy tribes screen | dead | delete |

Overall: **~72% of surfaces wired**; **48 / 69 endpoints are reachable from a screen**, **21 are unused**, and the 12 rally/service/notification endpoints have no UI at all.

---

## 5. Plan to finish (phases, in order)

### Phase 6.0 — Auth & session gate (foundational, do first) — **done (§10)**
- New `LoginScreen` (phone → `POST /auth/send-otp` → OTP `12345` in dev → `POST /auth/verify-otp`).
- Persist access **and refresh** tokens; `POST /auth/refresh` on 401 with one retry.
- Router redirect: unauthenticated → `/login`; remove the hard-coded auto-login.
- `logout()` calls `POST /auth/logout`, clears tokens, disconnects socket.
- **Done when**: cold start with no token lands on login; OTP round-trip signs in; expired token
  refreshes silently; logout returns to login and clears the stack.

### Phase 6.1 — Profile completeness — **done (§10)**
- Edit-profile sheet (displayName, bio, avatar URL, country/state/district, privacy) → `PATCH /users/me`.
- Trip-mode switch → `PATCH /users/me/trip-mode`; show the "On Trip" badge on Explore carousel.
- Profile badges: rank summary (`/rankings/me`), clans (`/clans/my`), rally count (`/rallies`).
- **Done when**: edits survive a relaunch (server round-trip) and invalidate `myProfileProvider`.

### Phase 6.2 — Settings — **done (§10)**
- Wire Log Out → Phase 6.0 flow; About/Terms/Privacy static pages; Version from `pubspec`.
- Map theme default → persisted preference consumed by Explore.
- Notification settings → local toggles until the backend exposes preferences (document the gap).
- Delete account → disabled with a clear "requires backend endpoint" notice (do not fake it).
- **Done when**: no tile shows "Coming soon" except documented backend gaps.

### Phase 7.0 — Notifications
- Bell on Explore/Profile with `unreadNotificationCountProvider` (live, no mock fallback).
- `NotificationsScreen`: list, mark-one, mark-all, tap-to-deep-link (flag / request / trip / rally).
- Add notification writes server-side for clan joins, community invites, trip start, rally join.
- **Done when**: accepting a friend request produces a notification visible after reopen.

### Phase 7.1 — Gear & food services
- Entry point on Explore (gear icon) → live `GET /services/gear?lat&lng`, distance-sorted.
- Rewrite `GearServiceSheet` to render provider + listings from the API (no Unsplash fallbacks).
- "Book Now" → provider website/phone only (booking API does not exist; state it plainly).
- Add "Eat Nearby" shelf using `GET /services/nearby-food` (10 km).
- **Done when**: sheet opens from the map with real listings and honest "no booking" copy.

### Phase 7.2 — Legendary rallies
- Rewrite `LegendaryRallySheet` live: `GET /rallies/nearby`, `POST /rallies`,
  `POST /rallies/:id/join`, socket `join_rally`, `POST /rallies/:id/arrive` (500 m),
  `POST /rallies/:id/complete`; roster from the rally payload, not mock users.
- Entry points: drop-flag long-press ("Start Rally") and a map layer for nearby rallies.
- **Done when**: create → invite → join → arrive → complete runs against the API and the badge
  appears on the profile.

### Phase 7.3 — Invites everywhere
- Replace `shared/invite_friends_sheet.dart` with the live picker; support `CLAN`, `TRIP`, `RALLY`
  targets (`POST /users/invites` with the correct `targetId`).
- Add invite actions to clan detail and trip plan detail.
- **Done when**: invited users receive the notification from Phase 7.0.

### Phase 7.4 — Explore depth
- Sub-Spots filter + horizontal card shelf from `GET /flags/sub-territories` (5 km).
- Device location (`geolocator` + Android/iOS permissions), recenter FAB uses real GPS,
  planner/tracker inherit it; stream `trip_location_update` over the trip socket.
- Wishlist: keep the honest notice until a bucket-list endpoint exists.
- **Done when**: map centres on the device, sub-spots render, tracker validates with the phone's
  own coordinates.

### Phase 7.5 — Loose ends
- Community Plans tab → open the planner pre-filled with `communityId`; refresh plans after create.
- Show `TripCompletionCard` after `POST /trips/:tripId/complete` (badge from the response).
- Wire `POST /trips/:tripId/join` for discoverable trips.
- Wonders: derive the registry from `GET /flags/explore?category=…`/`isMajorFlag`, add a route,
  or delete the screen until a registry endpoint exists.
- Delete `community_screen.dart` (legacy), dead providers, and the unused swallowing repository
  methods; remove `MockDataService` page-by-page as its last consumer disappears.
- **Done when**: `grep -r MockDataService lib/features` returns nothing.

### Phase 8 — Hardening & verification
- Backend: membership checks on community/chat reads, CORS allowlist, notification coverage,
  pagination defaults, input validation on the new mutation routes.
- Frontend: pagination for rankings/feed/history, empty-state copy audit, avatar fallbacks,
  `ApiException` mapping (401 → login, 403 → permission copy, 5xx → retry).
- Verification per phase: `flutter analyze` clean, `node --check` on touched backend files, and a
  live smoke test against `teritory-api` on `:4000` (start it, run the page flow, record the
  endpoints exercised). Add widget tests only where a regression is likely (mutations/toggles).

---

## 6. Definition of done for a page

- [ ] every visible control maps to a named endpoint (or an explicit "not available" notice);
- [ ] provider is `AsyncValue`-based, live-only, with no mock rows for that page;
- [ ] loading, empty and error+retry states rendered;
- [ ] mutations await the API, invalidate the owning provider, surface server errors;
- [ ] `flutter analyze` clean;
- [ ] runtime smoke test recorded in this document.

## 7. Known blockers / decisions needed

1. ~~`teritory-api` was not running during this audit~~ — it now runs on `:4000` and all
   migrated flows were exercised; see section 9 for what was observed.
2. Device location is a product decision (new plugin + permissions).
3. Avatar upload, account deletion, gear booking, DMs, wishlist and plan fork require **new
   backend work**; until then those buttons must stay honest rather than fake success.
4. ~~Token refresh needs a refresh token persisted at login~~ — both tokens are now stored and
   refreshed on 401 (§10).  Remaining auth-shaped gaps: no handle change, no account deletion,
   and no server-side notification preferences.

---

## 9. Live verification log — 17 Nov 2026

**Environment**: `teritory-api` on `:4000` against the Neon seed DB.
The shell environment exports `PORT=0`, which `dotenv` does not override, so `npm start`
silently binds an ephemeral port; the server was started as
`PORT=4000 node src/server.js`. Seeded data: 5 travelers, 2 clans, 2 communities,
2 flags within 100 km of Kochi, 3 trip plans, 1 active trip with 5 waypoints,
1 incoming friend request, 0 notifications, 1 rally, 2 gear providers.

**Test harness**: `test/live_flows_smoke_test.dart` drives the real client
(`TeritoryRepository`, `SocketService`) — not raw HTTP — so model parsing is part of
the assertion. Run: `flutter test test/live_flows_smoke_test.dart test/live_rankings_smoke_test.dart`.
Result: **8/8 passed**.

| Flow | Observed | Verdict |
|---|---|---|
| OTP login | `POST /auth/verify-otp` 12345 → u1 `arjunnair` | works |
| Explore flags | 2 flags / 100 km, detail comments 1, own footprint 1 | works |
| Clans | 2 clans, 2 memberships, detail roster 3, 2 communities | works |
| Community detail | 2 members, 2 plans, 1 feed row after a proposal | works |
| Community chat REST | send + refetch (`messages 2→3`) | works |
| Community chat socket | `new_message` delivered to the room from Arjun Nair | works |
| Trips hub | 3 proposed plans, active trip "Palakkad to Kanyakumari", 5 waypoints | works |
| Plan detail / saved / vote | save toggle on/off, vote toggle on/off, `hasVoted` | works |
| Planner → plan | `POST /trips/plans` creates a 2-waypoint community plan | works |
| Waypoint 15 km rule | 0,0 → `isValid=false`, `distanceM=8,550,265`, message returned | works at API level |
| Rankings | 5 rows, leader u5:4180; week reorders (u1:725); me rank 3 / 3160 | works |
| Profile & social | me, 3 friends, 1 incoming request, search, friend profile | works |

### 9.1 Contract mismatches fixed

| Mismatch | Symptom in the app | Fix |
|---|---|---|
| Plan payloads carried no community identity | Saved/community plans rendered "Personal" in `saved_plans_screen` | `community { id, name }` included in hub proposed/saved, saved-plans, plan detail, plan list, create-plan and community trip-plans responses; `TripPlan.fromJson` also reads the nested `community.name` |
| Community feed had no writer for plan proposals | Feed tab always empty for every seeded community | `createTripPlan` writes a `ANNOUNCEMENT` activity when `communityId` is set |
| `SocketService.leaveTrip` emitted an event no one listened for | Leaving the tracker left the socket in the trip room | Added `leave_trip` handler in `src/sockets/index.js` |

### 9.2 Blockers found while running the flows

1. **Waypoint validation cannot be triggered from the UI.** The endpoint works, but the
   tracker gates on `ActiveTripDetail.hasPosition`, which reads `participant.currentLat/Lng`;
   `TripParticipant` has no coordinate columns, and `trip_location_update` is never emitted
   (no GPS plugin). Validation stays disabled until device location is added (Phase 7.4).
2. **No way to delete a trip plan.** The smoke test creates
   "Smoke test plan (safe to delete)" in `Munnar High-Altitude Campers` on every run and it
   cannot be removed through the API. Plans now accumulate in the dev DB (3 after two runs).
3. **Denormalised counts disagree with rosters.** `memberCount` is seeded at 142 (clan) and
   68 (community) while the join tables hold 3 and 2 rows, so cards show large numbers and
   the members tab lists a handful. Not a wiring bug; the seed or the counter needs fixing.
4. **Feed coverage is thin.** Only `MEMBER_JOIN` and (now) proposed community plans create
   activities; messages, completions and flag drops do not, so the feed is quiet by design.
5. `chat_typing` is relayed as `user_typing` but no client listens; typing indicators are
   still unimplemented (Phase 7.0 alongside notifications).

---

## 10. Phase 6 log — 17 Nov 2026

### 10.1 What changed

| Area | Change |
|---|---|
| API client | `saveTokens` stores access **and** refresh tokens; a 401 outside `/auth/*` refreshes once (single-flight, because the server rotates and revokes the old refresh token) and replays the request |
| Session gate | `AuthStatus { restoring, signedOut, signedIn }` notifier restores the stored session on cold start; hard-coded `+919876543210` auto-login removed |
| Router | `routerProvider` + `refreshListenable`: `restoring → /splash`, `signedOut → /login`, `signedIn → shell`; `/login` and `/splash` leave the stack on sign-in |
| Login UI | `LoginScreen` — phone → `POST /auth/send-otp` → 5-digit code → `POST /auth/verify-otp`; server errors rendered inline; dev bypass hint only in debug builds |
| Logout | Settings → Log Out confirms, calls `POST /auth/logout`, clears both tokens, disconnects the socket, router lands on `/login` |
| Profile edits | `EditProfileSheet` → `PATCH /users/me` (displayName, bio, avatar URL, country/state/district, isPrivate) and `PATCH /users/me/trip-mode`; invalidates `myProfileProvider` |
| Profile badges | Rank (`/rankings/me`), clan count (`/clans/my`) and legendary rally count (already in `/users/me`) as chips under the stats row |
| Explore | "On a trip" pill under the header when the profile has trip mode on |
| Settings | Edit Profile / Privacy (live), map theme (persisted), notification switches (device-local, labelled), About / Terms / Privacy pages, version, Delete Account dialog stating the missing endpoint |
| Explore theme | `mapThemeProvider` (persisted) replaces the local `_isDarkTheme`, so Settings and the map FAB stay in sync |

### 10.2 Live tests run against `:4000`

| File | Covers | Result |
|---|---|---|
| `test/live_auth_smoke_test.dart` | `send-otp`; wrong code rejected; `verify-otp` stores both tokens; expired access token refreshes silently and rotates the refresh token; `logout` revokes and clears | 4/4 passed |
| `test/live_profile_smoke_test.dart` | `PATCH /users/me` round-trip (edit then re-read, then restore); `PATCH /users/me/trip-mode` flip and restore | 2/2 passed |
| `test/live_flows_smoke_test.dart` + `live_rankings_smoke_test.dart` | earlier migrations, re-run after the client change | passed |
| `test/preferences_test.dart` | map theme + notification switches survive a fresh provider container | 2/2 passed |

### 10.3 Gaps left open (deliberately)

1. **Handle** is not in the backend allow-list for `PATCH /users/me`; Settings states that instead
   of pretending.
2. **Account deletion** has no endpoint; the action shows a dialog naming the gap.
3. **Notification preferences** are device-local; the backend has no preferences endpoint, and the
   sheet says so.
4. **Avatar upload** does not exist — the sheet edits an avatar URL only.
5. Version is a constant in `AppConfig.appVersion` kept in sync with `pubspec.yaml`; adding
   `package_info_plus` was avoided.
6. The screens were verified through `flutter analyze` and the repository-level live tests; no
   on-device tap-through of the new login/settings UI was performed.
