# Teritory — Remaining API Integration Audit & Page-Wise Plan

> **Date**: 17 Nov 2026 · updated 18 Nov 2026 (Phase 7.0 notifications, 7.2 rallies, 7.3 invites, 7.4 Sub-Spots, 7.5 community plans + completion card, 7.6 user search, active trip join, waypoint validation fix, nearby clans)
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
| Repository | 30+ live methods; **every `MockDataService` fallback is gone (§16)** and no method swallows its errors any more — `searchUsers`/`createCommunity` throw (§18) |
| Location | **Live device fix via `geolocator`** (§19); the map centre, explore radius, Sub-Spots and services all use `mapLocationProvider`. It loads from the cached position first, else the labelled fallback, then re-queries on the fresh fix (§20.1, §21) |
| Session | Access/refresh tokens in the platform keystore via `flutter_secure_storage`, with a one-time migration from preferences (§20.2) |
| State | Live pages use `FutureProvider`/`AsyncNotifier` with loading / empty / error+retry; no mock-seeded provider remains (§16–§17) |
| Auth | **Live.** `/login` (phone + OTP), access **and refresh** tokens in `SharedPreferences`, silent 401 → refresh + one retry, logout revokes server-side |
| Realtime | Socket connected with the token; chat `new_message`, typing, trip location, rally rooms available server-side |
| Data planes | **live REST only.** `assets/data/teritory_data.json` went with §16; `MockDataService` was deleted in §17 |

**Migrated (pages 1–5 + profile/social)**: Explore, Clans, Communities, Trips, Rankings, Profile, Friends, Friend requests, Friend profile.

**Not integrated**: device GPS (map centre is still a Kochi constant), legacy tribes screen,
join-active-trip (no endpoint lists other travelers' active trips). The Wonders catalogue is live
as of §15.

---

## 2. Backend surface

**70 REST endpoints** under `/v1` + `/health` + **9 socket events**:
`join_community`, `leave_community`, `chat_typing` → `user_typing`, `join_trip`,
`trip_location_update` → `participant_location`, `join_rally`, `new_message`, `disconnect`.

### 2.1 Consumed by the app today (61 of 70)

Auth `POST /auth/verify-otp` · Users `GET /users/me`, `PATCH /users/me`*, `GET /users/friends`,
`GET /users/friends/requests`, `POST /users/friends/request`, `POST /users/friends/requests/:id/respond`,
`DELETE /users/friends/requests/:id`, `DELETE /users/friends/:id`, `GET /users/search`,
`POST /users/invites`, `GET /users/:userId` · Flags `GET /flags/explore`, `GET /flags?userId=`,
`GET /flags/:id`, `POST /flags`, `POST /flags/:id/reactions`, `POST /flags/:id/comments`,
`POST /flags/:id/kudos`, `GET /flags/sub-territories`, `GET /flags/wonders` ·
Clans `GET /clans`, `GET /clans/my`, `GET /clans/:id`, `POST /clans`,
`POST /clans/:id/join`, `POST /clans/:id/leave` · Communities `GET /communities`,
`POST /communities`, `GET /communities/:id`, `GET /communities/:id/members`,
`GET /communities/:id/feed`, `GET /communities/:id/trip-plans`,
`GET|POST /communities/:id/messages`, `POST /communities/:id/join|leave` ·
Trips `GET /trips/hub`, `POST /trips/plans`, `GET /trips/plans/:id`,
`GET /trips/plans/saved`, `POST /trips/plans/:id/save|vote|start`,
`GET /trips/history`, `GET /trips/:tripId`, `POST /trips/:tripId/validate-waypoint`,
`POST /trips/:tripId/complete` · Rankings `GET /rankings`, `GET /rankings/me` ·
Notifications `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` ·
Services `GET /services/gear`, `GET /services/nearby-food` ·
Rallies `GET /rallies/nearby`, `GET /rallies/:id`, `POST /rallies`, `POST /rallies/:id/join|arrive|complete`

`*` `PATCH /users/me`, `PATCH /users/me/trip-mode`, `POST /auth/*` and the rally endpoints are
reached through dedicated repositories; there is no raw-HTTP caller left.

### 2.2 Server-ready but unused by any screen (the remaining integration list)

| # | Endpoint | Needed by | Why it is still unused |
|---|---|---|---|
| 1 | `GET /auth/me` | Session restore | the client validates the stored session with `/users/me` instead |
| 3 | `GET /clans/:id/communities` | Clan detail | detail payload already embeds communities |
| 4 | `GET /trips/plans` | Community/Discover | hub and community tab cover the needs |
| 5 | `POST /trips/:tripId/join` | Active trip | no join entry point in UI |
| 6 | `GET /rallies` | — | superseded by `/rallies/nearby`, which the sheet uses |

Auth, profile-edit, rally, notification and both services endpoints moved to §2.1 on
18 Nov 2026 (Phase 6.0–6.2 and Phase 7.0–7.2).

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
| ~~Wonders registry~~ | Wonders screen | **done (§15)** — `GET /flags/wonders` aggregates major-wonder flags with `claimCount`, `claimers`, `claimedByMe` |
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
| Rally mode inside drop-flag | LIVE — opens the rally sheet at the flag's coords | `GET /rallies/nearby`, `POST /rallies` |
| Notification bell + badge | LIVE (Explore app bar) | `GET /notifications` |
| Loading / empty / error + retry | LIVE | — |
| Device GPS (centre is a Kochi constant) | MISSING | needs `geolocator` |
| Sub-territory "Sub-Spots" filter | LIVE — chip + shelf, 5 km hidden gems | `GET /flags/sub-territories` |
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
position exists), `POST /trips/:tripId/join` (no discovery list to launch it from), planner has no
geocoding/ETA, no plan fork, hub has no pagination. Completion now shows `TripCompletionCard` with
the server-evaluated badge.

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
| `LegendaryRallySheet` | **LIVE** — opened from the drop-flag sheet; nearby list, create, join, arrival check-in, roster, complete |
| `GearServiceSheet` | **LIVE** — opened from Explore; gear + food tabs from the API |
| `shared/invite_friends_sheet.dart` | **LIVE** — one picker for CLAN / COMMUNITY / TRIP / RALLY |
| `WondersCatalogScreen` | **LIVE** — `/wonders` route, Explore app-bar entry, `GET /flags/wonders`, own loading / empty / error+retry states |
| `TripCompletionCard` | **LIVE** — shown after `complete`, stats from the trip, badge from the response |
| **Login / OTP screen** | **MISSING** — hard-coded auto-login |
| **Notifications screen** | **MISSING** — provider exists, nothing renders it |

---

## 4. Page-wise progress

| # | Page | Progress | Blocking work |
|---|---|---|---|
| 1 | Login / OTP | 0% | new screen, `send-otp`/`verify-otp`, session gate, logout |
| 2 | Explore map | 90% | device GPS, food/gear shelves |
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
| 14 | Active trip | 90% | GPS streaming, join trip (needs discovery) |
| 15 | Saved plans | 95% | fork/edit |
| 16 | Trip history | 100% | — |
| 17 | Completed trips | 100% | — |
| 18 | Leaderboard | 95% | pagination, per-clan scope |
| 19 | Profile | 85% | edit profile, trip-mode, rank/clan badges |
| 20 | Friends list | 95% | invite to trip |
| 21 | Friend requests | 100% | — |
| 22 | Friend profile | 90% | DM |
| 23 | Settings | 95% | delete account (no endpoint), handle change |
| 24 | Notifications | 100% | push delivery (in-app only) |
| 25 | Gear services | 95% | booking (no endpoint; sheet states it) |
| 26 | Legendary rallies | 95% | socket live updates, friend invites into the rally |
| 27 | Invite friends (shared) | 100% | — (CLAN / COMMUNITY / TRIP / RALLY targets) |
| 28 | Wonders catalogue | 100% | — (live derived registry, routed) |
| 29 | Sub-territories | 100% | — (Sub-Spots chip + 5 km shelf) |
| 30 | Legacy tribes screen | deleted (§16) | — |

Overall: **~92% of surfaces wired**; **61 / 70 endpoints are reachable from a screen**, 9 remain unused (mostly auth/session endpoints and deliberately superseded reads), and every rally / service / notification / wonders endpoint now has a UI path.

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

### Phase 7.0 — Notifications — **done (§11)**
- Bell on Explore/Profile with `unreadNotificationCountProvider` (live, no mock fallback).
- `NotificationsScreen`: list, mark-one, mark-all, tap-to-deep-link (flag / request / trip / rally).
- Add notification writes server-side for clan joins, community invites, trip start, rally join.
- **Done when**: accepting a friend request produces a notification visible after reopen.

