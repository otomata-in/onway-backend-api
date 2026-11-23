# Flag Identity & Animation System — Design Plan

Status: phases 1–3 implemented (style model, catalog, shared painter, API persistence, Flag Studio, map/detail/profile/worldwide wiring and the style-aware ceremony); phase 4 polish pending
Scope: Teritory Flutter client (`teritory/`) and Node/Prisma API (`teritory-api/`)

## 1. What exists today (verified in code)

### 1.1 Flag data is content-only

`teritory-api/prisma/schema.prisma` → `model Flag` stores only:
`id, userId, placeName, city, country, countryCode, continent, latitude,
longitude, isMajorFlag, category, notes, photoUrl, kudos, createdAt, updatedAt`.

There is no colour, pattern, shape, emblem, animation or per-user flag style.
`model User` has `mapStyle` (map theme only), `isPrivate`, `isTripMode` — no flag
identity either.

`POST /flags` (`flags.controller.js`) accepts only those content fields.
`GET /flags/explore`, `/flags/:id`, `/flags/saved` and `/flags/wonders` spread
the row, so new fields would flow through automatically, but the owner select is
minimal (`id, displayName, handle, avatarUrl`).

### 1.2 The only flag animation is the one-shot staking ceremony

`teritory/lib/features/flag/presentation/epic_flag_staking_ceremony.dart`:

- 2400 ms timeline: plunge → impact at `t=0.32` → second shove at `t=0.46` →
  unfurl → telemetry card.
- A 1400 ms repeating controller drives the cloth.
- `_FlagStakingPainter` draws the steel pole, gold finial, ground shockwave
  rings, compass seal, cracks, particles, a 24-segment sine-wave cloth with
  amplitude 6, `elasticOut` unfurl, tassels and the text `TERITORY CLAIMED` /
  `★ MAJOR WONDER`.
- Colours are hardcoded: coral `#FF5330/#D63B19` normally, gold
  `#D97706/#F59E0B` for major flags. There is no way to pass a style in.

The ceremony receives only `placeName, city, coordinates, isMajorFlag,
category` through `DroppedFlagInfo`.

### 1.3 The persistent flag on the home map does not animate at all

`home_map_screen.dart`:

- `_buildUserFlagPin` = solid coral/gold rounded label + static
  `Icons.flag_rounded` + arrow. No pole, no cloth, no wave.
- `_buildFriendFlagPin` = avatar pill + static flag icon, border sapphire/gold.
- The only moving map element is `_buildCurrentLocationMarker`, a 2 s pulse.
- `FriendFlag.flagColor` is hardcoded `'#14B8A6'` in `api_flag.dart` and is
  never actually read by the pin.

### 1.4 Every other flag surface is a static icon or a photo

- Profile mini-map, worldwide map: static coral/gold circle with a flag icon.
- Profile flag list: photo thumbnail (or grey image placeholder) + text.
- Explore search rows, carousel cards, friend profile: icon + coral/gold tint.
- Nothing shows the owner's visual identity, and nothing differs between users.

### 1.5 Customization exists only for the map palette

`PreferenceStore` / `MapThemeNotifier` persist `teritory_map_dark` in
SharedPreferences (Midnight Oceanic vs Daylight White). That preference is
device-local and unrelated to flags.

### 1.6 Offline queue would drop any style

`PendingFlag` stores only content fields; `FlagDropRequest` calls `dropFlag`
without a style. If a styled flag is staked offline it would come back with the
default look.

## 2. Product concept: “Flag Atelier”

Give every traveller a **signature flag** — a small, expressive identity that is
consistent everywhere their flags appear — and let them optionally stake a
**one-off expedition flag** with a different look.

Two rules make this coherent:

1. **A flag is a snapshot, not a live reference.** When a flag is staked, the
   chosen style is copied onto the flag row. Changing your signature later does
   not silently rewrite history. An explicit “Apply to my previous flags”
   action can do that when the traveller wants it.
