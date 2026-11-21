# Teritory — Remaining Features: Verification, Gaps & Implementation Plan

> **Created:** 2026-11-21
> **Scope:** Verify the work described in `remaining_features_plan.md` and the completion summary (commits `8cf89ac`, `e19741f`) against the actual code, record every gap, and plan the remaining implementation.
> **Branch:** `develop` (clean and in sync with `origin/develop` at audit time, apart from one trailing-newline change).

---

## 1. How this audit was performed

Every claim was checked against the working tree, not against the plan document:

- read the backend route/controller/service files and the Flutter widgets, models, providers and repository methods involved;
- checked `pubspec.yaml` / `pubspec.lock` and `teritory-api/package.json` for declared dependencies;
- searched for remaining `Image.network` / `NetworkImage` usages, unresolved `/uploads/...` paths, and unused endpoints;
- ran `flutter analyze` (baseline: **0 issues**) and inspected the running API for the new endpoints;
- confirmed branch/commit state with `git status -sb` and `git log origin/develop..HEAD`.

A claim is marked **Complete** only when the full path works end to end (UI → repository → API → database → response → UI). Anything that renders or persists nothing is marked **Partial** even if the endpoint returns `201`.

---

## 2. Verification matrix

| # | Feature | Claimed | Verified status | Evidence |
|---|---------|---------|-----------------|----------|
| 1 | Client image caching | Complete | **Partial** | `cached_network_image` is installed and the six `Image.network` calls were replaced, but **27 `NetworkImage` usages remain** (avatars in profile, clans, community, friends, leaderboard, trip screens). `NetworkImage` only uses Flutter's in-memory cache — no disk cache, re-download after restart. |
| 2 | Click-to-call / external actions | Complete | **Complete (fixed in this pass)** | `url_launcher` wired for `tel:`, website and Google Maps; inquiries now persist through Prisma and are recorded from all three actions. |
| 3 | Photo upload pipeline | Complete | **Complete for the round trip (fixed in this pass)** | Uploads now return absolute URLs, the client resolves legacy relative paths, the directory is created at boot, extensions come from the MIME type, and multer errors map to `413`/`400`. Remaining: cover-image picker, magic-byte sniffing, orphan cleanup, object storage for multi-instance deploys. |
| 4 | Leaderboard filters | Complete | **Complete (fixed in this pass)** | Page-aware `getEnvelope`, a paging feed notifier, Load More + auto-load, and a Community dropdown backed by `GET /communities/mine`. |
| 5 | Road routing | Complete | **Partial** | OSRM proxy is used by active trip, plan detail **and now the trip planner preview**. Still missing: home-map route overlay, direction caching, per-user throttling, production routing endpoint. |
| 6 | Offline resilience | Complete | **Partial** | Saved plans/flags and **the trips hub + active trip detail** now fall back to cache, and only for network failures (server refusals stay visible). Still missing: offline banner, refresh-on-reconnect for read screens. |
| 7 | Push notifications | Complete backend & client support | **Not complete** | Only `fcmToken` is accepted by `PATCH /users/me` and exposed via `TeritoryRepository.updateFcmToken`. **No `firebase_core`/`firebase_messaging`, no token acquisition, no permission flow, no `firebase-admin` dispatch.** Nothing calls `updateFcmToken`. Blocked on Firebase credentials. |
| 8 | Structured chat images | Implied complete | **Complete (fixed in this pass)** | `CommunityMessage.imageUrl` column, validation on send, socket payload carries it, and the bubble falls back to the legacy `[Photo]` marker for old rows. |

---

## 3. Gap register (severity ordered)

### P0 — Broken user-facing round trips

1. **Uploaded images do not render.**
   - `teritory-api/src/modules/upload/upload.controller.js` returns `{ url: '/uploads/<uuid>.<ext>' }`.
   - `teritory/lib/core/config/app_config.dart` base URL is `http://localhost:4000/v1`.
   - `CachedNetworkImage(imageUrl: flag.photoUrl)` / `NetworkImage(profile.avatarUrl)` receive a path with no host (and the wrong prefix if naively concatenated).
   - New uploads therefore appear broken in the flag detail sheet, profile, clan/community covers and chat once the app restarts against stored relative values.

2. **Uploads directory is not created at runtime.**
   - `teritory-api/uploads` is gitignored; only a local `.gitkeep` exists (untracked because the directory is ignored).
   - A fresh clone/deploy gets `ENOENT` from `multer.diskStorage` on the first upload → `500`.

