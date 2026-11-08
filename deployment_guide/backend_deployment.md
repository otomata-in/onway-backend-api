# Backend Deployment & Maintenance Guide

This document describes how the Node.js Express backend is deployed, how code updates are released, and how to maintain the live service on Render.

---

## 1. Hosting Architecture on Render

* **Service Name**: `onway-backend-api`
* **Service ID**: `srv-dbnm5rrl550s73fjluq0`
* **Environment**: Node.js
* **Plan**: Free Tier (750 free instance hours/month)
* **Region**: Ohio (`us-east`)
* **Tracking Branch**: `main` on repository `https://github.com/otomata-in/onway-backend-api`
* **Auto Deploy**: Enabled (`yes` on git commit to `main`)

### Build & Start Commands
* **Build Command**: 
  ```bash
  npm install --legacy-peer-deps && npm run build
  ```
  *(Runs `prisma generate` via `npm run build` so Prisma client bindings are generated inside the container).*
* **Start Command**: 
  ```bash
  npm start
  ```
  *(Runs `node src/server.js`, binding to `0.0.0.0` on port `10000`).*

---

## 2. Standard Update Workflow (Push to Deploy)

Whenever you make changes to routes, controllers, or business logic:

### Step 1: Develop & Test Locally
```bash
# Run backend locally to verify changes
npm run dev
```

### Step 2: Commit and Push
```bash
git add .
git commit -m "feat: your new feature or fix description"

# Push to your GitHub repository
git push origin main
```

> **Automated Deploy**: Because Auto-Deploy is enabled on Render, pushing to `main` will automatically trigger a new build and deploy on Render within seconds.

---

## 3. Manual Redeployment & Cache Clear

If a deployment fails, or if you need to clear the npm build cache and force a complete re-install:

### Via Render Web UI:
1. Open the [Render Dashboard](https://dashboard.render.com/web/srv-dbnm5rrl550s73fjluq0).
2. Click the **Manual Deploy** button (top right).
3. Select **Clear build cache & deploy**.

### Via Terminal (Using Render API):
```bash
curl -X POST \
  -H "Authorization: Bearer <YOUR_RENDER_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"clearCache": "clear"}' \
  https://api.render.com/v1/services/srv-dbnm5rrl550s73fjluq0/deploys
```

---

## 4. Environment Variables on Render

The live service requires the following environment variables configured in the Render Dashboard under **Environment**:

| Variable | Description | Current Value Pattern |
| :--- | :--- | :--- |
| `NODE_ENV` | Runtime environment | `production` |
| `PORT` | Container listening port | `10000` |
| `DATABASE_URL` | Neon pooled Postgres connection | `postgresql://neondb_owner:***@ep-noisy-bar-be1d5ayd-pooler.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require` |
| `DATABASE_URL_UNPOOLED` | Neon direct Postgres connection | `postgresql://neondb_owner:***@ep-noisy-bar-be1d5ayd.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require` |
| `JWT_SECRET` | Secret token signing key | `onway_market_secret_jwt_key_2026` |
| `REDIS_URL` *(Optional)* | Upstash Redis connection string | `rediss://...` (falls back gracefully if omitted) |

> **Note on updating variables**: Changing any environment variable on Render triggers an automatic rolling redeployment.

---

## 5. Health Checks & Verification

Render uses the root endpoint to confirm container health before switching traffic.

* **Health Endpoint**: `https://onway-backend-api.onrender.com/health`
* **Response**:
  ```json
  {
    "status": "ok",
    "service": "OnWay API",
    "uptime": 124.5,
    "timestamp": "2026-11-07T17:48:33.272Z"
  }
  ```

### Quick Verification Command:
```bash
curl -I https://onway-backend-api.onrender.com/
# Expected: HTTP/2 200
```

---

## 6. Cold Starts & Keep-Alive Tip

On the Render Free tier, the service automatically spins down to save compute if there are no requests for **15 minutes**. When a request arrives, it takes ~40–50 seconds to boot up (cold start).

### How to keep the server awake for remote testers:
You can use a free uptime monitoring service like **[cron-job.org](https://cron-job.org/)** or **[UptimeRobot](https://uptimerobot.com/)**:
1. Create a free HTTP monitor pointing to `https://onway-backend-api.onrender.com/health`.
2. Set the interval to **every 10 minutes**.
3. This prevents the server from spinning down during business/testing hours!