2. **The flag you design is the flag that appears.** Home-map pin, detail sheet,
   profile, worldwide map, carousel, search, ceremony and offline replay all use
   the same style object and the same renderer.

### 2.1 Style dimensions

| Dimension | Options (v1) |
|---|---|
| Theme / palette | **Midnight Tide (blue default)**, Crimson Charge (red), Black Pirate, Neon Hacker, Rider Steel, Golden Summit, Emerald Trail, Sakura Dusk, Desert Mirage, Aurora, Monochrome Ink, Coral Expedition (legacy, demoted) |
| Colour override | Any `#RRGGBB`, plus curated swatches; secondary/accent auto-harmonised from the primary |
| Pattern | Solid, Horizon (two-band), Chevron, Tidal Waves, Sunburst, Constellation, Topographic, Weave |
| Shape | Classic rectangle, Swallowtail, Pennant, Burgee |
| Emblem | None, Compass, Peak, Anchor, Star, Flame, Compass Rose, Paw, Skull, Terminal, Helmet, Road Bike, Mountain Bike, Motorbike, Sedan, SUV, Sports Car |
| Motion | Still, Breeze, Gust, Ripple, Shimmer, Aurora, Storm, Inferno, Neon Pulse |
| Speed | Calm / Steady / Wild (0.5× – 2×) |

Presets combine all of the above so a traveller can get a strong result in one
tap, then fine-tune individual dimensions.

### 2.2 Why these dimensions

- Colour + pattern + emblem give identity without arbitrary artwork, so there is
  no image moderation surface and no asset pipeline.
- Shape changes the silhouette, which is visible even at pin size.
- Motion makes the home map feel alive, but it is a controlled vocabulary with a
  static option and a global “reduce motion” fallback.
- Curated palettes guarantee contrast; the custom colour path derives a readable
  emblem/border colour from luminance instead of trusting the user to choose a
  legible pairing.

## 3. UX

### 3.1 Entry points

- **Settings → Preferences → Flag Studio** — current signature preview, edit,
  save.
- **Profile → Flags section header → Customize** — same studio.
- **Drop Flag sheet** — a “Your Flag” card shows the signature or the one-off
  style, with a `Personalize` button. On save the traveller can choose
  “Use for this flag only” or “Save as my signature too”.
- **Own flag detail sheet** — “Restyle this flag” in a future phase.
- Long-press on your own pin is deliberately not used: it conflicts with map
  gestures and is undiscoverable.

### 3.2 Flag Studio layout

1. Hero animated flag on a pole, against the current map theme backdrop.
2. Preset rail with live mini-flags.
3. Segmented tabs: Theme · Colour · Pattern · Shape · Emblem · Motion.
4. Motion speed slider with three labelled stops.
5. Footer: `Save as my signature` (primary), `Reset`, and, when editing an
   existing signature, `Apply to my previous flags` (secondary, with a confirmation).

Every selection updates the hero instantly. Saving is optimistic but rolls back
and shows the server error if the PATCH fails — no fake success.

### 3.3 Drop Flag integration

- The sheet gets a compact flag preview row between the header and the “Major
  Landmark” card.
- “Personalize” opens the studio in picker mode and returns a `FlagStyle`.
- The chosen style is sent with `POST /flags` and carried into
  `DroppedFlagInfo`, so the staking ceremony unfurls the exact flag.
- If the request fails with no response, the style is persisted in `PendingFlag`
  and replayed later.

## 4. Rendering architecture

No new packages. Pure Flutter `CustomPainter`, `Path`, gradients and one shared
animation clock.

### 4.1 New client files