3. **Multer errors are mapped to `500`.**
   - Oversized files (`LIMIT_FILE_SIZE`) and unexpected fields hit the generic branch of `errorHandler.js`; clients see `Internal Server Error` instead of `413`/`400`.

4. **Upload extension is attacker-controlled.**
   - The filename extension comes from `file.originalname` while the MIME type comes from the client. A file named `x.html` with `image/jpeg` is stored as `.html` and served by `express.static` as HTML from the API origin.

### P1 — Claimed but not actually usable

5. **Service inquiries are fake.**
   - `recordInquiry` builds `{ id: 'inq_<timestamp>', ... }` and returns it; no table, no write.
   - No Flutter call site exists for call/website/navigate taps.

6. **Leaderboard paging and community selector are missing.**
   - `rankings_provider.dart` fetches page 1 only and discards `meta.hasMore`.
   - `leaderboard_screen.dart` has `_communityId` but no `onCommunityChanged`/dropdown.
   - No `/communities/mine` endpoint exists to populate a selector (membership data is only available indirectly).

7. **Active trip is not available offline.**
   - `fetchTripsHub` and `fetchActiveTripDetail` are network-only.
   - Saved plans and wishlist silently fall back to cache for *any* failure, including server errors, with no "showing offline copy" indicator.

8. **Chat image messages are a text marker.**
   - Works visually today, but breaks on whitespace/format changes and prevents clients from distinguishing images from text.

9. **Edit Profile cannot change the cover image.**
   - The repository accepts `coverImageUrl`, but the sheet exposes only an avatar picker and keeps a raw "Avatar URL" text field.

### P2 — Production hardening / completeness

10. **Push notifications are not implemented.** Blocked on Firebase project credentials (`google-services.json`, `GoogleService-Info.plist`, service account). Do not add packages that cannot be initialised.
11. **27 `NetworkImage` usages bypass disk caching.**
12. **No upload rate limit, magic-byte validation, or orphan cleanup.** Files accumulate forever; deleted flags/avatars leave files behind.
13. **Public OSRM demo server** (`router.project-osrm.org`) is not for production traffic; no caching or per-user throttle; no handling of OSRM's usage policy.
14. **No offline banner / automatic refresh** on reconnect for the cached read paths.
15. **Trip planner / home map** do not use road geometry.
16. **Uploads are on local disk.** Multi-instance deployments need S3/R2 (as the original plan noted) or a shared volume.

---

## 4. Implementation plan

### Phase 1 — Correct media round trip (P0, this pass)

- Add `AppConfig.mediaOrigin` + `AppConfig.resolveMediaUrl()` that turns `/uploads/...` into an absolute URL on the configured host (and leaves absolute URLs untouched).
- Normalise media fields at model boundaries (`ApiUser`, `ApiFlag`, `ApiWonder`, community/clan/trip/rally models) so every widget — cached or not — receives a usable URL.
- Return absolute URLs from `POST /v1/upload` using `PUBLIC_BASE_URL` when set, otherwise the request origin; keep relative storage compatibility by also resolving client-side.
- Create the uploads directory with `fs.mkdirSync(..., { recursive: true })` at module load.
- Derive the stored extension from the accepted MIME type (`jpeg → .jpg`, `png → .png`, `webp → .webp`).
- Map `LIMIT_FILE_SIZE → 413 IMAGE_TOO_LARGE`, `LIMIT_UNEXPECTED_FILE → 400`, invalid MIME → `400`.

**Acceptance:** upload a PNG with a real JWT, paste the returned URL into the app's flag/profile flow, confirm the image renders after an app restart; upload a 6 MB file and get `413`; upload a `.txt` and get `400`.

### Phase 2 — Real service inquiries (P1, this pass)

- Add Prisma model `ServiceInquiry` (`id`, `serviceProviderId`, `userId`, `type`, `createdAt`) with relations and indexes.
- Replace the fabricated response with `prisma.serviceInquiry.create`; validate `type ∈ {CALL, WEBSITE, NAVIGATE}`; 404 for unknown providers.
- Add `TeritoryRepository.recordServiceInquiry(providerId, type)`.
- Fire it (best-effort, non-blocking) from the call, website and navigate actions in `gear_service_sheet.dart`.

