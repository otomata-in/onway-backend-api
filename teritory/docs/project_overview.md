# Teritory - Project Overview

> **"Claim Your Footprint, Share the Globe."**

## 1. Executive Summary
**Teritory** is a next-generation social travel platform built for modern explorers, backpackers, road-trippers, and global wanderers. Inspired by the interactive map experience of OnWay, Teritory turns the world into a personal and communal travel canvas.

Whenever users travel to any destination—from bustling metropolitan alleys and hidden seaside cafes to iconic UNESCO world heritage wonders—they can **drop a Flag** to stake their presence, capture memories, and verify their journey.

Teritory connects travelers through a shared global geography where friends and fellow explorers see real-time and historical flags, discover hidden gems, celebrate major travel milestones, and build passionate travel tribes.

---

## 2. Core Value Propositions

### 📍 Proof of Journey (Geographic Footprint)
Instead of static photo grids, every memory is tied to true coordinates on a rich, interactive OpenStreetMap canvas. Travelers can look back at their life journey mapped across continents.

### 🚩 Major Flags vs. Casual Flags
Travel achievements are tiered:
- **Major Flags**: Globally celebrated wonders, national landmarks, high-altitude peaks, UNESCO heritage sites, and premier natural spectacles.
- **Local / Casual Flags**: Secret cafes, serene viewpoints, street markets, highway pit stops, and personal chill spots.

### 🌐 Living Social Map
The home screen is a full-bleed interactive map. Users immediately see:
- Their current location with a single-tap **"Flag This Teritory"** action.
- Friends and contacts who have previously or recently flagged spots nearby.
- Heatmaps and clusters of travel friends discovering the world.

### 🏆 Gamified Nomad Profile
Travelers earn badges, passport stamps, nomad rankings (from *Local Scout* to *Global Cartographer*), and continent progress meters (e.g. 5/7 continents unlocked, 18 countries flagged, 14 Major Flags earned).

---

## 3. Brand Identity & Design Language
- **Brand Colors**:
  - `Territory Ember / Coral`: `#FF5A36` (Flag drop, passion, discovery)
  - `Deep Ocean Navy`: `#0F172A` (Night map, elite status, premium dark tones)
  - `Emerald Route`: `#10B981` (Visited routes, verified flags, eco journeys)
  - `Golden Sun / Wonder Gold`: `#F59E0B` (Major Flags, trophies, UNESCO badges)
  - `Surface Frost`: `#F8FAFC` & Pure White `#FFFFFF` (Clean, glassy modern cards)
- **Typography**: Clean, readable, and modern via Google Fonts (`Plus Jakarta Sans` or `Outfit`).

---

## 4. Architectural Roadmap
1. **Phase 1: Interactive Prototype & UI Showcase (Current)**
   - Flutter cross-platform architecture.
   - Interactive OpenStreetMap integration (`flutter_map` + OSM tiles).
   - Rich mock dataset (`teritory_data.json`) covering home map, user profile, friend flags, and major wonder registries.
   - Android APK build for hands-on evaluation.

2. **Phase 2: Realtime Backend & Cloud Synchronization**
   - High-performance API backend.
   - Spatial database queries (PostGIS / Lakebase Postgres).
   - Photo storage (S3 / Cloud storage with CDN).
   - GPS anti-spoofing and location verification.

3. **Phase 3: Community & Global Ecosystem**
   - Travel tribes, expedition planning, group flags.
   - Offline flag caching for remote backcountry travels.
   - NFC/Bluetooth proximity passport stamping.
