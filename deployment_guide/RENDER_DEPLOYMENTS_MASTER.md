# Render Cloud Deployments — Master Architecture & Operations Guide

> **Last Updated & Verified:** 2026-11-21  
> **Repository:** `https://github.com/otomata-in/onway-backend-api`  
> **Status:** Both Services Live & Verified on Render

---

## 🗺️ Master Architecture Overview

This monorepo hosts two completely independent, production-grade Node.js backends deployed on Render. They share the same GitHub repository and the same AWS Ohio region on Neon, but are **100% strictly isolated** by directory, database catalog, Prisma schemas, and live processes.

```
                        ┌─────────────────────────────────────────────────────────────┐
                        │      GitHub Repository: otomata-in/onway-backend-api        │
                        │                       (branch: develop)                     │
                        └──────────────┬──────────────────────────────┬───────────────┘
                                       │                              │
                                       ▼                              ▼
             ┌───────────────────────────────────┐  ┌───────────────────────────────────┐
             │       Service 1: onway-api        │  │      Service 2: teritory-api      │
             │           (Render Web)            │  │           (Render Web)            │
             ├───────────────────────────────────┤  ├───────────────────────────────────┤
             │ Root Dir: . (repo root)           │  │ Root Dir: teritory-api            │
             │ Port: 10000                       │  │ Port: 10000                       │
             │ URL: onway-backend-api.onrender   │  │ URL: teritory-api.onrender.com    │
             └─────────────────┬─────────────────┘  └─────────────────┬─────────────────┘
                               │                                      │
                               ▼                                      ▼
             ┌───────────────────────────────────┐  ┌───────────────────────────────────┐
             │      Database: neondb (Neon)      │  │    Database: teritory_db (Neon)   │
             │       OnWay Marketplace Data      │  │      Teritory Geospatial Data     │
             └───────────────────────────────────┘  └───────────────────────────────────┘
```

---

## 📊 Live Services Matrix

| Service Name | Live Cloud URL | Root Directory | Database (Neon) | Health Endpoint | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OnWay API** | `https://onway-backend-api.onrender.com` | `.` (Root) | `neondb` | `/health` | 🟢 **Live (HTTP 200)** |
| **Teritory API** | `https://teritory-api.onrender.com` | `teritory-api` | `teritory_db` | `/health` | 🟢 **Live (HTTP 200)** |

---

## 🛡️ Isolation Guarantees: Why Deploying One Never Affects the Other

1. **Root Directory Isolation (`rootDir`):**
   - Render's `teritory-api` service has its Root Directory explicitly locked to `teritory-api/`.
   - Render will **only** watch and build files inside `teritory-api/` for that service.
   - The `onway-api` service builds from the root directory.

2. **Database Catalog Isolation:**
   - `onway-api` connects to database catalog `neondb` (tables: `Buyer`, `Vendor`, `Product`, `Order`, etc.).
   - `teritory-api` connects to database catalog `teritory_db` (tables: `User`, `Flag`, `Trip`, `Rally`, `Clan`, `Community`, `ServiceProvider`, etc.).
   - Neither service has credentials or access to the other catalog.

3. **Prisma Client Isolation:**
   - Root has `./prisma/schema.prisma`.
   - Teritory has `./teritory-api/prisma/schema.prisma`.
   - Prisma client bindings are generated inside separate `node_modules` folders.

4. **Zero Shared In-Memory State:**
   - Each runs in its own isolated Linux container on Render with its own dedicated memory and Node.js event loop.

---

## 🔧 Service 1: OnWay Hyperlocal Marketplace Backend

### Render Service Details
* **Name:** `onway-backend-api`
* **Service ID:** `srv-dbnm5rrl550s73fjluq0`
* **Region:** Ohio (`us-east`)
* **Live Base URL:** `https://onway-backend-api.onrender.com`
* **Health Check:** `https://onway-backend-api.onrender.com/health`

### Build & Run
* **Root Directory:** `.` (Repo Root)
* **Build Command:** `npm install --legacy-peer-deps && npm run build`
* **Start Command:** `npm start`

### Production Environment Variables
```env
NODE_ENV=production
PORT=10000
DATABASE_URL=postgresql://neondb_owner:npg_u3d5KxODFobB@ep-noisy-bar-be1d5ayd-pooler.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require
DATABASE_URL_UNPOOLED=postgresql://neondb_owner:npg_u3d5KxODFobB@ep-noisy-bar-be1d5ayd.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require
JWT_SECRET=onway_market_secret_jwt_key_2026
```