**Acceptance:** tapping Call/Website/Navigate produces a `201` and a row in `service_inquiries`; an unknown provider returns `404`; a signed-out tap still opens the dialer (analytics must never block the action).

### Phase 3 — Leaderboard pagination + community selector (P1, this pass)

- Backend: `GET /v1/communities/mine` returns communities the caller belongs to (membership-scoped, before `/:id`).
- Repository: `fetchLeaderboardPage()` returning entries + `hasMore`/`total`/`page` from `meta`; keep `fetchLeaderboard()` as a page-1 wrapper for facets.
- Provider: a paged feed notifier per `LeaderboardQuery` with `loadMore()` and `refresh()`.
- Screen: append pages on scroll near the end, bottom progress indicator, and a Community dropdown beside the existing Clan dropdown.

**Acceptance:** selecting a clan/community filters the board; scrolling past the first page appends without duplicating ranks; `hasMore=false` stops requests; signing out keeps the existing honest error state.

### Phase 4 — Offline read cache for trips (P1, this pass)

- Extend `OfflineCacheService` with `cacheTripsHub` / `getCachedTripsHub` and per-trip detail caches.
- In `fetchTripsHub` / `fetchActiveTripDetail`, cache successful payloads and use the cache **only for network failures**, not for `ApiException` responses (server refusals stay visible).
- Tighten saved plans/flags fallbacks to the same rule.
- Add a "showing saved copy" note on the trips hub when cached data is used (optional; see Phase 6).

**Acceptance:** load the trips hub online, disable networking, reopen → the active trip and plans render; force a `500` → the error is shown, not stale data.

### Phase 5 — Structured chat images (P1)

- Add `imageUrl String?` to `CommunityMessage`; accept/validate it in `sendCommunityMessage`; emit it over the socket.
- Client: `sendMessage(text, {imageUrl})`; upload then send with `imageUrl`; bubble prefers `imageUrl`, falling back to the legacy `[Photo]` marker for old rows.

**Acceptance:** send a photo with no caption → bubble renders the image; old `[Photo]` rows still render; a text-only message is unchanged.

### Phase 6 — Offline banner and refresh (P2)

- Global connectivity stream provider (reuse the pattern in `flag_queue_provider.dart`).
- Slim banner in the app shell when offline; invalidate the read providers when connectivity returns.
- Only after Phase 4 so the banner has cached content to show.

### Phase 7 — Remaining image caching (P2)

- Replace the 27 `NetworkImage` avatars with `CachedNetworkImageProvider(AppConfig.resolveMediaUrl(...))`.
- Add a small shared `TeritoryAvatar` widget so future screens cannot regress to uncached images.

### Phase 8 — Push notifications (blocked)

- Requires the user's Firebase project. Steps when credentials exist: `firebase_core` + `firebase_messaging`, permission request, token refresh → `PATCH /users/me`, foreground handler, `firebase-admin` + `sendPush` in the notification service, invalid-token cleanup.
- Until then the backend field stays dormant and no UI claims push is enabled.

### Phase 9 — Production hardening (P2/P3)

- Upload magic-byte sniffing, per-user upload throttle, file deletion on flag/avatar replacement, orphan sweeper.
- Move uploads to S3/R2 presigned URLs for multi-instance deploys (`PUBLIC_BASE_URL` + `UPLOAD_DRIVER`).
- Replace the public OSRM demo with a self-hosted/paid routing endpoint, cache directions by waypoint signature, throttle per user.
- Road geometry in the trip planner preview and the home map overlay.

---

## 5. Verification log