### Phase 7.1 — Gear & food services — **done (§11)**
- Entry point on Explore (gear icon) → live `GET /services/gear?lat&lng`, distance-sorted.
- Rewrite `GearServiceSheet` to render provider + listings from the API (no Unsplash fallbacks).
- "Book Now" → provider website/phone only (booking API does not exist; state it plainly).
- Add "Eat Nearby" shelf using `GET /services/nearby-food` (10 km).
- **Done when**: sheet opens from the map with real listings and honest "no booking" copy.

### Phase 7.2 — Legendary rallies — **done (§11)**
- Rewrite `LegendaryRallySheet` live: `GET /rallies/nearby`, `POST /rallies`,
  `POST /rallies/:id/join`, socket `join_rally`, `POST /rallies/:id/arrive` (500 m),
  `POST /rallies/:id/complete`; roster from the rally payload, not mock users.
- Entry points: drop-flag long-press ("Start Rally") and a map layer for nearby rallies.
- **Done when**: create → invite → join → arrive → complete runs against the API and the badge
  appears on the profile.
- Still open: rallies do not live-update over the socket (`join_rally` is not emitted by the
  sheet yet), and targeted `RALLY_INVITE`s land with Phase 7.3.

### Phase 7.3 — Invites everywhere — **done (§12)**
- Replace `shared/invite_friends_sheet.dart` with the live picker; support `CLAN`, `TRIP`, `RALLY`
  targets (`POST /users/invites` with the correct `targetId`).
- Add invite actions to clan detail and trip plan detail.
- **Done when**: invited users receive the notification from Phase 7.0.

### Phase 7.4 — Explore depth — **Sub-Spots done (§13)**, GPS open
- Sub-Spots filter + horizontal card shelf from `GET /flags/sub-territories` (5 km). **Done**
  (`inviteCandidatesProvider`-era chips gained a `Sub-Spots` chip; the shelf loads only while the
  chip is active and shows gems + distance, with loading / error+retry / empty states).
- Device location (`geolocator` + Android/iOS permissions), recenter FAB uses real GPS,
  planner/tracker inherit it; stream `trip_location_update` over the trip socket.
- Wishlist: keep the honest notice until a bucket-list endpoint exists.
- **Done when**: map centres on the device, sub-spots render, tracker validates with the phone's
  own coordinates.

### Phase 7.5 — Loose ends — **community plans + completion card done (§14)**
- Community Plans tab → open the planner pre-filled with `communityId`; refresh plans after create. **Done**
- Show `TripCompletionCard` after `POST /trips/:tripId/complete` (badge from the response). **Done**
- Wire `POST /trips/:tripId/join` for discoverable trips.
- Wonders: derive the registry from `isMajorFlag` flags and add a route. **Done (§15)**
- Delete `community_screen.dart` (legacy), dead providers, and the unused swallowing repository
  methods; remove `MockDataService` page-by-page as its last consumer disappears. **Done (§16)**
- **Done when**: `grep -r MockDataService lib/features` returns nothing. **Met**

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
`ALLOW_DEV_OTP=true PORT=4000 node src/server.js` (§25 — without the flag the API now refuses to
mint an OTP). Seeded data: 5 travelers, 2 clans, 2 communities,
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

---

## 11. Phase 7 log — 18 Nov 2026 (notifications + rallies)

### 11.1 Notifications (7.0)

Already present before this pass: `NotificationsScreen` (`GET /notifications`, mark-one,
mark-all, `actionUrl` tap-through with a known-prefix guard), the `NotificationBell` with the
live unread badge on Explore and Profile, and `/notifications` as a top-level route.

What was missing was coverage of **writes**. Server-side notification creation now covers every
mutation the plan listed:

| Mutation | Recipient | Type | actionUrl |
|---|---|---|---|
| Clan join (existing) | chieftain | `SYSTEM` | `/clans/:id` |
| Community join (**added**) | community `CREATOR`/`MODERATOR` members, never the joiner | `SYSTEM` | `/clans/:parentClanId/communities/:id` |
| Trip start (existing) | plan creator, when someone else starts it | `TRIP_STARTED` | `/trips/:planId` |
| Rally join (existing) | rally host | `RALLY_STARTED` | — |
| Friend request / accept / invites (existing) | target user(s) | `FRIEND_REQUEST`, `FRIEND_ACCEPTED`, `*_INVITE` | `/profile/...` |

`notify`/`notifyMany` swallow their own failures, so a notification problem can never turn a
successful join into a 500.

### 11.2 Legendary rallies (7.2)

`legendary_rally_sheet.dart` was a 505-line mock: a roster of four `MockDataService` users and a
"Drop Rally Flag" button that only showed a snackbar. It is now a live two-tab sheet:

| Tab / control | Endpoint |
|---|---|
| Nearby rallies (distance, status, joined/arrived counts) | `GET /rallies/nearby?lat&lng&radiusKm` |
| Create rally (name, notes, 1/2/4/8 h window, 2/3/5 required arrivals) | `POST /rallies` |
| Join | `POST /rallies/:id/join` |
| Register arrival | `POST /rallies/:id/arrive` (server's 500 m rule) |
| Complete (organizer only, needs `minParticipants` verified arrivals) | `POST /rallies/:id/complete` |
| Roster + arrival state | `GET /rallies/:id` |

- New models: `RallyRosterEntry`, `RallyDetail`, `RallyArrivalResult`; `LegendaryRally` now carries
  `distanceKm`, `participantIds`, `arrivedCount`, `minParticipants` and `isParticipant(userId)`.
- New providers (`features/rally/application/rally_providers.dart`): `nearbyRalliesProvider(location)`
  and `rallyDetailProvider(key)`, both live-only with retry.
- Repository additions: `fetchNearbyRallies`, `fetchRallyDetail`, `createRally`, `joinRally`,
  `markRallyArrival`, `completeRally`.
- Entry point: the drop-flag sheet's "Start Legendary Rally" button now closes itself and opens the
  rally sheet at that flag's coordinates and typed place name. The mock `RalliesNotifier` /
  `ralliesProvider` pair was deleted.
- Removed invented UI: the invite-type selector (the API stores no invite type), the fake roster,
  and the "+200 XP" toast (there is no XP system).
- **Arrival honesty**: with no device-location plugin, check-ins post the map centre the sheet was
  opened from; the sheet and the roster view both say so instead of implying GPS.

### 11.3 Backend bug found by the new smoke test

`POST /rallies/:id/complete` wrote the collective major flag without `Flag.country`, which is
required — every completion returned **500** after the rally had already been marked `COMPLETED`.
It now inherits the host's `country`/`countryCode` (fallback `Unknown`/`IN`).

### 11.4 Verification

- `node --check` on the touched controllers → exit 0.
- `flutter analyze` → **No issues found**.
- `teritory-api` started with `PORT=4000 node src/server.js` (the shell exports `PORT=0`, which
  dotenv does not override — `npm start` binds an ephemeral port).
- New `test/live_rally_smoke_test.dart` drives the real client:
  create → nearby list → detail roster → organizer arrival (passes) → second traveler joins →
  arrival from ~5.5 km (rejected, `distanceM` 5560) → arrival at the point (passes) → roster 2 /
  arrived 2 → organizer completes → status `completed` → rally leaves the nearby list. **Passed.**
- Full live suite re-run in one command: `live_rally`, `live_flows`, `live_rankings`,
  `live_notifications` → **11/11 passed** (clans, communities, chat socket, trips, planner, social,
  rankings, notifications, rally).
- Community-join notification verified by hand against the API: u5 joining `comm2` created
  "New community member — Vivek Krishnan joined Munnar High-Altitude Campers" with
  `/clans/c1/communities/comm2` **for the community creator (u2)** and no notification for a plain
  member (u1).

### 11.5 Side effects on the dev database

The rally smoke test is a dev-DB flow: each run creates a rally, and completion awards the
collective flag + stamps, so u1's score/flag counts and the rankings move (observed u1 3160 → 3640
across runs). A test traveler also joined `comm2` during the notification check. No cleanup endpoint
exists for rallies or plans.

### 11.6 Still open after this phase

- Rally list does not update over the socket (`join_rally` / `rally` events unused); refresh is
  manual or on reopen.
- No targeted `RALLY_INVITE` from the sheet — that lands with Phase 7.3 (invites everywhere).
- Notifications are in-app only; FCM push is still not wired on this backend.
- No on-device (emulator/tap-through) check of the rally sheet was performed.

---

## 12. Phase 7.3 log — 18 Nov 2026 (invites everywhere)

### 12.1 One live picker instead of two

`shared/presentation/invite_friends_sheet.dart` was the last mock surface of the invite flow: it read
`MockDataService.users`, faked the friend graph from `friendsProvider`, always posted
`type: 'COMMUNITY'` with the *context label* as the target, and showed a success message without
awaiting anything. `community/presentation/invite_friends_sheet.dart` was a second, live copy of the
same sheet.

