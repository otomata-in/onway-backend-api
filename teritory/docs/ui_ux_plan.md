# Teritory - UI / UX Design Plan & Architecture

## 1. Visual Theme & Aesthetics
- **Style**: Modern, clean, neo-tactile cartography with subtle glassmorphic overlays.
- **Palette**:
  - `Primary / Ember Orange`: `#FF5330` (Flags, active CTA, vibrant highlight)
  - `Secondary / Wonder Gold`: `#EAB308` & `#CA8A04` (Major Flags, trophies, UNESCO badges)
  - `Dark Navy / Slate`: `#0F172A` and `#1E293B` (Text, headers, high-contrast badges)
  - `Background Canvas`: `#F8FAFC` (Clean daylight UI)
  - `Card / Surface`: `#FFFFFF` with soft shadows (`0 8px 24px rgba(15, 23, 42, 0.08)`)
  - `Success / Forest`: `#10B981` (Verified GPS indicator, passport active stamp)
- **Typography**: Google Fonts `Plus Jakarta Sans` for modern geometric clarity and readability.

---

## 2. Navigation Architecture
A floating bottom navigation bar with 4 core views:
1. **🗺️ Home Map**: Fullscreen interactive explorer map with friend flags and instant flag drop FAB.
2. **🌍 Global Footprint**: Dedicated global view of all personal flags across continents with zoom presets.
3. **👥 Community**: Social feed of friend flags, travel tribes, and globetrotter leaderboards.
4. **👤 Travel Profile**: Passport stamps, nomad rank, major flags counter, and comprehensive flag collection.

---

## 3. Data Structure (Static Mock JSON)
To power all screens reliably with realistic, rich data:
- `currentUser`: Name, avatar, handle, nomad level, stats (total flags, major flags, countries, continents, passport stamps).
- `userFlags`: Complete list of personal flags (including lat, lng, city, country, isMajorFlag, category, date, photos, notes).
- `friendFlags`: Pins dropped by friends (friendName, avatar, placeName, lat, lng, note, date, likes, photos).
- `majorWonders`: Curated world wonders (Taj Mahal, Colosseum, Machu Picchu, Mount Everest Base, Great Wall, Santorini, Grand Canyon).
- `travelTribes`: Active community groups with expedition goals.