### Verification Command
```bash
curl -s https://onway-backend-api.onrender.com/health | jq .
```

---

## 🚩 Service 2: Teritory Geospatial Travel & Expedition Backend

### Render Service Details
* **Name:** `teritory-api`
* **Region:** Ohio (`us-east-2`)
* **Live Base URL:** `https://teritory-api.onrender.com`
* **Health Check:** `https://teritory-api.onrender.com/health`
* **WebSockets:** `wss://teritory-api.onrender.com`
* **Static Uploads:** `https://teritory-api.onrender.com/uploads/`

### Build & Run
* **Root Directory:** `teritory-api`
* **Build Command:** `npm install && npx prisma generate`
* **Start Command:** `npm start`

### Production Environment Variables
```env
NODE_ENV=production
PORT=10000
DATABASE_URL=postgresql://neondb_owner:npg_MNPi8KZyD1OU@ep-noisy-bar-be1d5ayd-pooler.c-9.us-east-2.aws.neon.tech/teritory_db?sslmode=require&connect_timeout=30&pool_timeout=30
JWT_SECRET=teritory_super_secret_jwt_access_key_2026_x99
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=teritory_super_secret_refresh_token_key_2026_z88
JWT_REFRESH_EXPIRES_IN=30d
ALLOW_DEV_OTP=true
WAYPOINT_VALIDATION_RADIUS_METERS=15000
RALLY_ARRIVAL_RADIUS_METERS=500
SUB_TERITORY_RADIUS_METERS=5000
```

### Verification Commands

#### 1. Health & Endpoints
```bash
curl -s https://teritory-api.onrender.com/health | jq .
```
Expected output:
```json
{
  "status": "ok",
  "service": "Teritory Standalone API",
  "version": "1.0.0",
  "endpoints": {
    "auth": "/v1/auth",
    "users": "/v1/users",
    "flags": "/v1/flags",
    "clans": "/v1/clans",
    "communities": "/v1/communities",
    "trips": "/v1/trips",
    "rallies": "/v1/rallies",
    "rankings": "/v1/rankings",
    "services": "/v1/services",
    "notifications": "/v1/notifications",
    "upload": "/v1/upload"
  }
}
```

#### 2. Live Auth & Dev OTP Test (Akhil V A)
```bash
curl -s -X POST https://teritory-api.onrender.com/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"+918848793417","otp":"12345"}' | jq .
```
Expected response:
```json
{
  "success": true,
  "message": "Authentication successful",
  "data": {
    "user": {
      "displayName": "Akhil V A",
      "handle": "akhilva"
    }
  }
}
```

#### 3. Real-Road Directions Proxy (OSRM)
```bash
curl -s "https://teritory-api.onrender.com/v1/trips/directions?waypoints=76.8731,8.5686;76.9780,8.4020" | jq .data
```

#### 4. Nearby Food in Kazhakkoottam
```bash
curl -s "https://teritory-api.onrender.com/v1/services/nearby-food?lat=8.5686&lng=76.8731" | jq .data
```

---

## 📱 Connecting the Flutter Mobile Apps

### For Teritory Mobile App (`teritory/lib/core/config/app_config.dart`)

```dart
class AppConfig {
  /// Toggle between local dev and live Render cloud backend:
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://teritory-api.onrender.com/v1', // Live Render Cloud
    // defaultValue: 'http://localhost:4000/v1',          // Local Dev (with adb reverse)
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://teritory-api.onrender.com',    // Live Render Cloud
    // defaultValue: 'http://localhost:4000',             // Local Dev
  );
}
```

---

## 🔄 Routine Deployment Operations

### How to Deploy Code Updates

When you make changes to either API:

```bash
# 1. Commit your changes
git add -A
git commit -m "feat: description of changes"

# 2. Push to develop
git push origin develop
```

- If changes are in `teritory-api/`, Render's `teritory-api` service automatically rebuilds and deploys.
- If changes are in root `src/`, Render's `onway-backend-api` service automatically rebuilds and deploys.
- If Render auto-deploy is paused, click **Manual Deploy** ➔ **Deploy latest commit** inside the respective service's dashboard.