| Check | Result |
|-------|--------|
| `flutter analyze` (baseline) | 0 issues |
| `flutter analyze` (after this pass) | **0 issues** |
| `git status -sb` (audit start) | `develop...origin/develop`, one trailing-newline change |
| `node --check` on upload/errorHandler/services/communities files | **all OK** |
| `npx prisma validate` | **valid** |
| Additive SQL applied (`ServiceInquiryType`, `service_inquiries`, `community_messages.imageUrl`) | **applied via `migrate diff` + `db execute`** (not `db push`, to avoid dropping `saved_flags`) |
| `POST /v1/upload` valid PNG | **201**, absolute URL, `GET` returns **200 image/png** |
| `POST /v1/upload` 6 MB file | **413 `IMAGE_TOO_LARGE`** |
| `POST /v1/upload` text/plain | **400 `INVALID_IMAGE_TYPE`** |
| `POST /v1/services/:id/inquiry` valid | **201** with a UUID row; row verified in `service_inquiries` |
| inquiry invalid type / unknown provider | **400 `BAD_REQUEST`** / **404 `NOT_FOUND`** |
| `GET /v1/rankings?limit=2&page=1` | `n=2`, `hasMore=true`, `total=6`; page 2 starts at rank 3 |
| `GET /v1/communities/mine` | `200`, membership-scoped list |
| Chat image message | **201** with `imageUrl: /uploads/...`; history returns it; `javascript:` URL rejected with **400** |
| Test data cleanup | test inquiry rows deleted, test chat message deleted, test upload file removed |
| Targeted Flutter tests (`pending_flag_queue`, `explore_location_query`, `widget_test`) | **13/13 passed** |
| Full `flutter test` | **44 passed, 3 failed** — two live tests hit the known 25 m duplicate-flag `409` from earlier runs (`live_sub_spots`, `live_wonders`), and `live_trip_plan_flow` timed out at 15 s on a cold database. All three are pre-existing shared-DB flakiness in live tests, not in the changed paths. |

**Not verified:** pending-pin/offline banner visuals on a device, airplane-mode round trip, push notifications (blocked), real Firebase dispatch.

---

## 6. Implemented in this pass

- `AppConfig.mediaOrigin` + `resolveMediaUrl`; model-level normalisation for users, flags, wonders, clans, communities, trips, rallies and leaderboard avatars.
- Upload endpoint: absolute URLs, directory creation, MIME-derived extensions, mapped multer errors, `INVALID_IMAGE_TYPE` code.
- `ServiceInquiry` model + relations, validated and persisted inquiries, `TeritoryRepository.recordServiceInquiry`, and fire-and-forget tracking from call/website/navigate.
- Leaderboard: `LeaderboardPage` with `meta`, `getEnvelope`, paged `LeaderboardFeedNotifier`, auto-load + Load More footer, Community dropdown and `GET /communities/mine`.
- Offline: trips-hub + active-trip caching, cache only on network failures, legacy `saved_flags` untouched.
- Chat: `CommunityMessage.imageUrl`, send validation, backwards-compatible rendering.
- Trip planner: OSRM road geometry with straight-line fallback, guarded by a waypoint signature.
- New actionable endpoint list: `GET /communities/mine`, `POST /services/:id/inquiry` now real.

## 7. Still remaining (ranked)

1. **Push notifications** — blocked on Firebase credentials; no code claims it works.
2. **27 `NetworkImage` avatars** — URLs are now correct, but they still bypass disk caching. Replace with `CachedNetworkImageProvider`/a shared avatar widget.
3. **Upload hardening** — magic-byte validation, per-user throttle, delete orphaned files when a flag/avatar is replaced, and an orphan sweeper.
4. **Object storage** — local disk breaks multi-instance deploys; add S3/R2 behind `UPLOAD_DRIVER`.
5. **Offline banner + reconnect refresh** — connectivity stream exists for the flag queue; reuse it globally.
6. **Production routing** — replace the public OSRM demo, cache by waypoint signature, throttle per user; add the home-map overlay.
7. **Edit-profile cover picker** — repository supports `coverImageUrl`; the sheet only uploads avatars.
8. **Chat authorisation** — `POST /communities/:id/messages` does not verify membership before writing; add a `communityMember` check.
9. **Schema drift** — the dev database still has a legacy `saved_flags` table not present in `schema.prisma`; `prisma db push` wants to drop it. Decide whether to migrate it into `SavedFlag` or drop it deliberately.

## 8. Explicit blockers / decisions

- **Firebase**: cannot be completed without project credentials. Do not add dormant packages that break `flutter analyze`/startup.
- **Object storage**: local disk is acceptable for the single-instance dev deployment documented in `deployment_guide`; multi-instance requires S3/R2. Not changing storage provider in this pass.
- **OSRM**: keep the public demo for development only; document the production swap.
- **Schema changes** (ServiceInquiry, chat imageUrl): additive only. The dev database was updated with `prisma migrate diff` + `db execute` because `db push` wanted to drop the legacy populated `saved_flags` table. **Every deployed environment needs the same additive migration before this code runs**, and the repo currently has no `prisma/migrations` history.
- **Concurrent edit:** commit `84f49be` reverted `recordInquiry` to the fabricated response while this audit was running; the persisted version was re-applied and is currently an uncommitted working-tree change. It must be committed to keep the fix.