```
lib/core/models/flag_style.dart
  FlagStyle (immutable, value equality, copyWith, toJson/fromJson, clamp/validate)
  FlagStudioResult

lib/core/theme/flag_style_catalog.dart
  FlagThemeData (id, label, primary, secondary, accent, pole, finial)
  FlagPattern / FlagShape / FlagEmblem / FlagMotion descriptors + labels/icons
  presets, lookup helpers, luminance-based foreground colour

lib/core/widgets/flag/teritory_flag.dart
  TeritoryFlag (size, style, phase, animate, showPole, major, reduceMotion)
  FlagAnimationScope (single ticker + inherited notifier)

lib/core/widgets/flag/flag_cloth_painter.dart
  FlagClothPainter: cloth geometry per shape, wave deformation, palette gradient,
  pattern layer, emblem layer, border/tassels, highlight/finish

lib/features/flag/presentation/flag_studio_screen.dart
  full-screen editor + picker mode

lib/features/flag/presentation/flag_style_preview.dart
  small/medium/hero previews reused by the studio and drop sheet
```

### 4.2 One renderer, many sizes

`TeritoryFlag` is the only thing that draws a flag. It delegates to
`FlagClothPainter`, which:

1. Builds the cloth path for the selected shape.
2. Applies a wave offset `y = f(x, phase, motion, speed)`; the hoist edge stays
   pinned. Breeze = one sine; Gust = three summed sines + larger amplitude;
   Ripple = travelling wave plus a moving highlight; Shimmer = a moving
   specular band; Aurora = palette interpolation over time; Still = no offset.
3. Clips the cloth and paints the palette gradient (theme primary → secondary →
   accent), with the custom colour replacing the primary when set.
4. Paints the pattern procedurally, scaled to cloth width so it looks correct
   from a 36 px pin to a 300 px hero.
5. Paints the emblem in a high-contrast disc near the hoist.
6. Paints the border, tassels and pole/finial. Major flags get a crown/star
   finial as an extra layer, independent of the chosen theme.

The painter takes a logical size and scales everything, so one implementation
serves every surface. `shouldRepaint` compares style, quantised phase and size.

### 4.3 Animation performance on the map

A naive `AnimationController` per marker would be a battery and jank problem.
The plan is:

- **One shared clock** (`FlagAnimationScope`) for the whole home map, not one
  per flag.
- Animate at a capped frame rate for pins (≈30 fps) and full rate for the
  studio/detail hero.
- Animate only a bounded set of pins (recommended: the focused flag plus the
  nearest ~8 visible flags), and only while the map is idle; panning/zooming
  renders static cloth. This keeps the map responsive in dense areas.
- Wrap each pin preview in `RepaintBoundary`.
- Respect `MediaQuery.disableAnimations` / accessible navigation and expose a
  “Still flags on map” fallback for low-power devices. The static style is the
  same painter at phase 0, so nothing looks broken.

### 4.4 Surfaces to update

| Surface | Change |
|---|---|
| Home map own pin | Mini waving flag (style-coloured) + existing place-name chip |
| Home map friend pin | Mini flag in the owner's style + avatar chip |
| Pending pin | Static amber flag with the chosen style, clearly “not staked” |
| Live flag detail | Hero flag header (animated) above/replacing the category chip |
| Profile flag list | Mini flag badge over the photo thumbnail |
| Profile mini-map | Mini flag markers instead of circles |
| Worldwide map | Mini flag markers instead of circles |
| Home carousel | Mini flag badge per card |
| Explore search rows | Mini flag swatch next to the icon |
| Friend profile flag lists | Owner-style mini flag badges |
| Staking ceremony | Uses the chosen style for cloth, pole/finial, shockwave, seal and god rays |

## 5. Data & API

### 5.1 Schema (additive, nullable)

```prisma
model User {
  ...
  flagStyle Json?   // signature flag, null = product default
}

model Flag {
  ...
  flagStyle Json?   // snapshot taken when the flag was staked
}
```

Prisma 5.22 is already in use, so `Json` is supported. Nullable columns mean
existing rows are valid and no backfill is required. The same additive migration
process used for `service_inquiries` applies: `prisma migrate diff` +
`prisma db execute`, never `db push` (it would try to drop `saved_flags`).

### 5.2 Canonical style object

