# Teritory - Project Overview

> **"Claim Your Footprint, Share the Globe."**

---

## 1. Executive Summary
**Teritory** is a next-generation social travel platform crafted for modern explorers, backpackers, road-trippers, and global wanderers. Built with Flutter and inspired by the live spatial map experience of OnWay, Teritory turns the entire planet into an interactive, communal canvas of verified travel achievements.

Whenever users travel to any destination—from bustling metropolitan alleys and hidden seaside cafes to iconic UNESCO World Heritage wonders and high-altitude summits—they can **drop a Flag** to stake their presence, capture memories, and verify their journey.

Teritory connects travelers through a shared global geography where friends and fellow explorers see real-time and historical flags, discover hidden gems, celebrate major travel milestones, and build passionate travel tribes.

---

## 2. Core Value Propositions

### 📍 Proof of Journey (Geographic Footprint)
Instead of static photo grids, every memory is tied to real coordinates on an interactive OpenStreetMap canvas. Travelers can look back at their life journey mapped across cities, countries, and continents.

### 🚩 Major Flags vs. Casual Flags
Travel achievements are clearly tiered:
- **Major Flags (Wonder Gold `#F59E0B`)**: Globally recognized iconic landmarks, high-altitude peaks, UNESCO World Heritage sites, and ancient monuments (e.g. Taj Mahal, Colosseum, Machu Picchu, Mount Everest Base, Great Wall of China).
- **Casual / Local Flags (Territory Coral `#FF5330`)**: Secret cafes, serene viewpoints, street markets, highway pit stops, camping spots, and personal chill zones.

### 🌊 Midnight Oceanic & Daylight Basemap Architecture
Teritory features a proprietary zero-API-key, 100% open-source map theming engine:
- **Midnight Oceanic (Default)**: Deep oceanic sapphire/teal waters (`#07345A`), midnight obsidian slate urban land (`#000C2C`), and deep emerald vegetation (`#092732`), engineered with a custom 4x5 color matrix filter over OpenStreetMap tiles. Completely free from third-party watermarks or API key requirements.
- **Daylight White Map**: Clean daytime cartography with crisp contrast and daylight readability.
- Both the Home Explorer map and the Profile World map are synchronized to this unified dual-theme engine.

### 👥 Living Social Explorer
The home screen is a full-bleed interactive map where users immediately see:
- Their current location with a single-tap **"Flag My Teritory"** action.
- Friends and contacts who have previously or recently flagged spots nearby.
- An interactive bottom friends carousel and categorized filter chips (`All`, `Friends`, `My Flags`, `Major Wonders`).

### 🏆 Gamified Nomad Profile
Travelers earn badges, passport stamps, nomad rankings (from *Local Scout* to *Global Cartographer*), and continent progress meters (e.g., 5/7 continents unlocked, 18 countries flagged, 14 Major Flags earned).

---

## 3. Brand Identity & Design Language
- **Brand Identity**:
  - **Logo**: A modern geometric summit flag integrated into a circular compass-globe mark.
- **Color Palette**:
  - `Territory Coral`: `#FF5330` (Primary CTA, flag drop action, high-energy highlights)
  - `Midnight Oceanic Slate`: `#0F172A` & `#1E293B` (Cards, sheet surfaces, premium dark tones)
  - `Oceanic Teal / Sapphire`: `#07345A` & `#38BDF8` (Water bodies, friend pins, active indicators)
  - `Wonder Gold`: `#F59E0B` & `#D97706` (Major Flags, trophies, UNESCO badges)
  - `Emerald Route`: `#10B981` (Verified GPS indicator, passport active stamps)
  - `Surface Light`: `#F8FAFC` & `#FFFFFF` (Clean daylight cards)
- **Typography**: Clean, readable, and modern via Google Fonts `Plus Jakarta Sans`.

---

## 4. Architectural Roadmap & Delivery Status

### Phase 1: Interactive Prototype & Design Verification (COMPLETED ✅)
- Flutter cross-platform architecture (`teritory/lib`).
- High-performance vector map using `flutter_map` + OpenStreetMap tiles.
- Custom mathematical 4x5 color matrix for **Midnight Oceanic** theme and instant toggle to **Daylight White**.
- Reactive data architecture via `TeritoryDataService` (`assets/data/teritory_data.json`).
- Complete page implementations: Home Explorer Map, Profile World Map, Community Tribes Feed, Wonders Registry.
- Interactive flag dropping (`DropFlagModal`) and detailed inspection sheet (`FlagDetailSheet`).
- Release APK built, optimized with ProGuard, and verified live on hardware device (`Motorola Edge 2022`).
- Integrated into parent repository on branch `develop`.

### Phase 2: Realtime Backend & Spatial Cloud API (Next)
- High-performance API backend.
- Spatial database queries (PostGIS / Lakebase Postgres).
- Cloud storage for user photos with global CDN presigned uploads.
- Real-time WebSocket pub/sub for live friend flag drops and nearby alerts.
- GPS anti-spoofing and location verification algorithms.

### Phase 3: Community & Global Ecosystem
- Collaborative Travel Tribes and shared group expeditions.
- Offline flag caching for remote backcountry travels.
- Proximity-based Bluetooth/NFC passport stamping between fellow travelers.
