# Teritory API — Cloud Deployment & Maintenance Guide

This document describes how the **Teritory Standalone Backend API** (`teritory-api`) is deployed, how code updates are released, and how it safely coexists alongside the `onway-api` without any conflict or disruption.

---

## 🛡️ Critical Architecture Guarantee: Zero Impact on OnWay API

The codebase contains two completely distinct backend services:

| Attribute | OnWay API (`onway-api`) | Teritory API (`teritory-api`) |
| :--- | :--- | :--- |
| **Directory** | Project Root (`./src`) | `./teritory-api` |
| **Database** | `neondb` (Postgres on Neon) | `teritory_db` (Isolated Postgres catalog on Neon) |
| **Local Port** | `3001` | `4000` |
| **Cloud Port** | Render binds `PORT` (10000) | Render binds `PORT` (10000) |
| **Dependencies** | Root `package.json` | `teritory-api/package.json` |
| **Prisma Schema** | `./prisma/schema.prisma` | `./teritory-api/prisma/schema.prisma` |
| **PM2 Process** | `onway-api` | `teritory-api` |
| **Live URL (Example)** | `https://onway-backend-api.onrender.com` | `https://teritory-api.onrender.com` |

> [!IMPORTANT]
> Because `teritory-api` uses its own separate database (`teritory_db`), its own Prisma schema, its own `package.json`, and its own isolated process, deploying or modifying `teritory-api` **will NEVER alter, overwrite, or touch `onway-api`**.

---

## 🚀 Deployment Methods

### Method 1: Render Blueprint (Recommended for Automated Multi-Service)

The repository's [render.yaml](file:///home/akhilva/onway-api/render.yaml) is configured with both services as distinct web services.

1. **Service 1**: `onway-api` (Root directory, targeting `neondb`).
2. **Service 2**: `teritory-api` (Root directory set to `teritory-api`, targeting `teritory_db`).

When you connect the repository to Render via Blueprint (or push to the repository's tracked branch), Render creates and manages `teritory-api` as an independent web service with zero modifications to the existing `onway-api`.

---

### Method 2: Render Dashboard (Dedicated Standalone Web Service)

If you prefer to create the service manually in the Render Dashboard so you don't touch any existing Render blueprints:

1. Log into your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** > **Web Service**.
3. Select your repository (`onway-backend-api` or monorepo).
4. Fill in the service configuration:
   * **Name**: `teritory-api`
   * **Region**: `Ohio (US East)` (or matching your Neon database region)
   * **Branch**: `develop` (or `main`)
   * **Root Directory**: `teritory-api` *(CRITICAL: This tells Render to only look inside the `teritory-api` folder)*
   * **Runtime**: `Node`
   * **Build Command**:
     ```bash
     npm install && npx prisma generate
     ```
   * **Start Command**:
     ```bash
     npm start
     ```
   * **Health Check Path**: `/health`
   * **Plan**: `Free` (or Starter)

5. Under **Environment Variables**, add:
   * `NODE_ENV`: `production`
   * `PORT`: `10000`
   * `DATABASE_URL`: `postgresql://neondb_owner:npg_MNPi8KZyD1OU@ep-noisy-bar-be1d5ayd-pooler.c-9.us-east-2.aws.neon.tech/teritory_db?sslmode=require&connect_timeout=30&pool_timeout=30`
   * `JWT_SECRET`: `teritory_super_secret_jwt_access_key_2026_x99`
   * `JWT_EXPIRES_IN`: `7d`
   * `JWT_REFRESH_SECRET`: `teritory_super_secret_refresh_token_key_2026_z88`
   * `JWT_REFRESH_EXPIRES_IN`: `30d`
   * `WAYPOINT_VALIDATION_RADIUS_METERS`: `15000`
   * `RALLY_ARRIVAL_RADIUS_METERS`: `500`
   * `SUB_TERITORY_RADIUS_METERS`: `5000`

6. Click **Create Web Service**. Render will clone only the `teritory-api` directory, install packages, generate Prisma bindings, and boot the server.

---

### Method 3: Docker Container Deployment

A production-ready [Dockerfile](file:///home/akhilva/onway-api/teritory-api/Dockerfile) is provided in `teritory-api/`.

```bash
# 1. Build Docker image
docker build -t teritory-api -f teritory-api/Dockerfile ./teritory-api

# 2. Run container
docker run -d \
  -p 4000:4000 \
  --name teritory-api-prod \
  --env-file ./teritory-api/.env \
  --restart unless-stopped \
  teritory-api
```

---

### Method 4: Linux Server / AWS EC2 with PM2

We provide an isolated deployment script [deploy_teritory.sh](file:///home/akhilva/onway-api/deploy_teritory.sh) that manages only `teritory-api` in PM2 without disturbing `onway-api`:

```bash
# Run isolated deployment
./deploy_teritory.sh

# Or run deployment and re-seed Kazhakkoottam test dataset
./deploy_teritory.sh --seed
```

To manage the services in PM2:
```bash
# Check status of both services
pm2 status

# Restart ONLY teritory-api
pm2 restart teritory-api

# View live logs of teritory-api
pm2 logs teritory-api
```

---

## 🗄️ Database Management & Seeding

* **Database Connection**: Hosted on Neon Cloud (`teritory_db`).
* **Schema Path**: [teritory-api/prisma/schema.prisma](file:///home/akhilva/onway-api/teritory-api/prisma/schema.prisma)
* **Push Schema Updates**:
  ```bash
  cd teritory-api
  npx prisma db push
  ```
* **Seed Rich Kazhakkoottam / Kerala Dataset**:
  ```bash
  cd teritory-api
  node prisma/seed.js
  ```

### Default Seeded User Credentials (for Testing)
* **Mobile Number**: `+91 8848793417`
* **OTP**: `12345`
* **User Profile**:
  * Name: `Akhil V A`
  * Handle: `@akhilva`
  * Home Base: `Kazhakkoottam, Thiruvananthapuram` (Lat: 8.5686, Lng: 76.8731)
  * Clan: Chieftain of `Travancore Voyagers` (`#TRV-001`)
  * Badges: `Territory Pioneer`, `Trailblazer`, `Highland Conqueror`
  * Pre-loaded data: 21 flags, active expedition to Ponmudi, wishlist spots, clan rankings, services.

---

## 📱 Mobile App (Flutter) Configuration

The Flutter app is configured in [teritory/lib/core/config/app_config.dart](file:///home/akhilva/onway-api/teritory/lib/core/config/app_config.dart).

### 1. Local Testing with Physical Device:
```bash
# Reverse the port so device talks to your local machine
adb reverse tcp:4000 tcp:4000

# Run Flutter app
cd teritory
flutter run
```

### 2. Pointing to Deployed Cloud URL:
When your Render service is live (e.g. `https://teritory-api.onrender.com`):
```bash
cd teritory
flutter run \
  --dart-define=API_BASE_URL=https://teritory-api.onrender.com/v1 \
  --dart-define=SOCKET_URL=https://teritory-api.onrender.com
```

Or build the production APK:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://teritory-api.onrender.com/v1 \
  --dart-define=SOCKET_URL=https://teritory-api.onrender.com
```

---

## 🔍 Verification & Health Checks

Once deployed, verify the service using `curl`:

```bash
curl -X GET https://<your-teritory-service>.onrender.com/health
```

Expected Response:
```json
{
  "status": "ok",
  "service": "Teritory Standalone API",
  "version": "1.0.0",
  "timestamp": "2026-11-19T...",
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
    "notifications": "/v1/notifications"
  }
}
```
