# Teritory - Page-Wise Feature Specifications

This document defines the functional and UI specifications for every key screen, modal, and component in the **Teritory** mobile application.

---

## Screen 1: Home Map & Live Flag Explorer (`HomeMapScreen`)

### Objective
Inspire spontaneous exploration by putting the full-screen interactive map front and center. Show who has explored what around the user, and allow instant flagging of the user's current coordinates.

### Key Elements & Functionality
1. **Interactive Full-Screen OpenStreetMap Canvas**:
   - Smooth panning, multi-touch pinch-to-zoom, and inertial scrolling via `flutter_map`.
   - Default camera centered at the user's current city/coordinates (e.g., Kochi center at `9.9790, 76.2760`).
   - 100% open-source and free tiles (`tile.openstreetmap.org`) with zero watermarks or API key requirements.
2. **Dual-Theme Map Engine**:
   - **🌊 Midnight Oceanic (Default)**: Deep oceanic sapphire/teal waters (`#07345A`), midnight obsidian slate urban land (`#000C2C`), and deep emerald vegetation (`#092732`), powered by an in-memory 4x5 color matrix filter.
   - **☀️ Daylight White Map**: Clean daylight cartography with crisp daytime contrast.
   - Floating theme toggle button allows one-tap switching between Oceanic and Daylight modes.
3. **Current Location Pulsing Beacon**:
   - Concentric animated ripple beacon showing real-time GPS presence with high-contrast core.
4. **Map Pins & Social Flag Markers**:
   - **User Flags**: Vibrant Territory-Coral markers (`#FF5330`).
   - **Friend / Contact Flags**: Custom pins featuring the friend's profile avatar badge, colored flag tag, and quick tap interaction.
   - **Major Landmark Pins**: Gilded golden badges (`#F59E0B`) indicating UNESCO / iconic wonders.
5. **Top Navigation Scrim & Header**:
   - Custom scalable **Teritory Logo** vector mark.
   - Live badge: `X Friends Active`.
   - Horizontal Filter Chips: `All`, `Friends`, `My Flags`, and `Major Wonders`.
6. **Bottom Friends Discovery Carousel**:
   - Horizontally scrolling cards highlighting recent flags dropped by contacts.
   - Tapping a card animates the map camera directly to that friend's flag coordinates.
7. **Floating Action Controls**:
   - **Recenter Compass FAB**: Snaps map back to user's real-time beacon.
   - **Theme Switcher FAB**: Toggles between Midnight Oceanic and Daylight modes.
   - **Primary Action Pill**: Floating `🚩 Flag My Teritory` button centered above bottom nav.

---

## Screen 2: Traveler Profile & Global Footprint Map (`ProfileScreen`)

### Objective
Showcase a traveler's lifelong adventures in one unified, breathtaking view. Highlight their achievements, passport badges, and statistics across continents.

### Key Elements & Functionality
1. **Macro-to-Micro Worldwide Flag Map**:
   - A dedicated interactive world map viewport (270px height) displaying **all the user's flagged spots** spanning across continents (Asia, Europe, Middle East, Americas) in a single unified view.
   - Synchronized map styles: Header toggle pills allow instant switching between **🌊 Oceanic** and **☀️ Daylight**.
   - **Quick Zoom Continent Chips**: Instant one-tap navigation presets:
     - `🌍 World` (Broad global overview)
     - `🇮🇳 India / Asia` (South Asian and East Asian clusters)
     - `🇪🇺 Europe` (Continental European route)
     - `🇦🇪 Middle East` (Arabian Peninsula landmarks)
2. **Prominent Major Flags vs. Total Flags Display**:
   - Golden trophy card highlighting:
     - **Major Flags Count**: E.g., `14 Major Flags` (Iconic UNESCO wonders & national landmarks).
     - **Total Flags Count**: E.g., `42 Total Spots`.
     - **Countries Visited**: E.g., `8 Countries`.
     - **Continents Explored**: E.g., `3 Continents`.
3. **Nomad Rank & Reputation Card**:
   - Current rank badge (e.g., `Level 4: Continental Roamer`).
   - XP progress bar toward next rank (`780 / 1000 XP`).
   - Custom bio and traveler credentials.
4. **Verified Passport Stamps Shelf**:
   - Horizontal shelf of digital passport stamps earned by visiting verified major locations (e.g. *Eiffel Tower Stamped*, *Taj Mahal Stamped*, *Colosseum Stamped*).
   - Tapping any stamp opens an inspection card with verification date and monument details.
5. **Filterable Flag Gallery & Timeline**:
   - Category filter chips: `All Flags`, `Major Flags Only`, `Asia`, `Europe`.
   - Rich card items with location name, country emoji, flag badge, visited date, coordinates, and photo thumbnail.
   - Tapping any item opens the full `FlagDetailSheet`.

---

## Screen 3: Social Hub & Travel Tribes (`CommunityScreen`)

### Objective
Build active travel communities, follow adventurous friends, discover curated travel lists, and participate in global challenges.

### Key Elements & Functionality
1. **Travel Tribe Expeditions**:
   - Shared group cards (e.g., *Himalayan Trekkers*, *Euro Rail Nomads*, *Monsoon Explorers*).
   - Displays tribe member count, total flags staked collectively, and active expedition targets.
2. **Global Activity Stream**:
   - Chronological feed of recent flags dropped by friends and followed globetrotters worldwide.
   - Real photos, traveler notes, and location tags.
   - Interactive kudos ("High-Five") counters and social comments.
3. **Monthly Globetrotter Leaderboard**:
   - Ranks top community explorers by Major Flags unlocked and new territories claimed.

---

## Screen 4: Explore & Major Wonder Catalog (`WondersCatalogScreen`)

### Objective
A curated registry of the world's most famous destinations, natural wonders, and cultural monuments that users can target to flag.

### Key Elements & Functionality
1. **Curated Collections**:
   - *The New 7 Wonders of the World* (Taj Mahal, Colosseum, Machu Picchu, Great Wall of China, Petra, Christ the Redeemer, Chichen Itza).
   - *UNESCO World Heritage Trails*.
   - *Alpine Summits & Extreme Peaks*.
2. **Claim Status Verification**:
   - Visual status badges: `[Claimed ✓]` in gold vs `[Unexplored]` in subtle slate.
   - Displays required coordinates, country, and historical significance.
3. **Search & Continent Filters**:
   - Quick search bar by monument name, country, or continent.

---

## Shared Modals & Interactive Sheets

### 1. Drop Flag Modal (`DropFlagModal`)
- Triggered by `🚩 Flag My Teritory` button.
- Auto-detects GPS coordinates and pre-fills the location name.
- Custom location title and notes input.
- Category selector: *Iconic Landmark*, *Hidden Gem*, *Scenic Viewpoint*, *Local Food*, *Camp/Stay*.
- Toggle: "Mark as Major Wonder" (highlights in Wonder Gold).
- Reactive state persistence via `TeritoryDataService.addFlag(...)`, updating maps and stats in real time.

### 2. Flag Detail Bottom Sheet (`FlagDetailSheet`)
- Frosted glass bottom sheet triggered by tapping any map pin or flag card.
- Displays:
  - Hero destination imagery.
  - Location title, country, and exact GPS coordinates.
  - Author avatar, traveler name, and visited date.
  - Traveler notes and story caption.
  - Social actions: "High Five / Kudos" counter, "Add to Bucket List", and "Share Flag".
