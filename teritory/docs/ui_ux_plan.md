# Teritory - UI / UX Design Plan & Architecture

## 1. Visual Theme & Aesthetics
- **Style**: Modern, clean, neo-tactile cartography with frosted glassmorphic overlays and high-contrast social badges.
- **Color Palette & Design Tokens**:
  - `Primary / Territory Coral`: `#FF5330` (Flags, active CTAs, interactive highlights)
  - `Secondary / Wonder Gold`: `#F59E0B` & `#D97706` (Major Flags, trophies, UNESCO badges)
  - `Midnight Oceanic Slate`: `#0F172A` and `#1E293B` (Dark map containers, high-contrast badges, cards)
  - `Oceanic Sapphire / Teal`: `#07345A` and `#38BDF8` (Water bodies, friend pin borders, active indicators)
  - `Success / Emerald`: `#10B981` (Verified GPS indicator, passport active stamps)
  - `Background Canvas`: `#F8FAFC` & Pure White `#FFFFFF` (Clean daylight UI)
  - `Border / Divider`: `#E2E8F0` and `#334155`
- **Typography**: Google Fonts `Plus Jakarta Sans` for modern geometric clarity and high readability across dense map data.
- **Logo & Iconography**: Custom scalable vector painter (`TeritoryLogo`) combining a summit flag with an oceanic compass-globe.

---

## 2. Basemap Rendering Engine

### The Problem with Third-Party Tiles
- Traditional dark map providers (e.g. CartoDB Dark Matter) enforce auth tokens and inject watermarks ("API KEY REQUIRED") when used publicly without commercial keys.
- Standard inversion filters produce an unnatural brownish/sepia tint because daylight water tiles (high blue, low red) invert into high red/brown values.

### The Teritory Solution: Mathematical Oceanic Matrix
Teritory uses 100% free, open-source OpenStreetMap tiles transformed on-the-fly via a custom **4x5 ColorFilter matrix**:
```dart
const ColorFilter.matrix(<double>[
  -0.20, -0.15, -0.30, 0.0, 140, // Red suppressed: zero brown/sepia
  -0.45,  0.20, -0.35, 0.0, 165, // Green balanced: deep emerald vegetation
  -0.55,  0.05, -0.05, 0.0, 185, // Blue tuned: rich oceanic sapphire/teal
   0.0,   0.0,   0.0,  1.0, 0,
])
```

### Dual Theme Architecture
Both the **Home Explorer Map** and the **Profile Worldwide Map** are unified to two synchronized modes:
1. **🌊 Midnight Oceanic (Default)**: Deep oceanic teal water, dark emerald vegetation, and midnight obsidian slate land.
2. **☀️ Daylight / White Map**: Clean, daylight OpenStreetMap with high sun contrast.

---

## 3. Navigation Architecture
A floating bottom navigation bar implemented via `MainNavigationShell` (`IndexedStack` preserving state across tabs):
1. **🗺️ Home Map**: Fullscreen interactive explorer map with friend pins, live GPS beacon, bottom friends carousel, and `🚩 Flag My Teritory` FAB.
2. **👥 Community**: Social feed of friend flags, travel tribes, and globetrotter leaderboards.
3. **🏛️ World Wonders**: Registry of UNESCO sites and Seven Wonders with "Claimed" vs "Unexplored" status.
4. **👤 Travel Profile**: Worldwide multi-continental footprint map, Major Flags counter, nomad ranking, passport stamps, and filtered flag gallery.

---

## 4. State Management & Data Architecture
Powered by `TeritoryDataService` (Singleton with `ChangeNotifier`):
- `currentUser`: Name, handle, avatar, nomad level, stats (total flags, major flags, countries, continents, passport stamps).
- `userFlags`: Personal flagged locations (coordinates, city, country, isMajorFlag, category, date, photos, notes). Supports runtime additions via `addFlag(...)`.
- `friendFlags`: Pins dropped by friends (friendName, avatar, placeName, coordinates, note, date, likes, photos).
- `majorWonders`: Curated world wonders (Taj Mahal, Colosseum, Machu Picchu, Mount Everest Base, Great Wall, Santorini, Grand Canyon).
- `travelTribes`: Active community groups with expedition goals.
- `passportStamps`: Collectible digital stamps with verification dates and coordinates.