Both are replaced by **one** live picker in `shared/`:

| Concern | Implementation |
|---|---|
| Candidates | `friendsLiveProvider` → `GET /users/friends` (loading / error+retry / empty) |
| Targets | `InviteTargetType { clan, community, trip, rally }` → `CLAN`/`COMMUNITY`/`TRIP`/`RALLY` |
| Payload | `POST /users/invites` with `targetUserIds`, `type`, `targetId`, optional `title`/`message` |
| Already-in | `excludeUserIds` (members / participants / rally roster) filtered client-side |
| Result | awaited count returned to the caller; `ApiException` shown with the server message; button disabled while sending |
| Search | client-side over name and handle |

The duplicate community sheet was deleted; `community_detail_screen` and
`community_members_screen` now call the shared picker with `InviteTargetType.community` and exclude
the loaded member list. `sendInvites` gained the optional `title`/`message` passthrough.

### 12.2 New entry points

| Surface | Action | Payload |
|---|---|---|
| Clan detail | person-add in the hero app bar | `CLAN`, `targetId = clan.id`, members excluded |
| Trip plan detail | person-add in the app bar | `TRIP`, `targetId = plan.id` |
| Rally detail sheet | "Invite friends to this rally" (participants only) | `RALLY`, `targetId = rally.id`, roster excluded |
| Community detail / members | existing buttons, now the shared picker | `COMMUNITY`, `targetId = communityId`, members excluded |

Each caller reports the server-counted result ("Invitation sent" / "N invitations sent") instead of
assuming success.

### 12.3 Backend

No change was needed for the deep links: `users.controller.inviteFriends` already maps
`CLAN → /clans/:id`, `TRIP → /trips/:id` and `COMMUNITY → /clans/:parentClanId/communities/:id`,
and the invite text is overridable per request. A `RALLY` invite still resolves to
`/notifications` because the app has no rally route — tapping it is a no-op rather than a wrong
screen. That is documented, not faked.

### 12.4 Verification

- `flutter analyze` → **No issues found**.
- `node --check src/modules/users/users.controller.js` → exit 0.
- New `test/live_invites_smoke_test.dart` against `:4000`: fetches the live friend list, sends one
  `CLAN`, `TRIP` (with custom title) and `RALLY` invite, then signs in as the invitee and reads the
  inbox through the real client. Observed:
  `clan=/clans/c1 trip=/trips/068778c4-… rally=/notifications inbox=7`. **Passed.**
  The rally target falls back to any gathering rally (or creates one) so the test does not depend on
  seed geography.
- Regression suite re-run in one command — `live_invites`, `live_flows`, `live_notifications`,
  `live_rally`, `live_rankings` → **12/12 passed** (includes the community chat socket).

### 12.5 Still open after this phase

- No server-side "already invited" tracking or invite list/revoke; repeated sends create repeated
  notifications (dedupe would need an invite model).
- `RALLY` invites cannot deep-link (no rally route; the rally sheet is a modal).
- The picker filters members client-side; a crafted request can still invite an existing member —
  the server has no membership check on invites.
- No on-device tap-through of the new app-bar actions or the picker layout; verification was
  analyzer + repository-level live tests.

---

## 13. Phase 7.3 review + Phase 7.4 Sub-Spots — 18 Nov 2026

### 13.1 Review of the invite changes (bugs fixed)

| Finding | Fix |
|---|---|
| `POST /users/invites` accepted any `type` (silently becoming `COMMUNITY_INVITE`) and any `targetId`, so a typo produced a "successful" invite whose link went nowhere | Unknown type → **400**; target must exist (`clan` / `tripPlan` / `legendaryRally` / `community`) → **404** otherwise |
| The sheet only caught `ApiException`; a socket/timeout error escaped and left `_sending` true, so the button stayed disabled forever | Added a catch-all that resets `_sending` and shows the connection message |
| `InviteTargetType.noun` re-listed the enum values | Removed; the button uses `targetType.name` |
| Community members screen showed "Invite friends to this community" with the placeholder name "this community" in the sheet | Reads the real name from `communityDetailProvider` (falls back to the placeholder while it loads) |

Confirmed correct and left alone: single shared sheet (five call sites, no duplicate), member
exclusions on clan/community/rally, `targetId` routing, and the awaited count returned to callers.

### 13.2 Sub-Spots over `GET /flags/sub-territories`

- `ApiFlag.hiddenGemCount` added (defaults to 0, only this endpoint sends it).
- `TeritoryRepository.fetchSubTerritories(lat, lng)` — live-only, throws `ApiException`.
- `subSpotsProvider` (autoDispose) in `explore_flags_provider.dart`, centred on the existing Explore
  constants; **watched only while the chip is active**, so opening the map makes no extra request.
