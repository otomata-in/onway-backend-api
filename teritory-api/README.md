# 🏴 Teritory Standalone Backend API (`teritory-api`)

Standalone microservice for the **Teritory** travel expedition platform.

---

## Tech Stack
- **Runtime**: Node.js 22 LTS + Express
- **Database**: Neon Serverless PostgreSQL (`teritory_db`)
- **ORM**: Prisma 5 (`@prisma/client`)
- **Cache**: Redis / In-Memory Cache
- **Real-time**: Socket.IO 4.8
- **Background Tasks**: node-cron (for 15km trip validation & expiry)

---

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Environment Setup
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure your `DATABASE_URL` points to your Neon PostgreSQL `teritory_db`.

### 3. Database Sync & Seed
```bash
# Push schema to Neon PostgreSQL
npm run prisma:push

# Populate database with rich Kerala travel test suite
npm run prisma:seed
```

### 4. Run Server
```bash
# Production mode
npm start

# Development mode with hot-reloading
npm run dev
```

The server starts at `http://localhost:4000`.

---

## API Base Endpoints

- **Health Check**: `GET /health`
- **Auth**: `/v1/auth` (send-otp, verify-otp, refresh, logout, me)
- **Users & Social**: `/v1/users` (me, profile, trip-mode, friends, requests)
- **Flags & Sub-Territories**: `/v1/flags` (explore, sub-territories, reactions, comments)
- **Clans**: `/v1/clans` (browse, my, join, leave, communities)
- **Communities**: `/v1/communities` (feed, messages, members, trip-plans)
- **Trips & Expeditions**: `/v1/trips` (hub, plans, vote, start, validate-waypoint, complete, history)
- **Legendary Rallies**: `/v1/rallies` (nearby, join, arrive, complete)
- **Rankings**: `/v1/rankings` (leaderboard with global, country, state, district, friends scopes)
- **Services & Gear**: `/v1/services` (gear, nearby-food)
- **Notifications**: `/v1/notifications` (list, read, read-all)

---

## Real-Time WebSockets (`Socket.IO`)
Connect to `ws://localhost:4000`:
- `join_community`: `{ communityId }`
- `chat_typing`: `{ communityId, isTyping }`
- `join_trip`: `{ tripId }`
- `trip_location_update`: `{ tripId, latitude, longitude }`
- `join_rally`: `{ rallyId }`