```json
{
  "v": 1,
  "theme": "midnight_tide",
  "color": "#0EA5E9",
  "pattern": "tide",
  "shape": "swallowtail",
  "emblem": "compass",
  "motion": "ripple",
  "speed": 1.0
}
```

Server-side `normalizeFlagStyle(input)`:

- allowlists theme / pattern / shape / emblem / motion ids;
- validates `color` as `#RRGGBB` (or null);
- clamps speed to 0.5–2.0;
- drops unknown keys and always writes `v: 1`;
- throws `400` with a specific message for an unknown value.

It lives in one server module and is used by both the user signature endpoint
and flag creation, so the two cannot diverge. The client catalog mirrors the
same ids; a contract fixture will keep them in sync.

### 5.3 Endpoints

- `PATCH /users/me/flag-style` (auth) — body `{ "style": { ... } }`, validates,
  saves the signature, returns the normalised style. Kept separate from
  `PATCH /users/me` so profile edits and style edits cannot clobber each other.
- `POST /flags` — accepts optional `flagStyle`. Resolution order:
  1. explicit, validated `flagStyle`;
  2. the user's saved signature;
  3. the product default.
  Always writes a concrete snapshot to `flags.flagStyle`.
- `PATCH /flags/style` (auth, optional phase 4) — apply the current signature to
  all of the caller's flags. This powers “Apply to my previous flags”.
- Include `flagStyle` in owner selects for explore / detail / saved / wonders, so
  legacy rows with a null snapshot can fall back to the owner's current
  signature before the default.

Client `ApiFlag` and `ApiUser` gain `FlagStyle style` with a safe fallback;
`toFlagItem()` and `toFriendFlag()` carry it, and the hardcoded
`flagColor: '#14B8A6'` is removed.

### 5.4 Offline & prefs

- `PendingFlag` gains `Map<String, dynamic>? flagStyle` with JSON round-trip;
  `enqueue` and `FlagDropRequest` pass it through.
- `PreferenceStore` caches the last signature locally (`teritory_flag_style`) so
  pins and offline drops keep the right look before the profile request settles.
  The server remains the source of truth; the cache is replaced on profile load.

## 6. Staking ceremony, upgraded

The ceremony becomes a reveal of the traveller's actual flag:

- `DroppedFlagInfo` and `EpicFlagStakingCeremony` accept `FlagStyle`.
- Cloth colours, pattern, emblem, border and pole finish come from the style.
- Shockwave rings, compass seal and god rays use the style's accent instead of
  hardcoded coral/gold.
- Major flags keep the trophy finial and `★ MAJOR WONDER` copy; the style still
  controls the fabric.
- The unfurl uses the same `FlagClothPainter` pattern/emblem code, so the flag
  that lands in the ground is exactly the flag that appears on the map.
- Haptics can vary subtly by motion (Gust gets the stronger second impact), but
  only if it does not make the ceremony feel inconsistent.

## 7. Innovation beyond “more colours”

These are deliberately phased so the core system stays shippable:

1. **Signature vs expedition flag** — a stable identity plus a one-off look for
   a special place. This is the feature no other map app has.
2. **Milestone liveries** — patterns/emblems unlocked by real travel (first
   flag, 5 countries, 10 friends, clan membership). Earned, not purchased, and
   additive to the free catalogue.
3. **Place-aware suggestions** — when dropping at a coastal spot, suggest
   `tidal`/`midnight`; at a peak, suggest `sunburst`/`summit`. Suggestions only;
   the traveller's choice always wins.
4. **Clan/community ribbon** — an optional small ribbon or accent using clan
   colours, so a flag can show both personal and crew identity. Optional and
   off by default to avoid visual clutter.
5. **Living map** — owned flags breathe/wave gently while the map is idle;
   friend flags move at lower amplitude so the traveller's own territory still
   reads first.
6. **Ceremony continuity** — the shockwave, seal and flag all share one palette,
   so the cinematic moment and the persistent pin feel like the same object.