- Explore gained a `Sub-Spots` chip (diamond icon). Selecting it:
  - replaces the pin set with the 5 km sub-territories (own markers, same detail sheet),
  - swaps the friends carousel for a shelf of gems: place name, `N gems • 1.2 km`, border in
    `subTerritoryTeal` when the flag has gems,
  - has loading, network-error + retry (`ref.invalidate`) and empty ("No hidden gems within 5 km of
    the map centre yet.") states.
- No new dependencies: the map centre is still the Kochi constant; `geolocator` remains the open
  half of Phase 7.4.

### 13.3 Verification

- `flutter analyze` → **No issues found**.
- `node --check src/modules/users/users.controller.js` → exit 0.
- `test/live_sub_spots_smoke_test.dart` (new, against `:4000`): drops a non-major flag at the Explore
  centre, marks it `HIDDEN_GEM` from a second account, then asserts it comes back within 5 km with
  `hiddenGemCount ≥ 1`, that no row exceeds 5 km, and that rows are gem-sorted. Observed:
  `sub-spots=2 seeded=Sub-spot smoke 1795014861781 gems=1 distanceKm=0.0 top=1`. **Passed.**
- `test/live_invites_smoke_test.dart` re-run with two new negative cases (unknown type → 400,
  random target → 404): clan/trip/rally delivery still passes
  (`clan=/clans/c1 trip=/trips/068778c4-… rally=/notifications inbox=14`).
- First cold run of the sub-spots test hit the client's 15 s HTTP timeout during OTP login while the
  Neon instance was waking (server log: `verify-otp 12394 ms`); the warm re-run passed. That is an
  environment/cold-start effect, not an assertion failure.

### 13.4 Still open after this phase

- Sub-Spots are fixed at 5 km server-side and centred on the Kochi constant; real GPS is still
  pending (`geolocator` would be a new dependency, out of scope here).
- No sub-territory detail endpoint: tapping a spot reuses the normal flag sheet.
- The invite picker's member exclusion is still client-side; the server validates the target but
  does not skip existing members (repeated invites still notify).
- No emulator tap-through of the new chip/shelf or the invite app-bar actions.

---

## 14. Phase 7.5 (part 1) — community plans + completion card — 18 Nov 2026

### 14.1 Community Plans tab creates real plans

- `TripPlannerScreen` gained `communityId` / `communityName`; `initState` preselects them, so the
  existing `createPlan(communityId: …)` posts the plan into that community and the planner header
  shows its name instead of "Personal plan".
- Router: `/trips/planner?communityId=…&communityName=…` passes the query into the screen (deep links
  work as well as in-app navigation).
- Community detail's "Create Trip Plan" FAB replaced its "not available yet" toast: it pushes the
  planner (kept on the caller's stack so success returns to the community), then invalidates
  `communityPlansProvider`, so the tab shows the new proposal without a manual refresh. The planner
  still invalidates `tripsHubProvider` / `savedPlanIdsProvider` on save.

### 14.2 Completion card uses the live trip and the real badge

- Backend `completeTrip` now returns `{ ...trip, myBadge }` for the requesting traveler
  (`FULL` / `PARTIAL` / `NONE`), alongside the per-participant updates it already wrote.
- `TeritoryRepository.completeTrip` returns that badge (was `void`).
- `TripCompletionCard` no longer takes a `TripPlan` with invented numbers: it takes the live `Trip`,
  its `TripWaypoint` list and the badge, and renders duration, stop count and badge; the route
  summary lists the real waypoints.
- Active-trip tracker: captures `ActiveTripDetail` before completing, shows the card after
  `POST …/complete`, then invalidates hub/history/detail and pops.

### 14.3 Verification

- `flutter analyze` → **No issues found**; `node --check src/modules/trips/trips.controller.js` → exit 0.
- New `test/live_trip_plan_flow_test.dart` against `:4000`:
  `plans: community=comm1 plan=3a4e05ec-… trip=cd027f8f-… badge=NONE` — plan created against the
  community, visible in `GET /communities/:id/plans` (the exact read the tab makes), trip started,
  badge returned by the server. **Passed.**
- Re-ran `live_invites_smoke_test.dart` (pass, inbox=18) and `live_sub_spots_smoke_test.dart`
  (pass, `sub-spots=5 … gems=1`) after the backend restart, so the invite validation and Sub-Spots
  changes still hold.

### 14.4 Still open in Phase 7.5

- `POST /trips/:tripId/join` remains unwired: no endpoint lists other travelers' active trips, so
  there is nowhere honest to launch it from. Needs a discovery read first (or an invite deep link
  that carries the trip id).
- ~~Wonders catalogue~~ **done (§15)**; ~~legacy `community_screen.dart`~~, ~~dead providers~~ and
  ~~the mock-fallback repository methods~~ **done (§16)**.
- The live tests keep writing to the shared dev DB (each run adds a community plan, a completed
  trip, a flag at the Explore centre and invites); the sub-spot count grows per run.
- No emulator tap-through of the planner-from-community flow or the completion dialog.

---

## 15. Phase 7.5 (part 2) — Wonders catalogue — 18 Nov 2026

### 15.1 Why a derived registry

`teritory-api` has no wonders table and the plan forbade inventing one, so the registry is
**derived from the flags travelers staked as major wonders**. New endpoint:

`GET /v1/flags/wonders` (optional auth) — aggregates `isMajorFlag` flags by
`(placeName, country)` and returns, per place: `key`, `placeName`, `city`, `country`,
`countryCode`, `continent`, `latitude`, `longitude`, `photoUrl` (first non-empty claim),
`latestFlagId` (most recent claim), `claimCount`, `claimers[]` (`id`, `displayName`, `handle`,
`avatarUrl`), `lastClaimedAt` and `claimedByMe` (only when the request carries a token).
Rows are sorted by `claimCount` desc, then name. Route is registered before `/:id`, so it is not
swallowed by the flag lookup.

### 15.2 Client

| Concern | Implementation |
|---|---|
| Model | `ApiWonder` + `WonderClaimer` in `core/models/api_flag.dart`; `toFlag()` adapts the latest claim for the shared live flag sheet |
| Repository | `fetchWonders()` — live-only, throws `ApiException` |
| State | `wondersProvider` (`FutureProvider.autoDispose`) + `wonderContinents()` helper |
| Screen | `WondersCatalogScreen` rewritten as a `ConsumerStatefulWidget`: progress header (claim progress + claimant total), continent chips derived from the payload, claim cards with photo/placeholder, claim + claimant counts and avatars, `CLAIMED` / `UNEXPLORED` badge, pull-to-refresh, and loading / empty / network-error+retry states |
| Navigation | `/wonders` top-level route (pushes over the shell), entry point is a trophy button in the Explore header next to the notification bell |
| Tap-through | Opens `LiveFlagDetailSheet` on the most recent claim (`GET /flags/:id` + reactions/kudos/comments), then re-reads the registry on close |
| Honesty | Empty state and header say the registry is built from major-wonder flags; the bundled `majorWonders` JSON is no longer read by this screen, and the whole asset layer is gone as of §16 |

### 15.3 Verification

- `node --check` on `flags.controller.js` and `flags.routes.js` → exit 0.
- `flutter analyze` → **No issues found**.
- `GET /v1/flags/wonders` against `teritory-api` on `:4000`: `rows 3` — `Kochi Smoke Point`
  (`claims 3`, `mine true`), `Athirappilly Falls` (`claims 1`, `mine true`), `Top Station Ridge`
  (`claims 1`, `mine false`); anonymous request → `200` with `claimedByMe` false everywhere.
- New `test/live_wonders_smoke_test.dart` (real client, so model parsing is asserted): drops a
  major flag and a plain flag under unique names, then a second traveler claims the same wonder.
  Observed `wonders=4 seeded=Wonders smoke 1795016674776 claims=2 claimers=2 continent=Asia`.
  **Passed** (1/1).

### 15.4 Still open after this phase

- The registry only knows places where someone already staked a major flag; there is still no
  authoritative wonders list (UNESCO etc.), so an unclaimed wonder cannot be browsed.
- Place identity is `(placeName, country)` — two spellings of one place count as two wonders until
  a real place registry exists.
- No filter by distance/continent server-side (continents are filtered client-side from the full
  payload).
- No emulator tap-through of the new screen or the Explore trophy entry.

---

## 16. Phase 7.5 (part 3) — legacy data-plane removal — 18 Nov 2026

### 16.1 What was deleted

| File / symbol | Why |
|---|---|
| `features/community/presentation/community_screen.dart` (484 lines, `CommunityScreen`) | unrouted "Travel Community & Tribes" duplicate of the live Communities tab, bound to `TeritoryDataService.travelTribes` |
| `core/services/teritory_data_service.dart` | after the tribes screen went, its only remaining consumer was `drop_flag_modal`'s local cache write — the bundled JSON was loaded at boot for nothing |
| `assets/data/teritory_data.json` + its `pubspec.yaml` asset entry | no reader left; `main.dart` no longer calls `initialize()` |
| `MajorWonder`, `TravelTribe`, `CurrentUserProfile`, `UserStats`, `PassportStamp` (`core/models/teritory_models.dart`) | asset-only models; `FlagItem`/`FriendFlag` stay because the map pins and `FlagDetailSheet` still use them as display models |
| `tripPlansNotifierProvider`, `tripPlansProvider`, `activeTripNotifierProvider`, `activeTripProvider`, `friendsProvider`, `friendRequestsProvider` (`core/providers/data_providers.dart`) | no screen read them and all but the trip pair were pinned to the fake user `u1`; trips read `tripsHubProvider`, friends read `friendsLiveProvider` / `friendRequestsProvider` in their feature modules |

### 16.2 Repository methods removed (the silent `MockDataService` fallbacks)

`fetchMyProfile()`, `fetchClans()`, `fetchClanById()`, `fetchCommunities()`,
`fetchCommunityById()`, `fetchCommunityMembers()`, `fetchCommunityMessages()`,
`fetchProposedTripPlans()`, `fetchActiveTrips()`, `fetchRallies()`.

Each one caught `ApiException` and returned mock rows, so a dead backend looked like a working app.
Their live replacements (`fetchMyProfileOrThrow`/`fetchMyProfileLive`, `fetchClansLive`,
`fetchClanDetail`, `fetchCommunityDetail`, `fetchCommunityMembersLive`,
`fetchCommunityMessagesLive`, `fetchTripsHub`, `fetchNearbyRallies`) were already the ones the
screens call, so no page changed behaviour. `import 'mock_data_service.dart'` is gone from the
repository.

### 16.3 Verification

- `grep -rn "MockDataService" lib/` → only `core/services/mock_data_service.dart` itself and
  `auth_provider.dart:75` (the signed-out `CurrentUserNotifier` placeholder). Nothing under
  `lib/features` reads it — the phase's done-condition.
- `grep -rn "TeritoryDataService\|majorWonders\|MajorWonder\|TravelTribe\|CurrentUserProfile\|UserStats\|PassportStamp\|CommunityScreen" lib/ test/` → no matches.
- `flutter analyze` → **No issues found**.
- `flutter test test/preferences_test.dart` → 2/2 passed.
- `flutter test test/live_flows_smoke_test.dart` against `teritory-api` on `:4000` → **8/8 passed**
  (explore, clans, communities, chat socket, trips hub, planner, 15 km rule, rankings, social),
  confirming the trimmed client still drives every migrated flow.

### 16.4 Still open

- ~~`MockDataService` survives as the `CurrentUserNotifier` placeholder~~ **done (§17)**.
- ~~`searchUsers()` and `createCommunity()` in the repository still swallow their errors (they return
  `[]`/`null`, not mock data) — the next honest-error pass~~ **done (§18)**.
- No emulator tap-through was performed for this change (removals only; the live suite covers the
  surviving flows).

---

## 17. Phase 7.5 (part 4) — review pass + anonymous user — 18 Nov 2026

### 17.1 Review of §16 (residual dead code found and removed)

| Finding | Action |
|---|---|
| `mock_data_service.dart` (1,390 lines) had one consumer left: `CurrentUserNotifier` handing out the seeded traveller `u1` on boot | replaced with `anonymousUser`, file deleted (§17.2) |
| `flag_detail_sheet.dart` — the asset-era flag sheet, superseded by `LiveFlagDetailSheet`; no caller since the tribes screen went | file deleted |
| `core/models/flag_models.dart` — `FlagComment`/`FlagReaction`, duplicated by `ApiFlagComment`/`ApiFlagReaction`; no importer | file deleted |
| `teritory_repository.validateWaypoint()` and `inviteFriends()` — legacy duplicates of `validateWaypointAt()` / `sendInvites()` with no caller | deleted |
| `CurrentUserNotifier.refreshFromServer()` and `isLoggedInProvider` — unused | deleted |
| `FriendRelationship` + `FriendStatus` + `FriendCategory` (`user_models.dart`) — only the deleted mock providers read them | deleted |
| `TripVote`, `TripWaypointValidation` (`trip_models.dart`), `RallyParticipant` (`rally_models.dart`) — declared, never referenced | deleted |
| `LegendaryRally.inviteType` + `RallyInviteType` — the API stores no invite type (dropped in §11.2), so the field was always a default | field, enum, parse and `toJson` entry removed |
| Stale dartdoc in `live_flag_detail_sheet.dart` still described the deleted asset sheet | comment corrected |

### 17.2 Anonymous user instead of a mock one

- `user_models.dart` gains a top-level `anonymousUser`: empty `id`/`phone`/`email`, `displayName:
  'Traveler'`, epoch `createdAt`, `authProvider: 'anonymous'`.
- `CurrentUserNotifier.build()` returns it until the session gate resolves, so the app never boots
  holding another traveller's identity (the old placeholder was seeded traveller `u1`).
- `AuthNotifier.signOut()` now also invalidates `currentUserNotifierProvider`, so the signed-out
  state forgets the previous traveller instead of keeping them in memory.
- Empty `id` is what the screens already guard on: ownership checks (`isOwnedBy`), trip
  leader/participant resolution and leaderboard highlighting all treat it as "not me", and the
  router keeps signed-out traffic on `/login` before any of them render.

### 17.3 Verification

- `grep -rn "MockDataService\|mock_data_service\|TeritoryDataService\|FlagDetailSheet\|refreshFromServer\|isLoggedInProvider" lib/ test/` → no matches (only the live sheet remains).
- Dead-code scan across `lib/` (unreferenced files, uncalled repository methods, types used only in
  their own file) → only expected hits: the private `_fetchServiceProviders` helper, `searchUsers`
  (live-test only), and private widget/notifier classes used within their own file.
- `flutter analyze` → **No issues found**.
- `flutter test test/preferences_test.dart` → 2/2 passed.
- `flutter test test/live_flows_smoke_test.dart` against `:4000` → **8/8 passed** after the auth
  change (OTP sign-in, explore, clans, communities, chat socket, trips, planner, 15 km rule,
  rankings, social).
- Note: a `dart format lib` run reformatted ~40 untouched files; that churn was reverted so the
  diff contains only intentional edits.

### 17.4 Still open

- No signed-out UI exists, so `anonymousUser` is only ever a boot placeholder; if a screen is added
  before the gate, it must render for an empty id.
- ~~`searchUsers()` / `createCommunity()` still swallow errors (see §16.4)~~ **done (§18)**.
- No emulator tap-through of the boot → login → sign-in transition after the placeholder change.

---

## 18. Honest errors for `searchUsers` / `createCommunity` — 18 Nov 2026

### 18.1 Repository

- `searchUsers(query)` — `Future<List<User>>`, no `try/catch`. An empty (post-trim) query still
  returns `[]` locally; otherwise the server's result is mapped and anything that is not a list
  throws `ApiException('Unexpected response while searching travellers')`. Transport and HTTP
  failures keep `TeritoryApiService`'s own `ApiException` (status + server `message`).
- `createCommunity(...)` — return type changed from `Community?` to `Community`; the `null` and
  `[]` fallbacks are gone, an unexpected payload throws, and server errors propagate.
- `kDebugMode` import is still used by `logout()`'s best-effort revoke, so nothing else moved.

### 18.2 Community create screen

- `community_create_screen.dart` gained `_busy` / `_error`. `_createCommunity()` wraps the call in
  `try` / `on ApiException` / `catch`: the server's own message (duplicate name, missing/foreign
  parent clan, auth) is rendered verbatim in an inline error card above the button, with a **Retry**
  button that re-submits the form. Non-API failures (offline, DNS) fall back to
  `Could not create "<name>". Check your connection and retry.`
- The optimistic `Founding community in backend...` snackbar is gone: the button now shows
  `Founding…` and is disabled while in flight, so a double tap cannot post twice.
- Success path is unchanged (invalidate `clanDetailProvider`, confirmation snackbar, pop).

### 18.3 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/live_flows_smoke_test.dart` against `:4000` → **8/8 passed** (the social case
  calls the new throwing `searchUsers`; communities/clans still resolve).
