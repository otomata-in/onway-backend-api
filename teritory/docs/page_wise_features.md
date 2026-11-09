# Teritory - Page-Wise Feature Specifications

This document defines the functional and UI specifications for every key screen in the **Teritory** mobile application.

---

## Screen 1: Home Map & Live Flag Explorer (Primary Screen)

### Objective
Inspire spontaneous exploration by putting the full-screen interactive map front and center. Show who has explored what around the user, and allow instant flagging of the user's current coordinates.

### Key Elements & Functionality
1. **Interactive Full-Screen OpenStreetMap Canvas**:
   - Smooth panning, pinch-to-zoom, and rotation via `flutter_map`.
   - Default camera centered at the user's current city/coordinates.
   - Quick "Recenter to My Location" compass button.
2. **Current Location Pulsing Beacon**:
   - High-contrast visual ring showing real-time GPS accuracy.
3. **Map Pins & Social Flag Markers**:
   - **User Flags**: Vibrant Territory-Orange flags.
   - **Friend / Contact Flags**: Custom pins featuring the friend's profile avatar badge, colored flag tag, and quick tap interaction.
   - **Major Landmark Beacons**: Golden star/gem badges indicating UNESCO / iconic wonders.
4. **Interactive Flag Detail Bottom Sheet**:
   - Tapping any flag pops a sleek frosted glass bottom sheet.
   - Displays: Place name, Country, Flagged by (User or Friend), Timestamp/Date, Story/Caption, Photo thumbnail, and "Visited by X friends".
   - Actions: "High Five / Kudos", "Add to My Bucket List", "View Directions".
5. **Prominent Flag Action Button ("Drop Flag Here")**:
   - Floating Action Pill: `🚩 Flag My Teritory`.
   - Opens the quick flag drop modal:
     - Auto-detected location name (with edit option).
     - Select category (Iconic Landmark, Hidden Gem, Scenic Viewpoint, Local Food, Camp/Stay).
     - Upload travel photo / selfie.
     - Add private or public travel notes.
     - Toggle: "Mark as Major Wonder" (if verified).
6. **Top Header Bar**:
   - App branding: **TERITORY** with an orange flag logo.
   - Friends filter chip (`All Flags`, `Friends Only`, `Major Wonders`).
   - Search bar to jump to any city or country on earth.

---

## Screen 2: Traveler Profile & Global Footprint Map

### Objective
Showcase a traveler's lifelong adventures in one unified, breathtaking view. Highlight their achievements, passport badges, and statistics across continents.

### Key Elements & Functionality
1. **Global Footprint Mini-Map**:
   - A single interactive world map view displaying **all the user's flagged spots** spanning across continents (e.g. Asia, Europe, Americas).
   - Zoom out to see the entire world with connected flight lines, or zoom into specific clusters.
2. **Key Travel Milestone Counters (Stats Row)**:
   - **Total Flags**: E.g., `42 Flags`.
   - **Major Flags**: E.g., `12 Major Wonders` (Highlighted in gold with trophy icon).
   - **Countries Visited**: E.g., `8 Countries`.
   - **Continents Explored**: E.g., `3 Continents`.
3. **Nomad Rank & Reputation Card**:
   - Current rank (e.g., `Level 4: Continental Roamer`).
   - XP progress bar to the next rank (`780 / 1000 XP`).
   - Earned Title & Bio (e.g., *"Himalayan trekker & coastal backpacker 🏔️🌊"*).
4. **Flag Gallery & Filterable List**:
   - Filter pills: `All Flags`, `Major Flags Only`, `Nature & Peaks`, `Heritage & Culture`.
   - Rich card list showing:
     - Location Name & Country flag emoji (e.g., *Colosseum, Rome 🇮🇹*).
     - Major Wonder badge tag.
     - Date flagged and coordinates.
     - Photo thumbnail and notes.
5. **Passport Stamps & Trophy Shelf**:
   - Grid of stamped badges (e.g. *Eiffel Tower Stamped*, *Taj Mahal Stamped*, *Mount Fuji Pioneer*).

---

## Screen 3: Social Hub & Travel Tribes (Community)

### Objective
Build active travel communities, follow adventurous friends, discover curated travel lists, and participate in global challenges.

### Key Elements & Functionality
1. **Activity Feed**:
   - Stream of recent flags dropped by friends and followed travelers worldwide.
   - Interactive kudos, comments, and travel recommendations.
2. **Traveler Leaderboard**:
   - Top globetrotters this month by Major Flags unlocked and new territories claimed.
3. **Travel Tribe Expeditions**:
   - Group challenges (e.g. *"Monsoon Western Ghats Circuit"* or *"Euro Rail 2026"*).
   - Join group and contribute flags to the shared tribe map.

---

## Screen 4: Explore & Major Wonder Catalog

### Objective
A curated registry of the world's most famous destinations, natural wonders, and cultural monuments that users can target to flag.

### Key Elements & Functionality
1. Curated collections: *The New 7 Wonders of the World*, *UNESCO Heritage Trails*, *Alpine Summits*, *Ancient Temples*.
2. Status indicators: `[Claimed ✓]` vs `[Unexplored]`.
3. Quick search by continent, country, or difficulty.