7. **Shareable flag card** — a later export of the flag + place + stats as an
   image. Not in v1.

## 8. Phases

### Phase 1 — Foundation (client-only, no API change)

Implemented. Review the language with
`flutter run -d chrome --target lib/dev/flag_preview_app.dart` (a dev-only
entrypoint; it is not wired into the router). Add `?preset=pirate_black` or
`?theme=crimson_charge` to open on a specific look. Reference renders:
`docs/flag_preview_catalog.png` (blue default) and
`docs/flag_preview_presets.png` (the new identity presets).

- `FlagStyle`, catalog, presets, codec, validation helpers.
- `FlagClothPainter` + `TeritoryFlag` + preview sizes.
- Unit tests for codec/equality/catalog ids; a widget test for static vs
  animated rendering.
- A hidden preview route is enough to review the visual language before wiring
  persistence.

### Phase 2 — Persistence

- Prisma `Json?` columns on `User` and `Flag`.
- `flag_style.js` validator + `PATCH /users/me/flag-style`.
- `POST /flags` style resolution and snapshot; owner select includes signature.
- Client `ApiUser` / `ApiFlag` parsing, repository methods, provider + local cache.
- API tests: valid, invalid, unauthenticated, snapshot immutability.

### Phase 3 — Studio and surfaces

Implemented:

- `FlagStudioScreen`: live hero, quick-start presets, cloth themes, curated
  custom colours, pattern/shape/emblem/motion pickers and wind speed. Saves
  through `PATCH /users/me/flag-style`; a refused save keeps the previous
  signature and shows the API message. Discard confirmation on back.
- Profile entry point: the signature card on your own profile opens the studio
  and updates in place.
- Home map pins (own, friend and pending) draw the flag's snapshot style and
  share one `FlagMotionHost` wind clock.
- Detail sheet banner, profile list cards, profile mini-map and the worldwide
  map draw the real flag instead of generic icons.
- The staking ceremony takes the dropped flag's style: the cloth is the shared
  `FlagClothPainter`, and shockwaves, seal, cracks, god rays, finial, particles
  and HUD accents follow the flag palette.

Still open for phase 4: carousel/search-row flags, friend-profile header,
settings entry point, map animation budget and reduce-motion review.

### Phase 4 — Polish

- Map animation budget/idle behaviour and reduce-motion fallback.
- “Apply to my previous flags”.
- Contrast/a11y pass, haptics, empty/error states.
- `flutter analyze`, targeted tests, live API checks, final verification log.

## 9. Verification plan

- `flutter analyze` → 0 issues.
- Dart unit: style codec, defaults, clamping, palette contrast, catalog uniqueness.
- Widget: studio selection changes preview; save failure surfaces the API error;
  reduce motion renders a static flag; map pin uses the style colours.
- API: `PATCH /users/me/flag-style` 200/400/401; `POST /flags` with, without and
  invalid style; old flag unchanged after signature change; explore/detail
  return style; persisted row contains the snapshot.
- Live checks against the dev API, then clean up test flags and styles.
- Migration applied with the additive diff/execute flow; confirm `saved_flags`
  is untouched.

## 10. Decisions to confirm before execution

1. **Signature changes** → new flags only by default, with an explicit “apply to
   previous flags” action. (Recommended.)
2. **Map animation** → default on, but bounded to the focused flag + nearest ~8
   and paused while panning. Static fallback available. (Recommended.)
3. **Custom colour** → free `#RRGGBB` picker plus curated swatches, with
   auto-derived readable foreground. (Recommended.)
4. **Unlockables** → not in v1; free catalogue first, milestone liveries later.
5. **Clan ribbon** → later, optional, off by default.
6. **Shapes/emblems** → 4 shapes and 17 emblems in v1 (travel, pirate, hacker, rider, three bikes and three cars); more can be added to the catalog without schema changes.

None of these require new dependencies, uploads or moderation tooling.