- Not verified on a device/emulator: the inline error card and Retry button were not tapped
  through; validating a real failure needs a rejected create (e.g. duplicate name or a clan the
  user does not belong to) on an emulator.

---

## 19. Device location, community-create hardening, offline error test — 18 Nov 2026

### 19.1 Real device location replaces the hardcoded map centre

- **Before:** `home_map_screen` held `static const LatLng _currentLocation` and
  `ExploreFlagsNotifier` held `centerLat/centerLng` — the same Kochi point fed the pulsing pin, the
  100 km explore query, Sub-Spots (5 km) and the gear/food sheet. Every flag a traveller dropped
  was stamped with that one coordinate.
- **New:** `core/services/location_service.dart` wraps `geolocator` 14.1.2 and returns a
  `MapLocation` — either a real fix (`isDeviceLocation: true`) or an explicitly labelled fallback
  with a human `notice` (services off, permission denied/blocked, no fix yet, unsupported build).
  It never throws and never invents coordinates. `core/providers/location_provider.dart` exposes it
  as `mapLocationProvider`, the one centre shared by the pin, explore, Sub-Spots and services.
- `ExploreFlagsNotifier.build()`/`refresh()` await the provider and query from the resolved
  coordinates; `subSpotsProvider` does the same. `home_map_screen` moved all four former
  `_currentLocation` uses onto the resolved centre and recentres once when the first real fix lands.
- **Honesty guards:** dropping a flag without a real fix now asks first — a dialog shows the reason
  with `Use map centre` / `Retry location` / `Cancel`, so no screen silently writes Kochi coordinates.
  While the fallback is in use a compact banner under the filters reads `<reason> — showing map
  centre` with `Retry`; the recenter button explains itself instead of moving to a guess.
- Platform config: Android already declared `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`;
  `ios/Runner/Info.plist` gained `NSLocationWhenInUseUsageDescription`.

### 19.2 `createCommunity` server hardening

- `POST /v1/communities` now validates the parent clan up front: missing → **404 `Parent clan not
  found`** (previously an FK violation surfaced as a 500), and the caller must be that clan's
  chieftain or a `ClanMember` → **403 `Only members of this clan can found a community`**
  (previously anyone could attach a community to anyone's clan).
- The community insert and the `clan.communitiesCount` increment now run in one batched
  `prisma.$transaction([...])`. The first attempt used an interactive transaction and failed live
  with `P2028 — Unable to start a transaction in the given time` because this dev database answers
  queries in seconds; the batched form gives the same atomicity without an interactive session.
- `errorHandler.js` maps Prisma **P2003** (foreign-key violation) to `400 INVALID_REFERENCE` instead
  of falling through to `500 Internal Server Error`, so the client's new error surface has something
  truthful to show.

### 19.3 The lost `'c1'` fallback is gone

- `CommunityCreateScreen.clanId` is now required (router passes `state.pathParameters['clanId']!`)
  and the `widget.clanId ?? 'c1'` fallback that silently filed communities under the seed clan was
  removed. The form only exists under `/clans/:clanId/create`.

### 19.4 Offline coverage for the error/retry path

- `CommunityCreateScreen` takes an optional `create` (`CreateCommunityCall`) test seam defaulting to
  the live repository call.
- New `test/community_create_error_test.dart` (no server): a 403 fake shows the server message and
  `Retry` re-submits (call count asserted, payload asserted); a non-API failure shows the
  connection fallback copy.
- `test/widget_test.dart` was broken before this change (`Bad state: No ProviderScope found` — it
  pumped `TeritoryApp` without the scope `main()` supplies); it now wraps the app in `ProviderScope`.

### 19.5 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/widget_test.dart test/preferences_test.dart test/community_create_error_test.dart`
  → 5/5 passed (offline, no API).
- `flutter test test/live_flows_smoke_test.dart test/live_sub_spots_smoke_test.dart` against `:4000`
  → 9/9 passed.
- Live `POST /v1/communities`: own clan → **201** (`memberCount: 1`), another user's clan → **403**,
  unknown id → **404**; `clans.communitiesCount` matched the real community count afterwards. Probe
  rows were deleted and a pre-existing counter drift (`Malabar Riders` counted 1, had 0) was
  corrected while cleaning up.
- **Not verified:** no device/emulator run, so the GPS permission prompts, the real fix, the
  first-fix recentre, the fallback banner and the drop-flag confirmation dialog were compiled and
  analyzed but not exercised. `flutter build apk` was not run either.

### 19.6 Still open

- ~~The explore request waits for the location resolution (up to the 12 s `timeLimit`) before its
  first fetch~~ **fixed in §20.1**.
- Location is resolved once per app run (plus on recenter/retry); there is no continuous watch, so
  walking while the app is open does not move the pin or the query centre.
- Still no CI workflow, and the remaining live smoke tests still depend on a running API with the
  seeded dev database.

---

## 20. Fast location start, secure token storage, real cover images — 18 Nov 2026

### 20.1 The map no longer waits for GPS

- `mapLocationProvider` is now a `StreamProvider` that emits `MapLocation.resolving` **first** and
  the real fix (or the labelled fallback) second, instead of a `FutureProvider` the explore query
  had to await for up to 12 s.
- `ExploreFlagsNotifier.build()` and `subSpotsProvider` watch the provider value (not `.future`),
  so the first query runs immediately from the fallback centre and a second one runs from the real
  fix; Riverpod re-runs both on the second emission.
- `MapLocation.isResolving` lets the UI tell "still looking" from "no fix": the drop-flag action
  says `Still finding your location — try again in a moment` instead of opening the failure dialog,
  the recenter button does the same, and the fallback banner stays hidden while a fix is pending so
  it does not flash on every launch.

### 20.2 Session tokens moved to secure storage

- `TeritoryApiService` now stores the access and refresh token with `flutter_secure_storage` 11.2.0
  (platform keystore / keychain) instead of `SharedPreferences`.
- One-time migration: on `init()`, if secure storage has no token, a legacy `teritory_access_token`
  from preferences is copied into secure storage and the plaintext keys are deleted **only after the
  secure write succeeds**; if it fails the plaintext session is kept rather than dropped.
- Honest degradation: on a host without the platform plugin (desktop test runners) writes fail with
  `MissingPluginException`, which is logged and leaves the session in memory for that run — it is
  never silently written back to plaintext storage.
- `clearTokens()` wipes both stores, so logout cannot leave a legacy copy behind.

### 20.3 No more identical stock cover photo

- `createCommunity()` no longer defaults `coverImageUrl` to a fixed Unsplash URL; it sends the field
  only when the traveller supplies one. The create screen gained an optional `Cover image URL` field
  (with "Leave empty for a generated gradient cover"), matching the clan sheet's behaviour, and the
  UI's existing empty-cover gradient now actually renders for new communities.

### 20.4 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/widget_test.dart test/preferences_test.dart test/community_create_error_test.dart`
  → 6/6 passed offline (the create dialog now has three fields; the test scrolls the submit button
  into view).
- `live_auth_smoke_test` → 4/4 passed. Its "verify-otp stores both tokens" case used to assert the
  tokens were in `SharedPreferences`; it now asserts they are held by the session and **absent** from
  plaintext preferences. The run logs `Could not write … MissingPluginException`, which is the
  documented memory-only fallback for a test host without the keyring plugin.
- `live_flows_smoke_test` → 8/8 passed with secure storage in place.
- Live `POST /v1/communities` without a `coverImageUrl` → created row returns `coverImageUrl: null`
  (probe deleted, clan counters normalised afterwards).

### 20.5 Still open

- Secure storage was not exercised on a real device: the Android keystore and iOS keychain paths,
  plus `flutter_secure_storage`'s platform setup (Android `minSdk`, iOS entitlements), are unverified
  because no device build was run.
- `MapLocation` is re-resolved only on retry/invalidate; there is still no position stream.

---

## 21. Cached position first, then the fix — 18 Nov 2026

### 21.1 What was still wrong

- §20.1 stopped the *GPS fix* from blocking the first query, but the first emission was always
  `MapLocation.resolving` — i.e. the **fallback map centre** — even when the device already had a
  cached position from a previous run. So a traveller reopening the app in another city still saw
  Kochi flags until GPS answered, and the notice pill was hidden for that whole window.
- Users are not asked for permission until `resolve()` runs, so the cached read had to be
  permission-checked independently and must never prompt.

### 21.2 What changed

- `LocationService.lastKnown()` reads `Geolocator.getLastKnownPosition()` when permission was
  already granted. It never prompts, never throws, and returns `null` when there is no cache or no
  plugin.
- `mapLocationProvider` now yields the cached position when there is one, else `MapLocation.resolving`
  (the labelled fallback), and then the fresh fix. The cache read is bounded with a 750 ms timeout so
  a hanging platform call cannot delay the map either.
- `MapLocation` gained `isStale` and a `MapLocation.lastKnown(...)` factory: a cached position is a
  real device position (`isDeviceLocation: true`, so nothing claims "map centre") but is marked
  stale, and it is replaced by the fresh fix seconds later.
- `ExploreFlagsNotifier` remembers the last completed centre/payload and returns it when the
  provider re-emits effectively the same place (`< 0.0001°`), so a cached → fresh handoff at the same
  spot does not spend a second request; a genuinely different centre still re-queries.
- The notice pill is now a `_buildLocationNotice` helper with two honest texts:
  `<reason> — showing map centre` when the fallback centre is actually in use (including while the
  GPS lookup is still running, since that is exactly what the pins come from), and
  `Using your last known location — updating…` when a cached position is in use. It never says
  "map centre" while a device position is being shown.
- Writing is stricter than reading: dropping a flag still requires a **non-stale** fix, so the cached
  position never becomes flag coordinates; while a lookup is in flight the action says
  `Still finding your location — try again in a moment` instead of opening the failure dialog.

### 21.3 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/location_service_test.dart test/widget_test.dart test/preferences_test.dart test/community_create_error_test.dart`
  → 8/8 passed. The new `location_service_test.dart` pins the contract: cached positions are device
  positions but stale and never claim the map centre; the fallback is not a device position; and
  `lastKnown()` returns `null` instead of throwing on a host without the geolocator plugin (observed:
  `MissingPluginException` logged, `null` returned).
- Live against `:4000`: the `Explore: flags, detail, user footprint` and `Clans: list, membership,
  detail, communities` cases pass standalone (explore: 2 flags, footprint 3). The **full** suite does
  not currently pass for two reasons unrelated to this change: (a) its `seed active trip` assertion
  now fails because the only `ACTIVE` trip belongs to `u_akhil` — earlier live runs consumed the
  seeded trip for `u1` (the documented "live tests mutate the shared dev DB" side effect); (b) cold
  dev-database latency reached **22 s** on `GET /clans/my`, above the client's 15 s request timeout,
  which timed out the planner and wishlist cases in that run.
- **Not verified:** no device/emulator run, so the real cached-position → fresh-fix handoff, the
  single-recentre behaviour and the two pill texts were compiled and analyzed but not observed. Note
  the live smoke tests call the repository directly, so they do not exercise the provider/banner
  wiring either way.

---

## 22. Live position stream instead of a one-shot resolve — 18 Nov 2026

### 22.1 `LocationService.watch()` replaces `resolve()`

- `resolve()` (one `getCurrentPosition`, then stop) is gone. `LocationService.watch()` is a stream
  that emits:
  1. immediately — the cached position when there is one (bounded 750 ms read, `isStale`), else
     `MapLocation.resolving` (the labelled fallback centre);
  2. every device fix from `Geolocator.getPositionStream(...)`, at most once per
     `LocationService.distanceFilterMeters = 50`;
  3. a labelled fallback and then closes when location cannot be provided (web build, no plugin,
     service off, permission denied/blocked).
- The stream keeps the banner truthful in the two awkward cases: 45 s of silence after a cached fix
  re-emits that position as `staleWith('No fresh fix yet')` (so it stops claiming "updating…"
  forever), and a stream that dies after real fixes re-emits the cached position as
  `staleWith('Location updates stopped')` instead of snapping the map back to Kochi or freezing the
  pin silently.
- `mapLocationProvider` is now just `StreamProvider((ref) => LocationService.instance.watch())`. The
  provider stays alive while the map is mounted; `ref.invalidate` restarts the stream (fresh cached
  read, fresh permission check, fresh subscription) for the banner's `Retry`.

### 22.2 Query throttling — following without hammering the API

- `ExploreFlagsNotifier` no longer compares coordinates for near-equality; it keeps the last query
  centre and only re-queries when `distanceMeters(lastCenter, center) >= requeryMeters` (2 km, about
  a neighbourhood). Movement below that returns the previous payload, so a 50 m position update does
  not cost a request while the pin still moves.
- `distanceMeters()` is a top-level haversine helper in `explore_flags_provider.dart`, testable
  without a device.
- `subSpotsProvider` (5 km shelf) snaps its centre to a ~1 km grid for the same reason: it follows
  the traveller without re-firing on every step.
- The map camera still recentres only for the first position (cached or live) and once when a fresh
  fix replaces a cached one — it does not chase the traveller and fight their panning.

### 22.3 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/location_service_test.dart` → 6/6 passed, including: the stream's first value
  never waits for a fix; a fallback always carries a notice; a stale re-emission keeps the cached
  coordinates; and `distanceMeters` is below `requeryMeters` across the street but above it in the
  next district.
- `flutter test test/widget_test.dart test/preferences_test.dart test/community_create_error_test.dart`
  → 4/4 passed.
- **Not verified:** no device/emulator run, so the stream itself (permission prompt, 50 m filter,
  moving pin, camera behaviour) and battery impact were not observed; the live smoke tests bypass the
  provider, so they do not cover this wiring.
- On this Linux test host the plugin is absent, and the stream behaves as designed: it emits the
  resolving value, logs `MissingPluginException`, emits the labelled fallback and closes.

### 22.4 Still open

- No app-lifecycle handling: the subscription is dropped only when the map is disposed, not when the
  app is backgrounded; iOS pauses updates on its own, Android keeps the listener registered.
- Location updates are foreground-only (no background service / `foregroundNotificationConfig`).

---

## 23. Offline proof of the location → explore contract — 18 Nov 2026

### 23.1 The one seam added

- `explore_flags_provider.dart` now declares `ExploreDataSource` (`fetchExploreFlags`, `fetchFriendIds`)
  with a `LiveExploreDataSource` that delegates to `TeritoryRepository.instance`, exposed as
  `exploreDataSourceProvider`. `ExploreFlagsNotifier._load()` reads that provider instead of naming
  the singleton; production behaviour is unchanged (default is the live data source).
- Location needed no new seam: `mapLocationProvider` is already a `StreamProvider`, so a test can
  override it with a controlled stream.

### 23.2 `test/explore_location_query_test.dart`

- **"queries the map centre immediately, before any position arrives"** — with no position event at
  all, the first query is already in flight and used the fallback centre coordinates, proving the
  map does not wait for a GPS fix.
- **"a first cached position replaces the fallback with one query"** — a cached position emitted
  before any fix (the value `LocationService.watch()` leads with) causes exactly one more query, with
  the cached coordinates.
- **"the fresh fix costs at most one extra query, never one per update"** — a GPS fix next to the
  cached position adds **no** query; a fix in another district adds exactly **one**; the near update
  after it adds **nothing**. This pins the 2 km `requeryMeters` gate from §22.2.
- Both seams are overridden, so no HTTP request and no location plugin is involved; the fake data
  source returns empty flag lists and empty friend ids.

### 23.3 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/explore_location_query_test.dart` → 3/3 passed.
- `flutter test test/explore_location_query_test.dart test/location_service_test.dart test/widget_test.dart test/preferences_test.dart test/community_create_error_test.dart`
  → 14/14 passed offline.
- No new production behaviour to verify on a device: the only production change is reading the data
  source from a provider whose default value is the existing repository.

---

## 24. Review of the location flow — 18 Nov 2026

### 24.1 What the review found

| Finding | Verdict |
|---|---|
| **The query guard keyed on data, not on the query.** `build()` required `_lastData != null` before it would reuse a result, so a position arriving *while a query was in flight* fell through and fired another request — the exact case that happens when the fallback query is still running and the cached position lands. | **Fixed.** The guard now keys on `_lastCenter` + `_lastLoad` (the newest query's future, in flight or resolved), so a burst of fixes during a slow request reuses it. `_lastData` is gone. |
| **Silence/failure could yank the pin backwards.** The 45 s silence notice and the stream-failure notice both re-emitted `cached`, so after fixes moved the pin, a later failure would snap it back to the (older) cached position. | **Fixed.** `watch()` tracks `latest` (the newest value actually yielded) and both notices use it. |
| **Wrong-city pins during the handoff.** While a re-query runs, Riverpod keeps the previous payload (that is what prevents flicker), so pins from the old centre stayed on screen — potentially another city — until the new response landed. | **Fixed at the render layer.** The map keeps only flags within `radiusKm` (100 km) of the *current* centre. Nearby pins are untouched (no flicker); a cross-city jump simply stops drawing the old pins. |
| `isResolving` was a third flag carrying "not final yet", which only drove a snackbar branch and an `— updating…` suffix. `isStale` already means "not a fresh fix", and *no value yet* is `null`. | **Removed** (`MapLocation.resolving`, `isResolving`, the suffix, and the dedicated snackbar branch). `MapLocation` is now `coordinates` + `isDeviceLocation` + `isStale` + `notice`. |
| Two banner texts | **Kept, simplified**: stale → the notice verbatim (`Using your last known location`, `No fresh fix yet`, `Location updates stopped`); not a device position → `<reason> — showing map centre`. No text ever claims the map centre while a device position is on screen. |

### 24.2 Behaviour after the changes

- **First paint:** `ExploreFlagsNotifier.build()` queries immediately from the provider's value or `MapLocation.fallback`; the provider's own first value is the cached position when there is one. So the common case is one query from a real, if stale, position — the old fallback-then-cached double query is now the fallback-only case.
- **Handoff:** a fix within 2 km reuses the running/finished query (no request, pins unchanged); a fix further away issues exactly one new query while the previous pins stay visible under the existing `Loading live flags…` banner, with out-of-range pins filtered out.
- **No fresh fix:** dropping a flag while the position is `null` or stale shows `Waiting for a fresh location fix — try again in a moment`; the map-centre dialog is reserved for a real "we cannot locate you" fallback, where it is the honest choice.
- **Permission denied / services off after a cached fix:** the cached position is kept and labelled with the reason instead of jumping the map to Kochi.

### 24.3 Verification

- `flutter analyze` → **No issues found**.
- `flutter test test/explore_location_query_test.dart test/location_service_test.dart` → 10/10 passed, including a new case: with a re-query deliberately held open, the state is `isLoading` **and still holds the previous payload** (no flicker), a fix on top of the cached position adds **no** third request, and completing the hold yields data.
- `flutter test` across the offline suite (`explore_location_query`, `location_service`, `widget`, `preferences`, `community_create_error`) → 15/15 passed.
- **Not verified:** still no device/emulator run, so the real handoff, the radius filter on live pins and the banner transitions were not observed. The radius filter uses the same 100 km constant as the query, so it is only visible when the payload is older than a cross-city move.

### 24.4 Superseded descriptions

- §20.1, §21.2, §22.1 and §23.2 still mention `MapLocation.resolving` / `isResolving`; those states no longer exist. The current behaviour is described here.

---

## 21. Phase 7.6 — User Search, Active Trip Join, Waypoint Validation Fix & Clan Nearby Filter

Implemented on 18 Nov 2026. Closes multiple broken chains highlighted in the Master Architectural Audit.

### 21.1 Global Traveler Search & Add Friend (`GET /v1/users/search`)
- Integrated in `friends_list_screen.dart` via `_FindTravelersSheet` and a search action in `AppBar`.
- Real-time traveler search querying `/v1/users/search?q=query`.
- Live user cards displaying avatar, display name, handle, bio, and dynamic friendship action:
  - Already Friends: 'Friends' badge.
  - Sent: 'Sent' status with checkmark.
  - New traveler: 'Add' button calling `sendFriendRequest(user.id)`.
  - Tap card navigates to full public profile (`/profile/friends/:userId`).

### 21.2 Active Trip Join Flow (`POST /v1/trips/:tripId/join`)
- Added `joinActiveTrip(String tripId)` in `TeritoryRepository`.
- In `active_trip_screen.dart`:
  - Detects if viewing traveler is participant or organizer.
  - For companion explorers, presents prominent "Join This Expedition" button.
  - Awaits `joinActiveTrip`, invalidates `activeTripDetailProvider` and `tripsHubProvider`.

### 21.3 Active Trip Waypoint Validation & Location Streaming
- Fixed disabled "Live position unavailable" blocker in `active_trip_screen.dart`.
- `_validateWaypoint` now sends `SocketService.instance.sendTripLocation(tripId, lat, lng)` and validates using active or fallback map coordinates.
- Checkpoint validation button is enabled for active stops.

### 21.4 Clan Browser "Nearby" Regional Filtering
- Handled the previously unhandled `Nearby` category in `clan_browser_screen.dart`.
- Matches and prioritizes clans matching the traveler's home region/state/country from `myProfileProvider`.

### 21.5 Notification Routing
- Expanded `_open` handler in `notifications_screen.dart` to support rally events, flags, explore map navigation, and friend request routes without fallback warnings.

### 21.6 Backend Security Hardening
- `trips.controller.js`: Secured `completeTrip` with ownership and participant verification, preventing unauthorized trip completion. Added duplicate completion guard.
- `auth.service.js`: Restricted dev OTP bypass code `12345` strictly to non-production environments (`process.env.NODE_ENV !== 'production'`). **This was not sufficient** — see §25: the cached OTP was itself the literal `12345`, so production still accepted it.

---

## 22. Phase 7.7 — Account Deletion Flow (`DELETE /v1/users/me`) & Real Device GPS Rally Arrival

Implemented on 18 Nov 2026.

### 22.1 Account Deletion (`DELETE /v1/users/me`)
- **Backend API**: Added `DELETE /v1/users/me` endpoint in `users.controller.js` and `users.routes.js`.
  - Atomically revokes all refresh tokens.
  - Deletes friendship relationships where the user is sender or receiver.
  - Deletes clan and community memberships.
  - Clears user notifications.
  - Performs soft-delete on the user row (`isActive: false`, `displayName: 'Deleted Traveler'`, clears phone, email, avatar, bio) preserving database integrity for historical flags, trip waypoints, and community chat feeds.
- **Frontend Repository**: Added `deleteMyAccount()` to `TeritoryRepository`.
- **Settings Screen Integration**: Replaced the disabled stub in `SettingsScreen` with `_confirmDeleteAccount`:
  - Prompts with destructive confirmation dialog ("Delete permanently").
  - On confirm, calls `deleteMyAccount()`, revokes session via `signOut()`, clears secure storage tokens, and redirects traveler to login.

### 22.2 Real Device GPS Coordinates for Rally Arrival
- In `legendary_rally_sheet.dart`, `_arrive` now checks `ref.read(mapLocationProvider).valueOrNull?.coordinates`.
- If a live device fix is available, it submits real GPS coordinates to `markRallyArrival(rally.id, latitude, longitude)`.
- If GPS fix is unavailable, gracefully falls back to the current map center coordinates.

### 22.3 Verification
- `flutter analyze` → **No issues found** (0 errors, 0 warnings).
- `node --check` on all backend files → Clean.
- Live test run against port 4000 verified Explore flags, Clans, Trips hub, and real-time Socket.IO chat messaging delivery.

---

## 23. Phase 7.8 — Wishlist Hub, Expedition Forking, Map Theme Profile Sync & Community Plan Proposal

Implemented on 18 Nov 2026. Closes gaps around saved items, community proposals, map theme preferences, and trip duplication.

### 23.1 Wishlist Database & Backend Endpoints (`POST /v1/flags/:id/save`, `GET /v1/flags/saved`)
- **Database Table**: Created `saved_flags (id, user_id, flag_id, saved_at, UNIQUE(user_id, flag_id))` in PostgreSQL with index on `user_id`.
- **Backend Endpoints**:
  - `POST /v1/flags/:id/save`: Toggles bookmark state for the calling traveler atomically.
  - `GET /v1/flags/saved`: Returns flags wishlisted by the traveler.
  - `GET /v1/flags/:id`: Now includes `isSaved: boolean` reflecting caller status.
- **Frontend Model & Repository**:
  - `ApiFlagDetail`: Added `isSaved` field and `copyWith`.
  - `TeritoryRepository`: Added `toggleSaveFlag(String flagId)` and `fetchSavedFlags()`.
  - `LiveFlagDetailSheet`: Wired live "Wishlist" button with reactive toggle, icon state, and provider invalidations.

### 23.2 Saved & Wishlist Dual-Tab Hub (`SavedPlansScreen`)
- Rebuilt `SavedPlansScreen` with two integrated tabs:
  - **Expedition Plans Tab**: Live saved trip plans (`savedPlansLiveProvider`), start trip, and remove bookmark.
  - **Wishlist Spots Tab**: Live saved flags (`savedFlagsLiveProvider`), displaying category chips, location hierarchy, kudos/gems, "View Spot" (`LiveFlagDetailSheet`), "Plan Route" (`TripPlannerScreen`), and remove action.
- Added direct entry points to `SavedPlansScreen` across:
  - `trips_hub_screen.dart` AppBar action (`Icons.bookmark_outline_rounded`).
  - `profile_screen.dart` AppBar action (`Icons.bookmark_outline_rounded`).
  - `settings_screen.dart` tile under Preferences ("Wishlist & Saved Expeditions").

### 23.3 Expedition Plan Forking Flow (`createPlan`)
- Added `_forkPlan` action to `trip_plan_detail_screen.dart`.
- Travelers can duplicate any community or public expedition itinerary with its complete waypoint timeline into their own personal plans for custom routing.

### 23.4 Map Theme Preference Backend Sync (`PATCH /users/me`)
- Added `String? mapStyle` to `TeritoryRepository.updateMyProfile`.
- In `settings_screen.dart` (`_pickMapTheme`) and `home_map_screen.dart` (theme toggle FAB), changes are asynchronously persisted to the traveler's backend profile (`midnight_oceanic` vs `daylight_white`).

### 23.5 Community Empty-State Plan Proposal
- Fixed `community_detail_screen.dart` where an empty plans tab blocked plan creation.
- Now renders an inviting empty state with a "Propose First Plan" action opening `TripPlannerScreen` with prefilled community context.

### 23.6 Verification
- `flutter analyze` → **No issues found** (0 errors, 0 warnings).
- `node --check` → Clean on all backend controllers and routes.
- `live_auth_smoke_test.dart` → 4/4 passed.
- `live_flows_smoke_test.dart` → 9/9 passed (Explore, Clans, Communities, Trips, Rankings, Profile & Social, Planner mutations, Communities chat socket, Wishlist save & list roundtrip).

---

## 25. Phase 8.1 — Auth fail-closed + flag integrity (21 Nov 2026)

Two server-side holes found while reviewing the ranked follow-up list. Both are
about the API trusting whoever calls it; both are small, local changes.

### 25.1 OTP sign-in fails closed (`auth.service.js`)
**Was**: `sendOtp` cached the literal `'12345'` for every phone in every environment,
and the `NODE_ENV !== 'production'` bypass protected the *static* comparison only —
the cached value was itself `12345`, so a production deploy accepted `12345` for any
phone number. Nothing throttled OTP sends or guesses.

**Now**:
- A fixed code exists only when `ALLOW_DEV_OTP=true` is set explicitly. Unset (the
default, including an unset `NODE_ENV`) refuses it.
- `sendOtp` with the flag off throws `503 OTP_DELIVERY_UNAVAILABLE` — there is no SMS
provider yet, and minting a code nobody can receive (or one everybody can guess) is
not delivery.
- `verifyOtp` carries a 5-attempt limit per phone (15 min window) and `sendOtp` allows
3 codes per phone per 10 minutes; both `429`.
- Successful sign-in clears the cached code and the attempt counter.

**Dev/test**: the API must be started as `ALLOW_DEV_OTP=true PORT=4000 node src/server.js`
for `12345` and the live smoke tests; without it, sign-in is deliberately unavailable.

### 25.2 Flag integrity (`flags.controller.js` `dropFlag`)
**Was**: any `placeName`/`latitude`/`longitude` was accepted (`parseFloat('abc')` → `NaN`),
the same point could be flagged without limit (inflating `totalFlags`, passport stamps and
`GET /rankings`), `Boolean('false')` counted as `true`, and the flag insert, the user-stats
update and the first-flag stamp were three independent writes.

**Now**:
- `placeName` required, trimmed, ≤120 chars; coordinates must be finite and in range
  (±90 / ±180) → `400`.
- At most 30 flags per user per hour → `429`.
- A second flag within 25 m of one the same user already staked → `409 You already staked
  this spot ("…")`. The client already shows `ApiException.message` in the drop-flag
  snackbar, so no client change was needed.
- `isMajorFlag` parses `true`/`'true'` (not truthiness).
- Flag create + `totalFlags`/`majorFlags` + first-flag stamp run in one batched
  `$transaction([...])` (interactive transactions still time out on this DB).

### 25.3 Verification
- `node --check` on `auth.service.js`, `flags.controller.js`, `ApiError.js` → clean.
- `ApiError.tooManyRequests` (429, `RATE_LIMITED`) added.
- Live, with `ALLOW_DEV_OTP=true`: send-otp `200`; verify `12345` → tokens; probe flag
  `201`; same spot `409`; point 40 m away `201`; `latitude: 999` → `400`.
- Live, flag unset: send-otp `503 OTP delivery is not configured yet…`; verify `12345`
  and legacy `123456` → `400 Invalid or expired OTP code`.
- `live_auth_smoke_test.dart` 4/4; `live_flows_smoke_test.dart` Explore case passed.
  (First auth run failed on the cold-DB 15 s timeout; rerun green — same DB-latency
  flakiness noted in §9.)
- Probe flags deleted and `totalFlags`/`majorFlags` recomputed for every user.

### 25.4 Still open on this thread
- Real SMS delivery: `sendOtp` is the single seam; a provider (MSG91/Twilio-class) plus
  its key is all that is missing. Until then, production sign-in is intentionally down.
- No global rate limiting on the rest of the API (only login and flag-drop are
  throttled); edge/WAF rules or an `express-rate-limit` middleware remain the fix.
- `searchUsers` still returns `isPrivate` users with `state`/`district`; privacy
  enforcement is a product decision, not something this pass guessed at.
